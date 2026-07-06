====================================================================
  MOVE IT!  -  a get-up-and-move reminder for Windows
====================================================================

WHAT IT IS
  A little app that lives in your system tray (down by the clock)
  and pops up a funky reminder to stand up and move every so often.
  Snooze it, confirm you moved, and it keeps the cycle going.

WHY IT WORKS ON A LOCKED-DOWN WORK PC
  It installs NOTHING. No Python, no Java, no setup file, no admin
  rights. It runs entirely on PowerShell + the .NET that already
  ships inside every copy of Windows. It's just text files.

--------------------------------------------------------------------
HOW TO RUN IT
--------------------------------------------------------------------
  1. Copy the whole "MoveIt" folder somewhere on the work PC
     (Documents or the Desktop is fine).
  2. Double-click   Start-MoveIt.bat
  3. A little teal circle icon appears near the clock. That's it
     running. (If it's hidden, click the small "^" arrow by the
     clock to find it.)

  To stop it: right-click the tray icon -> Quit.

--------------------------------------------------------------------
USING IT
--------------------------------------------------------------------
  RIGHT-CLICK the tray icon for the menu:
     Move now!          - pop the reminder immediately
     Snooze             - delay by your snooze time
     Pause / Resume     - mute reminders for a bit
     Settings...        - change the timings (see below)
     Quit               - close the app

  DOUBLE-CLICK the tray icon = trigger a move reminder right now.

  WHEN THE POPUP APPEARS:
     "I MOVED!"      - confirms you moved; counts it; restarts the
                       timer for the next nudge.
     "Gimme X min"   - snoozes for your chosen snooze time.

--------------------------------------------------------------------
SETTINGS  (right-click tray -> Settings...)
--------------------------------------------------------------------
  - Remind me every (minutes)   default 45
  - Snooze for (minutes)        default 5
  - Play a chime with alerts    on/off
  - Start automatically at login (adds a Startup shortcut - no admin)

  Settings are saved in  moveit-settings.json  next to the app.

--------------------------------------------------------------------
ADD YOUR OWN FUNNY MESSAGES
--------------------------------------------------------------------
  Open  messages.txt  in Notepad. Put one message per line. Save.
  They're picked at random. Go wild - inside jokes welcome.

--------------------------------------------------------------------
IF DOUBLE-CLICKING THE .BAT DOESN'T WORK
--------------------------------------------------------------------
  Some very locked-down PCs block .bat files. If so, try this:
  right-click  MoveIt.ps1  ->  "Run with PowerShell".

  If PowerShell itself is blocked by company policy (rare), there's
  unfortunately no install-free way around it - that's an IT setting.
  Everything here uses only what Windows already allows by default.

--------------------------------------------------------------------
BACKUP VERSION:  MoveIt.hta
--------------------------------------------------------------------
  If PowerShell is blocked, try the HTA version instead - just
  double-click  MoveIt.hta . It runs through mshta.exe, which is
  also built into Windows, and uses the same messages.txt file.

  Differences from the PowerShell version:
    - It's a small WINDOW (not a tray icon). Minimize it to get it
      out of the way; when it's time to move, it pops a big colorful
      alert and flashes in the taskbar.
    - Same features: configurable interval + snooze, "I MOVED!"
      confirmation, auto-restart, start-with-Windows, funky random
      messages, daily move count.
    - Settings are saved in moveit-settings.txt next to the app.

  Use whichever one runs on her machine - they don't need each other.
====================================================================
