# Move It! — developer notes

One product, two native builds. User-facing instructions are in [README.md](README.md).

| Folder | Platform | What it is |
|---|---|---|
| [`windows/`](windows/) | Windows | Install-free PowerShell + HTA scripts |
| [`macos/`](macos/) | macOS | Single-file Swift menu-bar app |

The two are independent — they share the *concept* and the funky `messages.txt` idea, but
no code.

---

## Windows (`windows/`)

Built to run on a **locked-down PC with no installs and no admin rights** — uses only
what ships inside stock Windows. **No build step**: the app *is* these text files.

| File | What it is |
|---|---|
| `MoveIt.ps1` | **Primary.** PowerShell + Windows Forms tray app. Invisible until it nudges you. |
| `Start-MoveIt.bat` | Launcher — runs the `.ps1` hidden, execution policy bypassed *per-process* (no machine change, no admin). |
| `MoveIt.hta` | **Backup** for when `.ps1`/`.bat` are blocked — runs via `mshta.exe` as a window. |
| `messages.txt` | Random reminder lines, one per line. Shared by both Windows versions. |
| `README.txt` | Plain-text instructions that ship inside the folder. |

- `Start-MoveIt.bat` runs:
  `powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File MoveIt.ps1`.
- Defaults live in `Get-DefaultConfig` at the top of `MoveIt.ps1` (interval 45, snooze 5,
  sound on, start-with-Windows off).
- Runtime settings are written next to the app: `moveit-settings.json` (PowerShell) /
  `moveit-settings.txt` (HTA). Both are **git-ignored** — per-user state, not source.
- Start-with-Windows drops a shortcut into `shell:startup` — no registry/admin.
- Quirks: chime needs a `.wav` in `C:\Windows\Media\` (else silent); emoji may render
  monochrome under mshta; anti-focus-stealing may downgrade force-to-foreground to a
  taskbar flash. If IT disables *both* PowerShell and mshta there's no install-free
  workaround.
- Developed on macOS, tested on Windows via Parallels. Nothing to compile — copy the
  folder over and run.

---

## macOS (`macos/`)

A single-file native AppKit **menu-bar** app (no dependencies, no Xcode project).

| File | Purpose |
|---|---|
| `main.swift` | entire app |
| `Info.plist` | bundle metadata (`LSUIElement` hides the Dock icon) |
| `build.sh` | compile + ad-hoc sign (+ install) |

**Build:**

```sh
./build.sh            # compile to build/Move It.app (universal arm64 + x86_64)
./build.sh --install  # compile, copy to ~/Applications, relaunch
```

- A `NSStatusItem` (teal dot) owns a menu: *Move now, Snooze, Pause/Resume, Settings…,
  Edit Messages…, About, Quit*. A one-shot `Timer` fires the nudge; "I MOVED!" logs the
  daily count and reschedules, "Gimme X" reschedules at the snooze interval.
- The nudge is a borderless floating `NudgeWindow` with a random vibrant background,
  centred, brought forward with `NSApp.activate`. Chime via `NSSound(named: "Ping")`.
- Settings persist in `UserDefaults`. Messages: read from
  `~/Documents/Move It/messages.txt` if present (one per line, `#` comments ignored),
  else the built-in list embedded in `main.swift`. **Edit Messages…** seeds that file and
  opens it.
- **Start at Login** uses `SMAppService.mainApp` (macOS 13+); on failure it points the
  user to System Settings ▸ General ▸ Login Items.

**Build note:** `build.sh` pins `-target <arch>-apple-macos13.0` and lipos arm64 + x86_64
into a universal binary — a beta Swift toolchain otherwise targets a newer macOS than the
installed one and Launch Services refuses to open the app (error -10825). Min system
macOS 13 (`SMAppService` requirement).

To keep the embedded message list and Windows `messages.txt` in sync, edit both.
