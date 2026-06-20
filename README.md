# dictate.nvim

A macOS-native, voice-controlled command and dictation plugin for Neovim / LazyVim powered by local offline Whisper (`faster-whisper`). Speak commands like `"go to definition"`, `"delete line"`, or multiplier actions like `"three delete line"`, and have Neovim execute them instantly.

## Features
- **Local Offline Voice Processing**: High-speed, high-accuracy offline recognition using Local Whisper (`faster-whisper`).
- **Pre-configured Commands**: 100+ standard Neovim and LazyVim command mappings (saving, navigation, editing, tab/split management, LSP, Harpoon, Flash, Trouble, etc.).
- **Automatic Clipboard Injection**: Bypasses typing delays by pasting text directly into Neovim.
- **Smart Correction Layer**: Automatically matches slightly mispronounced phrases or accents to your predefined vocabulary (using a fuzzy-matching correction layer).
- **LazyVim Integration**: Packages easily into lazy.nvim with an automated virtual environment installer for Python dependencies.

---

## Installation & Configuration

### Prerequisites
1. **macOS**: Native AVFoundation microphone capturing components require macOS.
2. **Python 3**: Python 3.12+ must be installed.
3. **Microphone Permissions**: Ensure Neovim (or your terminal application like iTerm2 or Alacritty) has Microphone access in macOS settings (*System Settings > Privacy & Security > Microphone*).

### Install via lazy.nvim

Add the following plugin specification to your LazyVim plugins config (e.g., `lua/plugins/dictate.lua`):

```lua
return {
  "your-github-username/dictate.nvim",
  build = "./install.sh",  -- Automatically creates virtual env and installs python deps
  cmd = { "VoiceStart", "VoiceStop", "VoiceToggle" },
  keys = {
    { "<leader>vm", "<cmd>VoiceToggle<cr>", desc = "Toggle Voice Commands" }
  },
  opts = {
    voice = "Samantha",  -- Samantha (English US), Rishi (English IN), etc.
    rate = 180,         -- Speech synthesis playback rate
    notify = true,       -- Enable notifications on phrase execution
    
    -- Note: stt_script and python_path resolve automatically to the plugin directory

    -- Pass extra CLI arguments to the Whisper daemon
    stt_args = {
      "--model", "base",       -- Whisper model choice (tiny, base, small)
      "--device", "cpu",       -- "cpu" or "cuda"
      "--threshold", "-42.0",   -- Mic energy threshold (VAD dB limit)
    }
  }
}
```

---

## How it Works Under the Hood

Dictate runs a background Python daemon process that taps into your microphone. 
- In **Normal / Visual / Command-line mode**, Dictate listens for command phrases (e.g., `"go to definition"`). If matched, it feeds the corresponding Vim keys (e.g., `gd`) into Neovim.
- In **Insert mode**, if you say standard text (like `"hello world"`), it will dictate (type) the text directly at your cursor. If you say an insert mode shortcut (like `"normal mode"`), it executes the action (like pressing `<Esc>`).

### Default Insert Mode Commands
While in **Insert Mode**, you can speak these special control phrases:
- `"normal mode"` / `"normal"` &rarr; Switches to Normal Mode (`<Esc>`).
- `"new line"` &rarr; Inserts a new line (`<CR>`).
- `"delete word"` &rarr; Deletes the word behind the cursor (`<C-w>`).
- `"delete line"` &rarr; Deletes current insert line (`<C-u>`).
- `"tab"` &rarr; Inserts a tab spacing (`<Tab>`).
- `"stop listening"` &rarr; Disables voice capturing.

---

## Commands & Mappings

You can toggle Dictate directly via commands or keybindings:

| Action | Command | Keymap |
| --- | --- | --- |
| Start voice capture | `:VoiceStart` | |
| Stop voice capture | `:VoiceStop` | |
| Toggle voice capture | `:VoiceToggle` | `<leader>vm` |

All standard command phrases are listed inside [bin/vocabulary.txt](file:///absolute/path/to/bin/vocabulary.txt) and defined inside [lua/dictate/commands.lua](file:///absolute/path/to/lua/dictate/commands.lua). You can inspect and modify these files to expand the command library.

