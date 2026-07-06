<#
====================================================================
  MOVE IT!  -  A get-up-and-move reminder for Windows
====================================================================
  Lives in the system tray. Nags you (nicely, funkily) to get up
  and move at a configurable interval. Snooze it, confirm you moved,
  and it auto-restarts the cycle.

  Runs on 100% stock Windows - no installs, no admin, no extras.
  Uses PowerShell + the .NET Framework that ships with Windows.

  Just double-click  Start-MoveIt.bat  to run it.
====================================================================
#>

# --- Load the GUI bits that come built into Windows --------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Where am I? (settings + messages live next to this script) -----------
$ScriptDir   = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
$ConfigPath  = Join-Path $ScriptDir 'moveit-settings.json'
$MessagePath = Join-Path $ScriptDir 'messages.txt'

# ----------------------------------------------------------------------
#  SETTINGS  (load from disk, or fall back to friendly defaults)
# ----------------------------------------------------------------------
function Get-DefaultConfig {
    [pscustomobject]@{
        IntervalMinutes  = 45      # how often to nag
        SnoozeMinutes    = 5       # the "gimme 5" delay
        Sound            = $true    # play a chime with the alert
        StartWithWindows = $false   # launch automatically at login
        MoveCount        = 0        # moves logged today
        MoveDate         = ''       # the day that count belongs to
    }
}

function Load-Config {
    $cfg = Get-DefaultConfig
    if (Test-Path $ConfigPath) {
        try {
            $saved = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            foreach ($p in $saved.PSObject.Properties) {
                if ($cfg.PSObject.Properties.Name -contains $p.Name) {
                    $cfg.$($p.Name) = $p.Value
                }
            }
        } catch { }   # corrupt file? just use defaults
    }
    # New day? reset the daily move counter.
    $today = (Get-Date).ToString('yyyy-MM-dd')
    if ($cfg.MoveDate -ne $today) { $cfg.MoveDate = $today; $cfg.MoveCount = 0 }
    return $cfg
}

function Save-Config {
    try { $script:Config | ConvertTo-Json | Set-Content $ConfigPath -Encoding UTF8 } catch { }
}

$script:Config = Load-Config

# ----------------------------------------------------------------------
#  THE FUNKY MESSAGE DATABASE
#  Edit messages.txt (one per line) to add your own. If it's missing,
#  these built-in classics are used.
# ----------------------------------------------------------------------
$BuiltInMessages = @(
    "I like to move it, move it! The lemurs demand it.",
    "Up and at 'em, hot stuff! Your chair needs a break from you.",
    "Beep boop. Human detected sitting too long. Initiate WIGGLE protocol.",
    "Stretch like a cat. Judge everyone like one too.",
    "Your spine just filed a formal complaint. Stand up!",
    "Shake your tail feather!",
    "Time to boogie! No one's watching. Probably.",
    "Hydrate AND perambulate. Double combo!",
    "Do a little dance, make a little... lap of the office.",
    "Your future self thanks you for moving RIGHT NOW.",
    "Get those legs jiggling, you magnificent desk creature.",
    "Pretend the floor is lava in 3... 2... 1...",
    "Reach for the stars! Or at least the ceiling.",
    "Stand up and feel superior to all the still-sitting people.",
    "Wiggle break! It's the law. (My law.)",
    "Move it or lose it, buttercup.",
    "Channel your inner flamingo. Stand on one leg.",
    "The water cooler misses you. Go gossip.",
    "Booty shakes burn calories. Science! (probably)",
    "Roll those shoulders back, your majesty."
)

$PraiseMessages = @(
    "Look at you GO!",
    "Certified Mover. Gold star.",
    "Your hips don't lie, and neither does your step count.",
    "Boom. Movement banked.",
    "The lemurs are proud.",
    "Smooth moves. Truly.",
    "That's how it's done!"
)

function Get-Messages {
    if (Test-Path $MessagePath) {
        $lines = Get-Content $MessagePath | Where-Object { $_.Trim() -ne '' }
        if ($lines.Count -gt 0) { return $lines }
    }
    return $BuiltInMessages
}

# A fun emoji to headline the popup (rotates randomly)
$Emojis = @([char]::ConvertFromUtf32(0x1F98E), # lizard
            [char]::ConvertFromUtf32(0x1F483), # dancer
            [char]::ConvertFromUtf32(0x1F57A), # man dancing
            [char]::ConvertFromUtf32(0x1F995), # dino
            [char]::ConvertFromUtf32(0x1F9A9), # flamingo
            [char]::ConvertFromUtf32(0x1F4AA), # muscle
            [char]::ConvertFromUtf32(0x1F3C3), # runner
            [char]::ConvertFromUtf32(0x1F386)) # fireworks

# Funky background palette for the popup.
# These are deep/saturated on purpose so white text always pops against them.
$Palette = @(
    [System.Drawing.Color]::FromArgb(197, 34, 92),   # raspberry
    [System.Drawing.Color]::FromArgb(63, 55, 201),   # indigo
    [System.Drawing.Color]::FromArgb(0, 121, 107),   # teal
    [System.Drawing.Color]::FromArgb(198, 87, 30),   # burnt orange
    [System.Drawing.Color]::FromArgb(106, 61, 196),  # purple
    [System.Drawing.Color]::FromArgb(171, 39, 79)    # crimson
)

# ----------------------------------------------------------------------
#  TRAY ICON  (drawn on the fly - a bright "go" circle)
# ----------------------------------------------------------------------
function New-TrayIcon {
    $bmp = New-Object System.Drawing.Bitmap 32,32
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.Clear([System.Drawing.Color]::Transparent)
    $fill = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,0,191,165))
    $g.FillEllipse($fill, 1, 1, 30, 30)
    # white "play / go" triangle in the middle
    $tri = [System.Drawing.Point[]]@(
        (New-Object System.Drawing.Point 12,9),
        (New-Object System.Drawing.Point 24,16),
        (New-Object System.Drawing.Point 12,23))
    $g.FillPolygon([System.Drawing.Brushes]::White, $tri)
    $g.Dispose()
    return [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}
$AppIcon = New-TrayIcon

# ----------------------------------------------------------------------
#  THE ALERT POPUP
#  Returns 'moved' or 'snooze'.
# ----------------------------------------------------------------------
function Show-MoveAlert {
    $messages = Get-Messages
    $msg   = $messages   | Get-Random
    $emoji = $Emojis     | Get-Random
    # Index-based pick (piping a nested array through Get-Random is unreliable)
    $bg    = $Palette[(Get-Random -Maximum $Palette.Count)]

    $form = New-Object System.Windows.Forms.Form
    $form.Text            = 'MOVE IT!'
    $form.Size            = New-Object System.Drawing.Size 480, 320
    $form.StartPosition   = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox     = $false
    $form.MinimizeBox     = $false
    $form.TopMost         = $true
    $form.BackColor       = $bg
    $form.Icon            = $AppIcon
    $form.ControlBox      = $false

    $lblEmoji = New-Object System.Windows.Forms.Label
    $lblEmoji.Text      = $emoji
    $lblEmoji.Font      = New-Object System.Drawing.Font('Segoe UI Emoji', 56)
    $lblEmoji.ForeColor = [System.Drawing.Color]::White
    $lblEmoji.BackColor = $bg
    $lblEmoji.TextAlign = 'MiddleCenter'
    $lblEmoji.Dock      = 'Top'
    $lblEmoji.Height    = 110
    $form.Controls.Add($lblEmoji)

    $lblMsg = New-Object System.Windows.Forms.Label
    $lblMsg.Text      = $msg
    $lblMsg.Font      = New-Object System.Drawing.Font('Segoe UI Semibold', 14)
    $lblMsg.ForeColor = [System.Drawing.Color]::White
    $lblMsg.BackColor = $bg
    $lblMsg.TextAlign = 'MiddleCenter'
    $lblMsg.Location  = New-Object System.Drawing.Point 20, 115
    $lblMsg.Size      = New-Object System.Drawing.Size 440, 90
    $form.Controls.Add($lblMsg)

    $btnMoved = New-Object System.Windows.Forms.Button
    $btnMoved.Text      = 'I MOVED!'
    $btnMoved.Font      = New-Object System.Drawing.Font('Segoe UI Semibold', 12)
    $btnMoved.Size      = New-Object System.Drawing.Size 200, 50
    $btnMoved.Location  = New-Object System.Drawing.Point 30, 225
    $btnMoved.BackColor = [System.Drawing.Color]::White
    $btnMoved.ForeColor = $bg
    $btnMoved.FlatStyle = 'Flat'
    $btnMoved.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnMoved)

    $btnSnooze = New-Object System.Windows.Forms.Button
    $btnSnooze.Text      = "Gimme $($script:Config.SnoozeMinutes) min"
    $btnSnooze.Font      = New-Object System.Drawing.Font('Segoe UI', 12)
    $btnSnooze.Size      = New-Object System.Drawing.Size 200, 50
    $btnSnooze.Location  = New-Object System.Drawing.Point 250, 225
    $btnSnooze.BackColor = $bg
    $btnSnooze.ForeColor = [System.Drawing.Color]::White
    $btnSnooze.FlatStyle = 'Flat'
    $btnSnooze.FlatAppearance.BorderColor = [System.Drawing.Color]::White
    $btnSnooze.FlatAppearance.BorderSize  = 2
    $btnSnooze.DialogResult = [System.Windows.Forms.DialogResult]::Retry
    $form.Controls.Add($btnSnooze)

    $form.AcceptButton = $btnMoved

    if ($script:Config.Sound) {
        try { [System.Media.SystemSounds]::Exclamation.Play() } catch { }
    }

    $form.Add_Shown({ $form.Activate() })
    $result = $form.ShowDialog()
    $form.Dispose()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) { return 'moved' }
    return 'snooze'
}

# ----------------------------------------------------------------------
#  SETTINGS WINDOW
# ----------------------------------------------------------------------
function Show-Settings {
    $f = New-Object System.Windows.Forms.Form
    $f.Text            = 'Move It - Settings'
    $f.Size            = New-Object System.Drawing.Size 360, 320
    $f.StartPosition   = 'CenterScreen'
    $f.FormBorderStyle = 'FixedDialog'
    $f.MaximizeBox     = $false
    $f.MinimizeBox     = $false
    $f.Icon            = $AppIcon

    $lbl1 = New-Object System.Windows.Forms.Label
    $lbl1.Text = 'Remind me every (minutes):'
    $lbl1.Location = New-Object System.Drawing.Point 20, 20
    $lbl1.AutoSize = $true
    $f.Controls.Add($lbl1)

    $numInterval = New-Object System.Windows.Forms.NumericUpDown
    $numInterval.Minimum  = 1
    $numInterval.Maximum  = 600
    $numInterval.Value    = [int]$script:Config.IntervalMinutes
    $numInterval.Location = New-Object System.Drawing.Point 230, 18
    $numInterval.Width    = 90
    $f.Controls.Add($numInterval)

    $lbl2 = New-Object System.Windows.Forms.Label
    $lbl2.Text = 'Snooze for (minutes):'
    $lbl2.Location = New-Object System.Drawing.Point 20, 60
    $lbl2.AutoSize = $true
    $f.Controls.Add($lbl2)

    $numSnooze = New-Object System.Windows.Forms.NumericUpDown
    $numSnooze.Minimum  = 1
    $numSnooze.Maximum  = 120
    $numSnooze.Value    = [int]$script:Config.SnoozeMinutes
    $numSnooze.Location = New-Object System.Drawing.Point 230, 58
    $numSnooze.Width    = 90
    $f.Controls.Add($numSnooze)

    $chkSound = New-Object System.Windows.Forms.CheckBox
    $chkSound.Text     = 'Play a chime with each alert'
    $chkSound.Checked  = [bool]$script:Config.Sound
    $chkSound.Location = New-Object System.Drawing.Point 20, 100
    $chkSound.AutoSize = $true
    $f.Controls.Add($chkSound)

    $chkStartup = New-Object System.Windows.Forms.CheckBox
    $chkStartup.Text     = 'Start automatically when I log in'
    $chkStartup.Checked  = [bool]$script:Config.StartWithWindows
    $chkStartup.Location = New-Object System.Drawing.Point 20, 130
    $chkStartup.AutoSize = $true
    $f.Controls.Add($chkStartup)

    $lblInfo = New-Object System.Windows.Forms.Label
    $lblInfo.Text     = "Tip: edit messages.txt (next to this app) to add your own funky reminders."
    $lblInfo.Location = New-Object System.Drawing.Point 20, 165
    $lblInfo.Size     = New-Object System.Drawing.Size 310, 50
    $lblInfo.ForeColor = [System.Drawing.Color]::Gray
    $f.Controls.Add($lblInfo)

    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text     = 'Save'
    $btnOK.Location = New-Object System.Drawing.Point 150, 230
    $btnOK.Size     = New-Object System.Drawing.Size 80, 32
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $f.Controls.Add($btnOK)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text     = 'Cancel'
    $btnCancel.Location = New-Object System.Drawing.Point 240, 230
    $btnCancel.Size     = New-Object System.Drawing.Size 80, 32
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $f.Controls.Add($btnCancel)

    $f.AcceptButton = $btnOK
    $f.CancelButton = $btnCancel

    if ($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:Config.IntervalMinutes  = [int]$numInterval.Value
        $script:Config.SnoozeMinutes    = [int]$numSnooze.Value
        $script:Config.Sound            = [bool]$chkSound.Checked
        $script:Config.StartWithWindows = [bool]$chkStartup.Checked
        Save-Config
        Set-Startup -Enable $script:Config.StartWithWindows
        Reset-Timer $script:Config.IntervalMinutes
        Update-Tooltip
    }
    $f.Dispose()
}

# ----------------------------------------------------------------------
#  START-WITH-WINDOWS  (drops a shortcut in the Startup folder)
# ----------------------------------------------------------------------
function Set-Startup {
    param([bool]$Enable)
    $startupDir = [Environment]::GetFolderPath('Startup')
    $lnkPath    = Join-Path $startupDir 'Move It.lnk'
    $batPath    = Join-Path $ScriptDir 'Start-MoveIt.bat'
    try {
        if ($Enable) {
            $ws = New-Object -ComObject WScript.Shell
            $sc = $ws.CreateShortcut($lnkPath)
            $sc.TargetPath       = $batPath
            $sc.WorkingDirectory = $ScriptDir
            $sc.Description       = 'Move It - movement reminder'
            $sc.Save()
        } elseif (Test-Path $lnkPath) {
            Remove-Item $lnkPath -Force
        }
    } catch { }
}

# ----------------------------------------------------------------------
#  TIMER + TRAY PLUMBING
# ----------------------------------------------------------------------
$script:Timer = New-Object System.Windows.Forms.Timer

function Reset-Timer {
    param([double]$Minutes)
    $script:Timer.Stop()
    $ms = [int]([Math]::Max(1, $Minutes) * 60 * 1000)
    $script:Timer.Interval = $ms
    $script:Timer.Start()
}

$script:Notify = New-Object System.Windows.Forms.NotifyIcon
$script:Notify.Icon    = $AppIcon
$script:Notify.Visible = $true

function Update-Tooltip {
    $next = $script:Config.IntervalMinutes
    # NotifyIcon text is capped at 63 chars
    $script:Notify.Text = "Move It! - every $next min - moves today: $($script:Config.MoveCount)"
}
Update-Tooltip

# The core nag cycle
function Trigger-Alert {
    $script:Timer.Stop()
    $choice = Show-MoveAlert
    if ($choice -eq 'moved') {
        $script:Config.MoveCount = [int]$script:Config.MoveCount + 1
        Save-Config
        Update-Tooltip
        $praise = $PraiseMessages | Get-Random
        try { $script:Notify.ShowBalloonTip(2500, 'Nice!', "$praise  (moves today: $($script:Config.MoveCount))", 'Info') } catch { }
        Reset-Timer $script:Config.IntervalMinutes      # auto-restart the cycle
    } else {
        Reset-Timer $script:Config.SnoozeMinutes        # gimme 5
    }
}

$script:Timer.Add_Tick({ Trigger-Alert })

# Double-click the tray icon = move right now
$script:Notify.Add_DoubleClick({ Trigger-Alert })

# ----------------------------------------------------------------------
#  TRAY RIGHT-CLICK MENU
# ----------------------------------------------------------------------
$menu = New-Object System.Windows.Forms.ContextMenuStrip

$miMoveNow = $menu.Items.Add('Move now!')
$miMoveNow.Add_Click({ Trigger-Alert })

$miSnooze = $menu.Items.Add('Snooze')
$miSnooze.Add_Click({ Reset-Timer $script:Config.SnoozeMinutes })

$menu.Items.Add('-') | Out-Null

$script:miPause = $menu.Items.Add('Pause reminders')
$script:Paused = $false
$script:miPause.Add_Click({
    if ($script:Paused) {
        Reset-Timer $script:Config.IntervalMinutes
        $script:Paused = $false
        $script:miPause.Text = 'Pause reminders'
    } else {
        $script:Timer.Stop()
        $script:Paused = $true
        $script:miPause.Text = 'Resume reminders'
    }
})

$miSettings = $menu.Items.Add('Settings...')
$miSettings.Add_Click({ Show-Settings })

$menu.Items.Add('-') | Out-Null

$miQuit = $menu.Items.Add('Quit')
$miQuit.Add_Click({
    $script:Timer.Stop()
    $script:Notify.Visible = $false
    $script:Notify.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$script:Notify.ContextMenuStrip = $menu

# ----------------------------------------------------------------------
#  GO!
# ----------------------------------------------------------------------
Set-Startup -Enable $script:Config.StartWithWindows
Reset-Timer $script:Config.IntervalMinutes

# Friendly hello so she knows it's running
try { $script:Notify.ShowBalloonTip(3000, 'Move It is on the job!',
    "I'll nudge you every $($script:Config.IntervalMinutes) min. Right-click the tray icon for options.", 'Info') } catch { }

# Keep the app alive in the tray (this is the message loop)
$context = New-Object System.Windows.Forms.ApplicationContext
[System.Windows.Forms.Application]::Run($context)
