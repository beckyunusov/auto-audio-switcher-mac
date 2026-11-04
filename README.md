# auto-audio-switcher-mac

Make macOS switch its default audio devices automatically when a wireless
gaming headset is powered on or off, while keeping the low-latency 2.4 GHz
USB receiver instead of Bluetooth.

## The problem

A USB wireless receiver is always plugged in, so macOS always lists it as an
audio device and happily routes sound to it even when the headset itself is
switched off. Bluetooth would solve the switching, but on a Mac any app that
opens the mic drops a Bluetooth headset to the hands-free profile: playback
becomes narrow mono and the mic sounds like a phone call. The receiver keeps
full stereo plus mic with lower latency, so it is worth keeping.

## How it works

The headset vendor's desktop app knows when the headset connects to the
receiver and writes that state to its own log file:

```
cue.dev.connection_controller: "HS80 MAX WIRELESS" Disconnected -> Wireless
```

`bin/audio-switch-watch` polls the newest log file every two seconds for that
line and, when the state changes, calls `bin/audio-switch on|off`, which sets
the default output, system-sound and input devices with
[`SwitchAudioSource`](https://github.com/deweller/switchaudio-osx).
A launchd agent keeps the watcher running at login.

Written for a Corsair HS80 MAX with iCUE 5 on macOS, but the device names,
log directory and log line are all configurable, so any headset whose vendor
app logs a similar connect/disconnect line will work.

## Install

```sh
brew install switchaudio-osx
git clone https://github.com/beckyunusov/auto-audio-switcher-mac.git
cd auto-audio-switcher-mac
./install.sh
```

`install.sh` renders the launchd plist from the template using the repo's
location and your home directory, then starts the agent. No paths are
hard-coded; move the repo and re-run `./install.sh`.

Manual use without the agent:

```sh
bin/audio-switch devices   # list device names on this Mac
bin/audio-switch toggle    # or on / off / status
```

Bind `audio-switch toggle` to a hotkey if you want a manual override.

## Configure

Create `~/.config/auto-audio-switcher/config.sh` to override any default:

```sh
HEADSET_OUT="CORSAIR HS80 MAX WIRELESS Gaming Receiver"   # output device when headset is on
HEADSET_IN="CORSAIR HS80 MAX WIRELESS Gaming Receiver"    # input device when headset is on
FALLBACK_OUT="MacBook Pro Speakers"                       # output device when headset is off
FALLBACK_IN="MacBook Pro Microphone"                      # input device when headset is off
HEADSET_LOG_NAME="HS80 MAX WIRELESS"                      # device name as written in the log
VENDOR_LOG_DIR="$HOME/Library/Application Support/Corsair/Logs/CUE5"
POLL_INTERVAL=2
```

Device names come from `bin/audio-switch devices`. To use the vendor app's
processed output (EQ, spatial audio) instead of the raw receiver, set
`HEADSET_OUT` to the virtual device it creates, e.g. the one prefixed `[iCUE]`.

## Check and troubleshoot

```sh
launchctl print gui/$(id -u)/com.auto-audio-switcher.watch | head -5
tail -f ~/Library/Logs/auto-audio-switcher/watch.log
```

- Nothing switches: make sure the vendor app is running; the watcher reads
  its log.
- Wrong direction: check the exact transition words in the log. `Wireless`,
  `Wired` and `Connected` mean on, `Disconnected` means off.
- Switching takes a moment: it polls, so expect up to `POLL_INTERVAL` seconds.

## Uninstall

```sh
./uninstall.sh
```

## License

MIT
