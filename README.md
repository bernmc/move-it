# Move It!

**A tiny, free Windows app that nudges you to get up and move — and it installs
*nothing*, so it runs even on a locked-down work PC.**

Sit at a desk all day? Move It! lives quietly down by your clock and every so often
pops up a funky reminder to stand up and stretch. You click **I MOVED!**, it counts it,
and the cycle starts again. No installer, no admin rights, no accounts, no internet.
It's just a couple of text files that run on the bits already built into Windows.

## Why it works when nothing else will install

Locked-down work computer? No permission to install programs? That's exactly what this
is for. Move It! uses **only** PowerShell and .NET — both of which already come inside
every copy of Windows. Nothing is downloaded, nothing is installed, and it never touches
the internet. To remove it, you just delete the folder.

## Getting it (about 2 minutes)

1. Go to the **[Releases page](../../releases/latest)** and download **MoveIt.zip**.
2. **Right-click the downloaded zip → Extract All…** to unpack it. Put the `MoveIt`
   folder anywhere you like — your **Documents** or **Desktop** is perfect.
3. Open the folder and **double-click `Start-MoveIt.bat`**.
4. A little **teal circle** appears down near the clock (the system tray). That's it
   running! If you can't see it, click the small **^** arrow by the clock to reveal
   hidden icons.

That's the whole install. Really.

> **If Windows shows a blue "Windows protected your PC" box:** that's normal for any app
> that isn't from the Microsoft Store. Click **More info → Run anyway**. You only do this
> once. (See [Troubleshooting](#if-it-wont-start) if the `.bat` is blocked entirely.)

## Using it day to day

- **When the reminder pops up**, you get two buttons:
  - **I MOVED!** — confirms you got up, counts it for the day, and restarts the timer
    for the next nudge.
  - **Gimme X min** — snoozes for your chosen snooze time.
- **Right-click the teal icon** for the menu:
  - **Move now!** — pop a reminder this instant
  - **Snooze** — delay the next one
  - **Pause / Resume** — mute reminders for a while
  - **Settings…** — change the timings (below)
  - **Quit** — close the app
- **Double-click the icon** = trigger a reminder right now.

## Settings

Right-click the icon → **Settings…**:

- **Remind me every (minutes)** — default **45**
- **Snooze for (minutes)** — default **5**
- **Play a chime with alerts** — on/off
- **Start automatically at login** — adds a Startup shortcut (no admin needed)

Your settings are remembered between runs (saved in a small `moveit-settings.json` file
next to the app).

## Make it your own

Open **`messages.txt`** in Notepad — it's the list of funky reminder lines, one per line.
Add your own, delete ones you don't like, save. They're picked at random. Inside jokes
strongly encouraged. (It ships with about 90 to get you started.)

## If it won't start

Some very locked-down PCs block `.bat` files. If double-clicking `Start-MoveIt.bat` does
nothing:

- **Try this instead:** right-click **`MoveIt.ps1` → Run with PowerShell**.
- **Still blocked?** There's a backup version — just double-click **`MoveIt.hta`**. It
  runs through `mshta.exe` (also built into Windows) and does the same job, except it's a
  small **window** instead of a tray icon. Minimize it to tuck it away; when it's time to
  move, it pops a big colourful alert and flashes in the taskbar. Same settings, same
  `messages.txt`.

If PowerShell **and** mshta are both blocked by company policy (rare), there's no
install-free way around that — it's an IT setting outside any app's control.

## Common questions

**Is anything sent over the internet?** No. Nothing. It's entirely offline — just files
on your PC.

**Will it get me in trouble with IT?** It installs nothing and needs no admin rights, so
there's nothing to "install" in the first place. But every workplace is different — if
you're unsure, it's only a folder of text files you can show them.

**Is it really free?** Yes — free and open source (MIT licence). The whole program is
readable text in this repository.

**How do I uninstall it?** Right-click the icon → **Quit**, then delete the folder. If you
turned on "Start automatically at login", also remove the **Move It** shortcut from your
Startup folder (press `Win + R`, type `shell:startup`, delete it there).

**Something's not working / I have an idea.** Open an issue on this page (the **Issues**
tab).

---

*For the technically inclined: how it works and how to tweak it are in
[DEVELOPER.md](DEVELOPER.md).*
