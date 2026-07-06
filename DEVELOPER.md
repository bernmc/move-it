# Move It! — developer notes

A get-up-and-move desk reminder for Windows, built to run on a **locked-down PC with no
installs and no admin rights**. Everything uses only what ships inside stock Windows —
PowerShell + Windows Forms/.NET, or `mshta.exe`. User-facing instructions are in
[README.md](README.md).

There is **no build step**. The app *is* these text files — copy the folder to a Windows
machine and run it.

## The two versions

Both are self-contained and share `messages.txt`. Ship whichever runs on the target PC —
they don't depend on each other.

| File | What it is |
|---|---|
| `MoveIt.ps1` | **Primary version.** PowerShell + Windows Forms tray app. Invisible until it nudges you. |
| `Start-MoveIt.bat` | Launcher for the PowerShell version — runs it hidden, no console window, execution policy bypassed *per-process* (no system change). |
| `MoveIt.hta` | **Backup version.** Runs via `mshta.exe` for when `.ps1`/`.bat` are blocked. A window rather than a tray icon. |
| `messages.txt` | The random reminder lines, one per line. Shared by both versions. Edit freely. |

## How it runs

- **`Start-MoveIt.bat`** calls:
  `powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File MoveIt.ps1`.
  The `Bypass` is scoped to that single process, so it needs no admin rights and changes
  no machine policy.
- **`MoveIt.ps1`** loads `System.Windows.Forms` + `System.Drawing`, draws a `NotifyIcon`
  in the tray, and runs a timer that fires the funky full-window alert at the configured
  interval. "I MOVED!" logs the daily count and restarts the cycle; "Gimme X" snoozes.
- **`MoveIt.hta`** does the same job through the Trident/mshta engine as a small window,
  since HTAs can't own a tray icon.

## Settings & data (generated at runtime, next to the app)

- PowerShell version → `moveit-settings.json`
- HTA version → `moveit-settings.txt`

Both hold interval, snooze, sound on/off, start-with-Windows, and the daily move count +
date. They're **git-ignored** — they're per-user runtime state, not source.

Defaults live at the top of `MoveIt.ps1` in `Get-DefaultConfig`:

- `IntervalMinutes` — how often to nag (default **45**)
- `SnoozeMinutes` — the "Gimme 5" delay (default **5**)
- `Sound` — play a chime with the alert
- `StartWithWindows` — add/remove a shortcut in the user's Startup folder (no admin)

## Start-with-Windows

Handled purely in user space: a `Move It` shortcut is dropped into
`shell:startup` (`%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`). No registry
writes needing admin, no scheduled tasks.

## Known Windows quirks

- The chime uses a `.wav` from `C:\Windows\Media\`; if absent it fails silently.
- Emoji may render monochrome under the older mshta/IE engine (cosmetic).
- Windows' anti-focus-stealing behaviour can downgrade "force to foreground" into a
  taskbar flash — expected, not a bug.
- If IT policy disables **both** PowerShell and mshta, there is no install-free
  workaround; that's outside the app's control.

## Testing

Developed on macOS, tested on Windows via Parallels. There's nothing to compile — edit a
file, copy the folder over, run.
