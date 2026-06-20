#!/usr/bin/env python3
import sys
import os
import re
import time
import threading
import argparse
import queue
from difflib import get_close_matches

# Audio & GUI imports
from AVFoundation import AVAudioEngine
from Foundation import NSRunLoop, NSDate
import AppKit
import Quartz
import numpy as np
from faster_whisper import WhisperModel

# ── Arguments ─────────────────────────────────────────────────────────────

parser = argparse.ArgumentParser(description="Whisper Speech-to-Text Daemon")
parser.add_argument(
    "--model",
    type=str,
    default="base",
    help="Whisper model size (tiny, base, small, medium, large-v3)",
)
parser.add_argument(
    "--device", type=str, default="cpu", help="Device to run model on (cpu, cuda)"
)
parser.add_argument(
    "--threshold",
    type=float,
    default=-42.0,
    help="Microphone VAD threshold in dB (default: -42.0)",
)
parser.add_argument(
    "--silence",
    type=float,
    default=1.2,
    help="Silence timeout in seconds (default: 1.2)",
)
parser.add_argument(
    "--no-paste", action="store_true", help="Disable pasting text at the active cursor"
)
args = parser.parse_args()

paste_enabled = not args.no_paste
silence_seconds = args.silence
threshold_db = args.threshold
model_size = args.model
device = args.device

# ── Load Whisper Model ────────────────────────────────────────────────────

# print(
#     f"Loading Whisper model '{model_size}' on '{device}' (compute_type='int8') ...",
#     end="",
#     flush=True,
# )
try:
    # Use int8 compute type for optimized CPU performance
    model = WhisperModel(model_size, device=device, compute_type="int8")
    # print(" Done!")
except Exception as e:
    print(f"\nERROR: Failed to load Whisper model: {e}", file=sys.stderr)
    sys.exit(1)

# ── Vocabulary ────────────────────────────────────────────────────────────

priority_words = [
    "save",
    "save file",
    "save and quit",
    "quit",
    "force quit",
    "undo",
    "redo",
    "delete line",
    "delete word",
    "delete character",
    "normal mode",
    "visual mode",
    "insert mode",
    "go to definition",
    "go to reference",
    "next word",
    "previous word",
]

vocabulary = []

try:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    vocab_path = os.path.join(script_dir, "vocabulary.txt")
    with open(vocab_path, "r", encoding="utf-8") as f:
        for line in f:
            word = line.strip()
            if word and not word.startswith("#"):
                vocabulary.append(word.lower())
except Exception:
    pass

# Combine lists and remove duplicates
vocabulary = list(dict.fromkeys(priority_words + vocabulary))
# print(f"Vocabulary loaded: {vocabulary}", flush=True)

# ── Correction Layer ──────────────────────────────────────────────────────

aliases = {
    "normal mode": "normal",
    "visual mode": "visual",
    "insert mode": "insert",
    "go to referance": "go to reference",
}


def has_hallucination_loop(text):
    words = text.lower().split()
    if len(words) >= 6:
        from collections import Counter

        # Check bigrams
        bigrams = [f"{words[i]} {words[i + 1]}" for i in range(len(words) - 1)]
        bigram_counts = Counter(bigrams)
        for bigram, count in bigram_counts.items():
            if count >= 3 and (count / len(bigrams)) > 0.35:
                return True

        # Check single words
        word_counts = Counter(words)
        for word, count in word_counts.items():
            if count >= 3 and (count / len(words)) > 0.4:
                return True
    return False


def normalize_text(text):
    text = text.strip()
    if has_hallucination_loop(text):
        return ""  # Discard loops completely

    # Clean text: lowercase, replace commas/dashes with spaces, and strip formatting
    text_clean = re.sub(r"[^\w\s]", " ", text)
    text_clean = re.sub(r"\s+", " ", text_clean)
    text_clean = text_clean.lower().strip()

    if text_clean in aliases:
        return aliases[text_clean]

    # Find closest match in vocabulary with a highly forgiving cutoff (0.65)
    # This allows matching accented speech and slightly misheard pronunciations
    match = get_close_matches(text_clean, vocabulary, n=1, cutoff=0.65)
    if match:
        return match[0]
    return text_clean


# ── Paste ─────────────────────────────────────────────────────────────────


def paste_text(text):
    if not text:
        return

    text = text.lower()

    active_app = AppKit.NSWorkspace.sharedWorkspace().frontmostApplication()
    app_name = active_app.localizedName() if active_app else ""

    if app_name in ["Terminal", "iTerm", "iTerm2", "Alacritty", "Kitty"]:
        return

    pb = AppKit.NSPasteboard.generalPasteboard()
    old_text = pb.stringForType_(AppKit.NSPasteboardTypeString)

    pb.declareTypes_owner_([AppKit.NSPasteboardTypeString], None)
    pb.setString_forType_(text + " ", AppKit.NSPasteboardTypeString)

    event_down = Quartz.CGEventCreateKeyboardEvent(None, 9, True)
    Quartz.CGEventSetFlags(event_down, Quartz.kCGEventFlagMaskCommand)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, event_down)

    event_up = Quartz.CGEventCreateKeyboardEvent(None, 9, False)
    Quartz.CGEventSetFlags(event_up, Quartz.kCGEventFlagMaskCommand)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, event_up)

    time.sleep(0.15)
    if old_text:
        pb.setString_forType_(old_text, AppKit.NSPasteboardTypeString)


# ── Audio Processing & VAD ────────────────────────────────────────────────

transcription_queue = queue.Queue()
active_buffers = []
is_speaking = [False]
silence_samples_count = [0]


def resample_audio(samples, src_rate, target_rate):
    if src_rate == target_rate:
        return samples
    duration = len(samples) / src_rate
    num_target_samples = int(duration * target_rate)
    return np.interp(
        np.linspace(0, len(samples), num_target_samples, endpoint=False),
        np.arange(len(samples)),
        samples,
    )


def audio_tap(buffer, when):
    length = buffer.frameLength()
    if length == 0:
        return

    # Extract Float32 samples from channel 0
    ptr = buffer.floatChannelData()[0]
    samples = np.array(ptr[:length], dtype=np.float32)

    # Downsample to 16000 Hz if needed
    src_rate = buffer.format().sampleRate()
    if src_rate != 16000.0:
        samples_16k = resample_audio(samples, src_rate, 16000.0)
    else:
        samples_16k = samples

    # Calculate RMS energy of this block
    rms = np.sqrt(np.mean(samples_16k**2)) if len(samples_16k) > 0 else 0.0
    db = 20 * np.log10(rms) if rms > 1e-5 else -100.0

    # VAD State Machine
    if db > threshold_db:
        if not is_speaking[0]:
            is_speaking[0] = True
            # sys.stdout.write("\r[Listening...]")
            sys.stdout.flush()
        silence_samples_count[0] = 0
        active_buffers.append(samples_16k)
    else:
        if is_speaking[0]:
            active_buffers.append(samples_16k)
            silence_samples_count[0] += len(samples_16k)

            # Determine silence elapsed (16000 samples = 1s)
            silence_elapsed = silence_samples_count[0] / 16000.0
            if silence_elapsed >= silence_seconds:
                is_speaking[0] = False
                silence_samples_count[0] = 0

                # Combine collected buffers
                audio_chunk = np.concatenate(active_buffers)
                active_buffers.clear()

                # Filter out short noises (clicks, keyboard taps, breaths) under 0.4 seconds
                if len(audio_chunk) >= 16000 * 0.4:
                    # sys.stdout.write("\r[Transcribing...]")
                    sys.stdout.flush()
                    transcription_queue.put(audio_chunk)
                else:
                    # Clear VAD indicator silently
                    sys.stdout.write("\r\033[K")
                    sys.stdout.flush()


# ── Worker Thread ─────────────────────────────────────────────────────────


def transcribe(audio_chunk):
    # Inject standard commands in initial_prompt to bias spelling/grammar context
    prompt_words = priority_words + [
        "live grep current directory",
        "go to type definition",
        "search workspace diagnostics",
        "file tree",
    ]
    prompt_str = " ".join(prompt_words)

    # Comma-separated list for hotwords
    hotwords_str = ",".join(vocabulary) if vocabulary else None

    segments, _ = model.transcribe(
        audio_chunk,
        language="en",
        initial_prompt=prompt_str,
        hotwords=hotwords_str,
        beam_size=5,
        vad_filter=True,
        temperature=0.0,
    )
    return "".join(s.text for s in segments).strip()


def recognition_worker():
    while True:
        try:
            audio_chunk = transcription_queue.get(timeout=1.0)
        except queue.Empty:
            continue

        result = transcribe(audio_chunk)

        # Clear the status indicator
        sys.stdout.write("\r\033[K")
        sys.stdout.flush()

        if result:
            phrase = normalize_text(result)
            print(phrase.lower(), flush=True)
            if paste_enabled:
                paste_text(phrase)

        transcription_queue.task_done()


threading.Thread(target=recognition_worker, daemon=True).start()

# ── Audio engine ──────────────────────────────────────────────────────────

audio_engine = AVAudioEngine.alloc().init()
input_node = audio_engine.inputNode()
fmt = input_node.outputFormatForBus_(0)

# Install audio tap on input bus
input_node.installTapOnBus_bufferSize_format_block_(0, 4096, fmt, audio_tap)

audio_engine.prepare()
audio_engine.startAndReturnError_(None)

# print("=" * 45, flush=True)
# print("Whisper Speech-to-Text Daemon Started", flush=True)
# print(f"Model Size:   {model_size}", flush=True)
# print(f"VAD Limit:    {threshold_db} dB", flush=True)
# print(f"Silence:      {silence_seconds}s", flush=True)
# print(f"Auto-Type:    {'Enabled' if paste_enabled else 'Disabled'}", flush=True)
# print("=" * 45, flush=True)
print("READY", flush=True)

# ── Run loop ──────────────────────────────────────────────────────────────

try:
    loop = NSRunLoop.currentRunLoop()
    while True:
        loop.runUntilDate_(NSDate.dateWithTimeIntervalSinceNow_(0.1))
except KeyboardInterrupt:
    audio_engine.stop()
    try:
        input_node.removeTapOnBus_(0)
    except Exception:
        pass
    sys.exit(0)
