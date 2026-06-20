#!/bin/bash
set -e

echo "=== Installing Dictate Daemon Dependencies ==="

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 could not be found. Please install Python 3." >&2
    exit 1
fi

# Detect OS
OS="$(uname)"
if [ "$OS" != "Darwin" ]; then
    echo "WARNING: Dictate's AVFoundation microphone capturing requires macOS." >&2
    echo "Python dependencies will still be installed." >&2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Create virtual environment
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment in $SCRIPT_DIR/.venv..."
    python3 -m venv .venv
else
    echo "Virtual environment already exists."
fi

# Upgrade pip and install dependencies
echo "Installing dependencies..."
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt

echo "=== Installation Complete ==="
