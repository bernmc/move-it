// ====================================================================
//  MOVE IT!  —  a get-up-and-move reminder for macOS
// ====================================================================
//  Lives in the menu bar as a little teal dot. Every so often it pops
//  a funky, colourful nudge to stand up and move. Click "I MOVED!" to
//  confirm (it counts your daily moves and restarts the cycle), or
//  snooze with "Gimme X min".
//
//  Native, single-file AppKit app. No dependencies, no installer.
//  The Mac sibling of the Windows "Move It!" (PowerShell/HTA) version.
//  Build with ./build.sh — user instructions are in the repo README.
// ====================================================================

import AppKit
import ServiceManagement

// MARK: - Defaults & storage keys ------------------------------------

private enum K {
    static let interval  = "IntervalMinutes"
    static let snooze    = "SnoozeMinutes"
    static let sound     = "Sound"
    static let moveCount = "MoveCount"
    static let moveDate  = "MoveDate"          // yyyy-MM-dd the count belongs to

    static let defaultInterval = 45
    static let defaultSnooze   = 5
}

// MARK: - Config (persisted in UserDefaults) -------------------------

final class Config {
    private let d = UserDefaults.standard

    init() {
        // Seed friendly defaults on first run.
        if d.object(forKey: K.interval) == nil { d.set(K.defaultInterval, forKey: K.interval) }
        if d.object(forKey: K.snooze)   == nil { d.set(K.defaultSnooze,   forKey: K.snooze) }
        if d.object(forKey: K.sound)    == nil { d.set(true,              forKey: K.sound) }
    }

    var intervalMinutes: Int {
        get { max(1, d.integer(forKey: K.interval)) }
        set { d.set(max(1, newValue), forKey: K.interval) }
    }
    var snoozeMinutes: Int {
        get { max(1, d.integer(forKey: K.snooze)) }
        set { d.set(max(1, newValue), forKey: K.snooze) }
    }
    var sound: Bool {
        get { d.bool(forKey: K.sound) }
        set { d.set(newValue, forKey: K.sound) }
    }

    // Daily move count, auto-reset when the date rolls over.
    private func today() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
    var moveCount: Int {
        if d.string(forKey: K.moveDate) != today() { return 0 }
        return d.integer(forKey: K.moveCount)
    }
    func logMove() {
        let t = today()
        let n = (d.string(forKey: K.moveDate) == t) ? d.integer(forKey: K.moveCount) : 0
        d.set(n + 1, forKey: K.moveCount)
        d.set(t, forKey: K.moveDate)
    }
}

// MARK: - Messages ---------------------------------------------------
//  Read the user's own list from ~/Documents/Move It/messages.txt if it
//  exists (one message per line); otherwise fall back to these built-in
//  favourites. "Edit Messages…" creates the file so it can be edited.

enum Messages {
    static var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Move It").appendingPathComponent("messages.txt")
    }

    static func load() -> [String] {
        if let text = try? String(contentsOf: fileURL, encoding: .utf8) {
            let lines = text.split(whereSeparator: \.isNewline)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            if !lines.isEmpty { return lines }
        }
        return builtIn
    }

    /// Make sure the editable file exists (seeded with the built-ins), return its URL.
    @discardableResult
    static func ensureFile() -> URL {
        let url = fileURL
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            try? fm.createDirectory(at: url.deletingLastPathComponent(),
                                    withIntermediateDirectories: true)
            let header = "# Move It! messages — one per line. Lines starting with # are ignored.\n"
                       + "# Edit freely, save, and Move It picks them at random. Inside jokes welcome.\n\n"
            try? (header + builtIn.joined(separator: "\n") + "\n").write(to: url, atomically: true, encoding: .utf8)
        }
        return url
    }

    static let builtIn: [String] = [
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
        "Roll those shoulders back, your majesty.",
        "Quick! Touch your toes before they file a missing-persons report.",
        "Your step counter is sobbing quietly. Go console it.",
        "Strut to the kitchen like you own the place.",
        "Twist! Bend! Wiggle! Repeat! You glorious noodle.",
        "Stand up and shake it off like a wet dog. Go on.",
        "Your chair and you need to see other people. Take a break.",
        "Achievement unlocked: Leave The Chair. Reward: not being a gargoyle.",
        "Gravity is winning. Fight back. Stand up.",
        "Do the floss. Yes, the dance. Yes, right now. I'll wait.",
        "Plot twist: the legs work! Use them!",
        "Pretend you're a marionette and someone yanked your strings UP.",
        "Stretch like you're the last cat in a sun puddle.",
        "Marching on the spot counts. Knees up, soldier!",
        "Be a tree in a hurricane. Sway dramatically. Commit.",
        "Your butt has gone to sleep. Wake it with a lap of the room.",
        "Strike a superhero pose. Hands on hips. Feel powerful. Now walk it off.",
        "Imagine a tiny crowd chanting your name. Now jog to the kettle.",
        "Wiggle every toe. Then every finger. Then leave. Bye!",
        "Shimmy now, spreadsheet later.",
        "Your hamstrings are writing you a strongly-worded letter.",
        "Stand up so fast the chair gets whiplash.",
        "It's the moooove, the get-up-and-grooove. Lemurs approve.",
        "Do three squats. Nobody will know. (I'll know. I'm proud.)",
        "Reach up like you're grabbing the last biscuit on the top shelf.",
        "Pretend you dropped something. Now stretch to 'find' it.",
        "Disco arms! Point at the ceiling, point at the floor. Repeat.",
        "Be the office legend who actually stretches. Iconic.",
        "Roll your neck slowly. Hear that? That's progress.",
        "Up you get, you absolute desk gremlin. Bipedal time.",
        "Walk to a window. Look smug. Look at clouds. Come back.",
        "Your blood is pooling. Pump it! March, march, march!",
        "Do a little victory wiggle. You haven't won anything. Wiggle anyway.",
        "Earth to body: WE HAVE LEGS. Please confirm by standing.",
        "Channel a flamingo, then a giraffe, then a very tall human. Stretch up!",
        "Shake your hands out like you just washed them and there's no towel.",
        "Big stretch! Yawn allowed. Reach for the sky and own it.",
        "The 'sitting Olympics' has no medals. Get up and do a real lap.",
        "Bounce on your heels ten times. Boing. Boing. Better already.",
        "Sashay to the nearest window and give the sky a slow, judgmental nod.",
        "Go refill your water. Take the long way. Add a twirl at the corner.",
        "Ten calf raises while the kettle boils. Up, up, up, you tiptoe legend.",
        "Tango to the printer and back. Rose in teeth optional.",
        "Do the sprinkler. Just once. Then act like nothing happened.",
        "March to the far end of the office and high-five the wall.",
        "Air-guitar a solo. Windmill arm mandatory. Take a bow.",
        "Power-walk one lap like you're late but fabulous.",
        "Squat to pick up something imaginary. Groan for authenticity.",
        "Stand and do slow-motion running for ten seconds. Chariots of Fire.",
        "Reach for the ceiling, then touch your toes. Be the world's tallest slinky.",
        "Moonwalk to the bin, drop nothing in it, moonwalk back.",
        "Do five star jumps. Startle a colleague. Bond over it.",
        "Wander to the kitchen and reorganise one mug. Stretch while judging it.",
        "Shoulder shimmy your way to the water cooler. Own the shimmy.",
        "Do the robot to the coffee machine. Beep responsibly.",
        "Big lunge forward. Hold. Look heroic. Lunge back. Encore.",
        "Take a lap and wave regally at everyone like a passing monarch.",
        "Stand on tiptoes and 'reach the top shelf' of imaginary snacks.",
        "Do a slow hip circle. Yes. Like a rusty hula hoop. Loosen up.",
        "Strut to reception like it's a catwalk and you're the finale.",
        "Bust out jazz hands, then walk them all the way to the kitchen.",
        "Pace while you think. Congratulations, you're now a Serious Thinker.",
        "Do the twist all the way down and all the way back up. Chubby Checker nods.",
        "Gallop — actual gallop — to the far door. Neigh optional but encouraged.",
        "Ten shoulder rolls back, then swan off to fetch a cuppa.",
        "Stretch tall, wobble side to side, then waddle to the window like a penguin.",
        "Do a little shadow-boxing. Jab, jab, escape the chair. Float like a butterfly.",
        "Skip (yes, SKIP) to the nearest exit and back. Feel eight years old.",
        "Do a dramatic slow stand like you're rising for a standing ovation. You've earned it.",
        "Wiggle to the kitchen, do one victory spin, wiggle back. Champion.",
        "Touch each wall of the room. It's a quest. You are the hero.",
        "Do the disco point across the whole office. Saturday Night Desk Fever.",
        "Stretch your arms wide and 'hug the room', then go for an actual wander.",
        "Bounce over to a coworker and ask them absolutely nothing. Bounce back.",
    ]
}

// MARK: - The funky nudge window -------------------------------------

final class NudgeWindow: NSWindow {
    private let onMoved: () -> Void
    private let onSnooze: () -> Void

    init(message: String, snoozeMinutes: Int, onMoved: @escaping () -> Void, onSnooze: @escaping () -> Void) {
        self.onMoved = onMoved
        self.onSnooze = onSnooze
        let size = NSSize(width: 560, height: 300)
        super.init(contentRect: NSRect(origin: .zero, size: size),
                   styleMask: [.borderless],
                   backing: .buffered, defer: false)

        isOpaque = false
        backgroundColor = .clear          // transparent corners around the rounded card
        isReleasedWhenClosed = false      // we manage lifetime via the owning property
        level = .floating
        hasShadow = true
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // A random vibrant background — different funky colour each time.
        let palette: [NSColor] = [
            NSColor(calibratedHue: 0.48, saturation: 0.85, brightness: 0.80, alpha: 1), // teal
            NSColor(calibratedHue: 0.92, saturation: 0.70, brightness: 0.95, alpha: 1), // pink
            NSColor(calibratedHue: 0.09, saturation: 0.90, brightness: 0.98, alpha: 1), // orange
            NSColor(calibratedHue: 0.75, saturation: 0.65, brightness: 0.85, alpha: 1), // purple
            NSColor(calibratedHue: 0.33, saturation: 0.70, brightness: 0.78, alpha: 1), // green
            NSColor(calibratedHue: 0.58, saturation: 0.75, brightness: 0.90, alpha: 1), // blue
        ]
        let bg = palette.randomElement()!

        let root = NSView(frame: NSRect(origin: .zero, size: size))
        root.wantsLayer = true
        root.layer?.backgroundColor = bg.cgColor
        root.layer?.cornerRadius = 22
        contentView = root

        // Title
        let title = NSTextField(labelWithString: "MOVE IT!")
        title.font = .systemFont(ofSize: 30, weight: .heavy)
        title.textColor = .white
        title.alignment = .center
        title.frame = NSRect(x: 20, y: size.height - 78, width: size.width - 40, height: 40)
        root.addSubview(title)

        // The random message
        let msg = NSTextField(wrappingLabelWithString: message)
        msg.font = .systemFont(ofSize: 19, weight: .semibold)
        msg.textColor = .white
        msg.alignment = .center
        msg.isEditable = false
        msg.isSelectable = false
        msg.drawsBackground = false
        msg.isBezeled = false
        msg.frame = NSRect(x: 34, y: 96, width: size.width - 68, height: 110)
        root.addSubview(msg)

        // Buttons — bold, solid, high-contrast pills that read on any background colour.
        let moved = pill(title: "I MOVED!  🎉",
                         fill: .white,
                         text: NSColor(white: 0.10, alpha: 1),
                         action: #selector(movedTapped))
        moved.keyEquivalent = "\r"                     // Return activates it
        moved.frame = NSRect(x: 76, y: 34, width: 224, height: 50)
        root.addSubview(moved)

        let snooze = pill(title: "Gimme \(snoozeMinutes) min",
                          fill: NSColor(white: 0, alpha: 0.30),
                          text: .white,
                          action: #selector(snoozeTapped))
        snooze.frame = NSRect(x: 312, y: 34, width: 172, height: 50)
        root.addSubview(snooze)

        center()
    }

    /// A borderless, solid-fill rounded "pill" button with a bold coloured title.
    private func pill(title: String, fill: NSColor, text: NSColor, action: Selector) -> NSButton {
        let b = NSButton(title: "", target: self, action: action)
        b.isBordered = false
        b.wantsLayer = true
        b.layer?.backgroundColor = fill.cgColor
        b.layer?.cornerRadius = 25
        b.attributedTitle = NSAttributedString(string: title, attributes: [
            .foregroundColor: text,
            .font: NSFont.systemFont(ofSize: 17, weight: .heavy),
        ])
        return b
    }

    // Hide immediately, then run the callback on the next tick so we're not
    // tearing this window (and its button) down while its click is still firing.
    @objc private func movedTapped()  { let cb = onMoved;  orderOut(nil); DispatchQueue.main.async(execute: cb) }
    @objc private func snoozeTapped() { let cb = onSnooze; orderOut(nil); DispatchQueue.main.async(execute: cb) }
}

// MARK: - The "well done!" toast -------------------------------------
//  A small self-dismissing confirmation that slides in near the menu bar
//  after you move — the Mac echo of the Windows tray balloon.

final class ToastWindow: NSWindow {
    init(title: String, body: String) {
        let size = NSSize(width: 400, height: 128)
        super.init(contentRect: NSRect(origin: .zero, size: size),
                   styleMask: [.borderless], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        isReleasedWhenClosed = false      // we manage lifetime via the owning property
        level = .floating
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let root = NSView(frame: NSRect(origin: .zero, size: size))
        root.wantsLayer = true
        // A cheerful green — white text stays legible (same principle as the nudge).
        root.layer?.backgroundColor =
            NSColor(calibratedHue: 0.36, saturation: 0.72, brightness: 0.60, alpha: 1).cgColor
        root.layer?.cornerRadius = 20
        contentView = root

        let t = NSTextField(labelWithString: title)
        t.font = .systemFont(ofSize: 21, weight: .heavy)
        t.textColor = .white
        t.frame = NSRect(x: 22, y: size.height - 48, width: size.width - 44, height: 30)
        root.addSubview(t)

        let b = NSTextField(wrappingLabelWithString: body)
        b.font = .systemFont(ofSize: 15, weight: .semibold)
        b.textColor = .white
        b.isEditable = false; b.isSelectable = false
        b.drawsBackground = false; b.isBezeled = false
        b.frame = NSRect(x: 22, y: 16, width: size.width - 44, height: 58)
        root.addSubview(b)

        // Tuck into the top-right, just under the menu bar (visibleFrame excludes it).
        if let screen = NSScreen.main {
            let vf = screen.visibleFrame
            setFrameOrigin(NSPoint(x: vf.maxX - size.width - 16, y: vf.maxY - size.height - 16))
        }
    }
}

// MARK: - App --------------------------------------------------------

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let cfg = Config()
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var paused = false
    private var nudge: NudgeWindow?

    // Menu items we update dynamically
    private let pauseItem = NSMenuItem(title: "Pause", action: #selector(togglePause), keyEquivalent: "")
    private let countItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")

    func applicationDidFinishLaunching(_ note: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = menuBarIcon()
        buildMenu()
        scheduleNext(minutes: cfg.intervalMinutes)
    }

    // A running figure for the menu bar — a template symbol so it adapts to the
    // light/dark menu bar automatically. Falls back to a teal dot on old systems.
    private func menuBarIcon() -> NSImage {
        let cfg = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        if let runner = NSImage(systemSymbolName: "figure.run", accessibilityDescription: "Move It")?
            .withSymbolConfiguration(cfg) {
            runner.isTemplate = true
            return runner
        }
        let dot = tealDot()
        dot.isTemplate = false
        return dot
    }

    // A small teal dot for the menu bar (fallback only).
    private func tealDot() -> NSImage {
        let d: CGFloat = 16
        let img = NSImage(size: NSSize(width: d, height: d))
        img.lockFocus()
        NSColor(calibratedHue: 0.48, saturation: 0.85, brightness: 0.78, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: d - 4, height: d - 4)).fill()
        img.unlockFocus()
        return img
    }

    // MARK: Menu

    private func buildMenu() {
        let m = NSMenu()
        m.addItem(withTitle: "Move now!", action: #selector(moveNow), keyEquivalent: "")
        m.addItem(withTitle: "Snooze", action: #selector(snoozeFromMenu), keyEquivalent: "")
        pauseItem.target = self
        m.addItem(pauseItem)
        m.addItem(.separator())
        countItem.isEnabled = false
        m.addItem(countItem)
        m.addItem(.separator())
        m.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        m.addItem(withTitle: "Edit Messages…", action: #selector(editMessages), keyEquivalent: "")
        m.addItem(.separator())
        m.addItem(withTitle: "About Move It!", action: #selector(about), keyEquivalent: "")
        m.addItem(withTitle: "Quit Move It!", action: #selector(quit), keyEquivalent: "q")
        for item in m.items where item.action != nil { item.target = self }
        m.delegate = self
        statusItem.menu = m
    }

    private func refreshMenu() {
        pauseItem.title = paused ? "Resume" : "Pause"
        let n = cfg.moveCount
        countItem.title = "Moved \(n) time\(n == 1 ? "" : "s") today"
    }

    // MARK: Scheduling

    private func scheduleNext(minutes: Int) {
        timer?.invalidate()
        guard !paused else { return }
        timer = Timer.scheduledTimer(withTimeInterval: Double(minutes) * 60,
                                     repeats: false) { [weak self] _ in
            self?.fireNudge()
        }
    }

    private func fireNudge() {
        // Don't stack windows if one is already up.
        if nudge != nil { return }
        let message = Messages.load().randomElement() ?? "Time to move!"
        if cfg.sound { NSSound(named: "Ping")?.play() }

        let w = NudgeWindow(message: message, snoozeMinutes: cfg.snoozeMinutes,
            onMoved: { [weak self] in
                guard let self = self else { return }
                self.cfg.logMove()
                self.showToast()
                self.nudge = nil
                self.scheduleNext(minutes: self.cfg.intervalMinutes)
            },
            onSnooze: { [weak self] in
                guard let self = self else { return }
                self.nudge = nil
                self.scheduleNext(minutes: self.cfg.snoozeMinutes)
            })
        nudge = w
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
    }

    // MARK: The "well done!" toast

    private var toast: ToastWindow?
    private var toastTimer: Timer?

    private static let praise = [
        "King Julian would be proud. 👑",
        "Look at you GO!",
        "Certified Mover. Gold star. ⭐️",
        "The lemurs are proud.",
        "Boom. Movement banked.",
        "Smooth moves. Truly.",
        "That's how it's done!",
        "Your hips don't lie, and neither does your step count.",
    ]

    private func showToast() {
        let n = cfg.moveCount
        let line = Self.praise.randomElement() ?? "Nice one!"
        let w = ToastWindow(title: "Well done! 🎉", body: "\(line)\nMoves today: \(n)")

        toast?.close()
        toast = w
        w.alphaValue = 0
        w.orderFrontRegardless()          // show without stealing focus
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            w.animator().alphaValue = 1
        }

        // Auto-dismiss after ~2.8s (matches the Windows balloon), fading out.
        toastTimer?.invalidate()
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.8, repeats: false) { [weak self] _ in
            guard let self = self, let win = self.toast else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.35
                win.animator().alphaValue = 0
            }, completionHandler: {
                win.close()
                self.toast = nil
            })
        }
    }

    // MARK: Menu actions

    @objc private func moveNow() { fireNudge() }

    @objc private func snoozeFromMenu() { scheduleNext(minutes: cfg.snoozeMinutes) }

    @objc private func togglePause() {
        paused.toggle()
        if paused { timer?.invalidate() } else { scheduleNext(minutes: cfg.intervalMinutes) }
        refreshMenu()
    }

    @objc private func editMessages() {
        let url = Messages.ensureFile()
        NSWorkspace.shared.open(url)
    }

    @objc private func about() {
        NSApp.activate(ignoringOtherApps: true)
        let a = NSAlert()
        a.messageText = "Move It!"
        a.informativeText = "A friendly get-up-and-move reminder.\n\n"
            + "Free and open source (MIT). Your data never leaves this Mac.\n"
            + "The Mac companion to the Windows version."
        a.addButton(withTitle: "OK")
        a.runModal()
    }

    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: Settings window

    private var settingsWindow: NSWindow?

    @objc private func openSettings() {
        if let w = settingsWindow { NSApp.activate(ignoringOtherApps: true); w.makeKeyAndOrderFront(nil); return }

        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 380, height: 250),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Move It! Settings"
        w.isReleasedWhenClosed = false
        let v = NSView(frame: w.contentView!.bounds)
        w.contentView = v

        func label(_ s: String, _ y: CGFloat) -> NSTextField {
            let l = NSTextField(labelWithString: s)
            l.frame = NSRect(x: 20, y: y, width: 220, height: 22)
            v.addSubview(l); return l
        }
        func field(_ value: Int, _ y: CGFloat) -> NSTextField {
            let t = NSTextField(frame: NSRect(x: 250, y: y - 2, width: 60, height: 24))
            t.alignment = .right
            t.integerValue = value
            v.addSubview(t); return t
        }

        _ = label("Remind me every (minutes):", 200)
        intervalField = field(cfg.intervalMinutes, 200)
        _ = label("Snooze for (minutes):", 165)
        snoozeField = field(cfg.snoozeMinutes, 165)

        soundCheck = NSButton(checkboxWithTitle: "Play a chime with alerts", target: nil, action: nil)
        soundCheck.frame = NSRect(x: 20, y: 125, width: 300, height: 22)
        soundCheck.state = cfg.sound ? .on : .off
        v.addSubview(soundCheck)

        loginCheck = NSButton(checkboxWithTitle: "Start automatically at login", target: nil, action: nil)
        loginCheck.frame = NSRect(x: 20, y: 95, width: 300, height: 22)
        loginCheck.state = loginEnabled() ? .on : .off
        v.addSubview(loginCheck)

        let save = NSButton(title: "Save", target: self, action: #selector(saveSettings))
        save.bezelStyle = .rounded
        save.keyEquivalent = "\r"
        save.frame = NSRect(x: 210, y: 20, width: 150, height: 40)
        v.addSubview(save)

        let cancel = NSButton(title: "Cancel", target: self, action: #selector(closeSettings))
        cancel.bezelStyle = .rounded
        cancel.frame = NSRect(x: 90, y: 20, width: 110, height: 40)
        v.addSubview(cancel)

        settingsWindow = w
        w.center()
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
    }

    private var intervalField: NSTextField!
    private var snoozeField: NSTextField!
    private var soundCheck: NSButton!
    private var loginCheck: NSButton!

    @objc private func saveSettings() {
        cfg.intervalMinutes = max(1, intervalField.integerValue)
        cfg.snoozeMinutes   = max(1, snoozeField.integerValue)
        cfg.sound           = (soundCheck.state == .on)
        setLoginEnabled(loginCheck.state == .on)
        closeSettings()
        // Restart the cycle with the new interval (unless paused).
        scheduleNext(minutes: cfg.intervalMinutes)
    }

    @objc private func closeSettings() {
        settingsWindow?.orderOut(nil)
        settingsWindow = nil
    }

    // MARK: Start at login (macOS 13+)

    private func loginEnabled() -> Bool {
        if #available(macOS 13.0, *) { return SMAppService.mainApp.status == .enabled }
        return false
    }
    private func setLoginEnabled(_ on: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if on { if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() } }
                else  { if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() } }
            } catch {
                let a = NSAlert()
                a.messageText = "Couldn't change the login setting"
                a.informativeText = "You can add or remove Move It! manually in System Settings ▸ General ▸ Login Items."
                a.runModal()
            }
        }
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) { refreshMenu() }
}

// MARK: - Entry point ------------------------------------------------

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // menu-bar only, no Dock icon
app.run()
