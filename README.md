# Move It!

**A tiny, free reminder that nudges you to get up and move — for Windows *and* Mac.**

Sit at a desk all day? Move It! waits quietly in the background and every so often pops a
funky reminder to stand up and stretch. You click **I MOVED!**, it counts it, and the
cycle starts again. No accounts, no subscriptions, no internet — your data never leaves
your computer.

<p align="center">
  <img src="docs/screenshot.png" alt="Move It! nudge window: a big 'MOVE IT!' heading, a funky reminder message, and 'I MOVED!' and 'Gimme 5 min' buttons" width="620">
</p>

There are two versions. **Pick yours below.**

- **[Windows](#windows)** — installs *nothing at all*, so it even runs on a
  locked-down work PC with no admin rights.
- **[Mac](#mac)** — a little menu-bar app.

---

## Windows

Runs on 100% stock Windows — no installer, no admin rights, no Python/Java/anything. It's
just a few text files that use the PowerShell and .NET already built into Windows.

**Getting it (about 2 minutes):**

1. Go to the **[Releases page](../../releases/latest)** and download **MoveIt-Windows.zip**.
2. **Right-click the zip → Extract All…**, and put the `MoveIt` folder anywhere — your
   **Documents** or **Desktop** is perfect.
3. Open the folder and **double-click `Start-MoveIt.bat`**.
4. A little **teal circle** appears down near the clock. That's it running! Can't see it?
   Click the small **^** arrow by the clock to reveal hidden icons.

> If Windows shows a blue **"Windows protected your PC"** box, that's normal for anything
> not from the Microsoft Store — click **More info → Run anyway** (once).

**Using it:** when the reminder pops up, click **I MOVED!** (counts it, restarts the
timer) or **Gimme X min** (snooze). **Right-click the teal icon** for the menu — *Move
now, Snooze, Pause/Resume, Settings, Quit*. Settings let you change the interval (default
45 min), snooze time, chime, and start-at-login.

**If the `.bat` is blocked** on a very locked-down PC: right-click **`MoveIt.ps1` → Run
with PowerShell** instead, or use the backup **`MoveIt.hta`** (double-click it — same job,
runs as a small window). Full details are in the `README.txt` inside the folder and in
[windows/](windows/).

**To uninstall:** right-click the icon → Quit, then delete the folder.

---

## Mac

A small **menu-bar app** — a teal dot up near the clock that nudges you on a timer.

**Getting it (about 2 minutes):**

1. Go to the **[Releases page](../../releases/latest)** and download **MoveIt-Mac.zip**.
2. Double-click the zip to unpack it, then drag **Move It** into your **Applications**
   folder.
3. **First time only:** macOS is cautious about apps that aren't from the App Store. If it
   refuses to open, go to **System Settings → Privacy & Security**, scroll down, and click
   **"Open Anyway"** next to the Move It message. You only do this once.
4. Look for the small **teal dot** near the top-right of your screen. You're running.

Works on any Mac from ~2020 onwards (Apple Silicon *and* Intel), macOS 13 or later.

**Using it:** when the colourful nudge appears, click **I MOVED!** (counts it, restarts
the timer) or **Gimme X min** (snooze). **Click the teal dot** for the menu — *Move now,
Snooze, Pause/Resume, Settings…, Edit Messages…, Quit*. Settings let you change the
interval (default 45 min), snooze time, chime, and **Start automatically at login**.

**To uninstall:** click the dot → Quit, then drag **Move It** from Applications to the
Trash.

---

## Make it your own (both versions)

Move It ships with about 90 funky reminder lines, picked at random. You can edit them:

- **Windows:** open `messages.txt` (in the folder) in Notepad — one message per line.
- **Mac:** menu → **Edit Messages…**. It creates a `messages.txt` in
  **Documents → Move It** and opens it; add your own, save, done.

Inside jokes strongly encouraged.

## Common questions

**Is anything sent over the internet?** No. Nothing, on either platform. It's entirely
offline.

**Is it really free?** Yes — free and open source (MIT licence). The whole thing is
readable in this repository.

**Windows vs Mac — are they the same app?** Same idea, two native builds. The Windows one
is text files (PowerShell/HTA); the Mac one is a native menu-bar app. They don't need each
other — grab whichever matches your computer.

**Something's not working / I have an idea.** Open an issue on this page (the **Issues**
tab).

---

*For the technically inclined: how each version works and how to build the Mac app are in
[DEVELOPER.md](DEVELOPER.md).*
