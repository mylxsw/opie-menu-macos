import AppKit
import IOKit.pwr_mgt
import CoreAudio
import OpieMenu

@MainActor
enum DemoAction: String, CaseIterable {
    case darkMode, nightShift, keepAwake, mute, missionControl, emoji, screenshot

    var menuItem: OpieMenuItem {
        let dark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let awake = UserDefaults.standard.bool(forKey: "keepAwake")
        let muted = UserDefaults.standard.bool(forKey: "muted")
        let title: String
        let icon: OpieMenuIcon
        switch self {
        case .darkMode:
            title = dark ? "Turn off\nDark Mode" : "Turn on\nDark Mode"
            icon = .systemSymbol("circle.lefthalf.filled")
        case .nightShift:
            title = "Turn on\nNight Shift"
            icon = .systemSymbol("moon.circle")
        case .keepAwake:
            title = awake ? "Turn off\nKeep Awake" : "Turn on\nKeep Awake"
            icon = .systemSymbol("bolt")
        case .mute:
            title = muted ? "Turn off Mute" : "Turn on Mute"
            icon = .systemSymbol("speaker.slash")
        case .missionControl:
            title = "Mission\nControl"
            icon = .systemSymbol("rectangle.3.group")
        case .emoji:
            title = "Emoji &\nSymbols"
            icon = .smile
        case .screenshot:
            title = "Screenshot &\nRecording T…"
            icon = .systemSymbol("camera.viewfinder")
        }
        return OpieMenuItem(id: rawValue, title: title, icon: icon)
    }
}

@MainActor
final class ActionController {
    private var awakeAssertion: IOPMAssertionID = 0

    func perform(_ item: DemoAction, restore app: NSRunningApplication?) {
        app?.activate(options: [])
        switch item {
        case .darkMode:
            var error: NSDictionary?
            NSAppleScript(source: "tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode")?
                .executeAndReturnError(&error)
            if error != nil { openSettings("com.apple.Appearance-Settings.extension") }
        case .nightShift:
            // Night Shift has no public toggle API. Open its native settings panel.
            openSettings("com.apple.Displays-Settings.extension")
        case .keepAwake:
            if awakeAssertion != 0 {
                IOPMAssertionRelease(awakeAssertion)
                awakeAssertion = 0
            } else {
                let reason = "Opie Native Keep Awake" as CFString
                IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), reason, &awakeAssertion)
            }
            UserDefaults.standard.set(awakeAssertion != 0, forKey: "keepAwake")
        case .mute:
            toggleMute()
        case .missionControl:
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Mission Control.app"))
        case .screenshot:
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Screenshot.app"))
        case .emoji: break
        }
    }

    private func openSettings(_ pane: String) {
        if let url = URL(string: "x-apple.systempreferences:\(pane)") { NSWorkspace.shared.open(url) }
    }

    private func toggleMute() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device) == noErr else { return }
        address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var muted = UInt32(0)
        size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &muted) == noErr else { return }
        muted = muted == 0 ? 1 : 0
        guard AudioObjectSetPropertyData(device, &address, 0, nil, size, &muted) == noErr else { return }
        UserDefaults.standard.set(muted != 0, forKey: "muted")
    }

    func insert(_ text: String, into app: NSRunningApplication?) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        app?.activate(options: [])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true),
                  let up = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false) else { return }
            down.flags = .maskCommand
            up.flags = .maskCommand
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }
    }
}
