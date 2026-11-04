#!/bin/zsh
# Installs the launchd agent that runs audio-switch-watch at login.
# Paths are derived from where this repo lives and from $HOME; nothing is hard-coded.
set -e
REPO="${0:A:h}"
LABEL="com.auto-audio-switcher.watch"
AGENT_DIR="$HOME/Library/LaunchAgents"
PLIST="$AGENT_DIR/$LABEL.plist"
LOG_DIR="${XDG_STATE_HOME:-$HOME/Library/Logs}/auto-audio-switcher"
LOG_FILE="$LOG_DIR/watch.log"

if ! command -v SwitchAudioSource >/dev/null 2>&1; then
  echo "SwitchAudioSource is required. Install it with:  brew install switchaudio-osx" >&2
  exit 1
fi

mkdir -p "$AGENT_DIR" "$LOG_DIR"
sed -e "s|__WATCH_SCRIPT__|$REPO/bin/audio-switch-watch|" \
    -e "s|__LOG_FILE__|$LOG_FILE|" \
    "$REPO/launchd/$LABEL.plist.template" > "$PLIST"
plutil -lint "$PLIST" >/dev/null

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Installed and started $LABEL"
echo "  scripts: $REPO/bin"
echo "  plist:   $PLIST"
echo "  log:     $LOG_FILE"
