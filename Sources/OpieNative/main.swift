import AppKit
import Carbon
import QuartzCore
import SwiftUI
import OpieMenu

@MainActor
@main
struct OpieNativeApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(CommandLine.arguments.contains("--preview-window") ? .regular : .accessory)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var styleItems: [OpieMenuStyle: NSMenuItem] = [:]
    private var menu: OpieRadialMenu!
    private var emojiWindow: NSPanel?
    private var previousApp: NSRunningApplication?
    private var hotkeyReady = false
    private let actions = ActionController()
    private static let preferenceKey = "menuStyle"

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.set(false, forKey: "keepAwake")
        menu = OpieRadialMenu(items: DemoAction.allCases.map(\.menuItem),
                              centerTitle: "Starter", style: Self.savedStyle()) { [weak self] item in
            self?.perform(item)
        }
        menu.onWillShow = { [weak self] in
            guard let self else { return }
            self.previousApp = NSWorkspace.shared.frontmostApplication
            let refreshed = DemoAction.allCases.map(\.menuItem)
            if refreshed.count != self.menu.items.count ||
                zip(refreshed, self.menu.items).contains(where: { $0.id != $1.id || $0.title != $1.title }) {
                self.menu.updateItems(refreshed)
            }
        }
        menu.prepare()
        if !CommandLine.arguments.contains("--preview-window") {
            hotkeyReady = menu.installGlobalHotKey(keyCode: 49, modifiers: UInt32(controlKey | optionKey))
        }
        configureStatusMenu()

        if CommandLine.arguments.contains("--smoke-test") {
            Task { @MainActor [weak self] in
                guard let self else { exit(1) }
                self.menu.show()
                let visible = self.menu.isVisible
                let originalStyle = self.menu.style
                var stylesWork = true
                for style in OpieMenuStyle.allCases where style.isAvailable {
                    self.menu.setStyle(style)
                    stylesWork = stylesWork && self.menu.style == style
                }
                self.menu.setStyle(originalStyle)
                self.menu.dismiss()
                try? await Task.sleep(for: .milliseconds(550))
                let closed = !self.menu.isVisible
                var selectedID: String?
                self.menu.onSelect = { selectedID = $0.id }
                self.menu.show()
                self.menu.select(index: 6)
                self.menu.activateSelection()
                try? await Task.sleep(for: .milliseconds(550))
                let callbackWorks = selectedID == DemoAction.screenshot.rawValue && !self.menu.isVisible
                print("package menu visible=\(visible), styles=\(stylesWork), closed=\(closed), selection callback=\(callbackWorks), hotkey=\(self.hotkeyReady)")
                exit(visible && stylesWork && closed && callbackWorks && self.hotkeyReady ? 0 : 1)
            }
        } else if CommandLine.arguments.contains("--preview-window") {
            DispatchQueue.main.async { [weak self] in self?.menu.show() }
        }
    }

    private static func savedStyle() -> OpieMenuStyle {
        switch UserDefaults.standard.string(forKey: preferenceKey) {
        case "liquidGlass", "frosted": return .frosted // The old glass style used this value.
        case "systemLiquidGlass": return .liquidGlass
        default: return .classic
        }
    }

    private func configureStatusMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "circle.hexagongrid", accessibilityDescription: "Opie Native")
            button.toolTip = "Opie Native · ⌃⌥Space"
        }
        let statusMenu = NSMenu()
        let openItem = NSMenuItem(title: "在鼠标位置打开  ⌃⌥Space", action: #selector(toggleMenu), keyEquivalent: "")
        openItem.target = self
        statusMenu.addItem(openItem)
        let styleMenu = NSMenu()
        for style in OpieMenuStyle.allCases {
            let item = NSMenuItem(title: styleTitle(style), action: #selector(changeStyle(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style.rawValue
            item.state = style == menu.style ? .on : .off
            item.isEnabled = style.isAvailable
            styleMenu.addItem(item)
            styleItems[style] = item
        }
        let styleItem = NSMenuItem(title: "外观风格", action: nil, keyEquivalent: "")
        styleItem.submenu = styleMenu
        statusMenu.addItem(styleItem)
        statusMenu.addItem(.separator())
        let quitItem = NSMenuItem(title: "退出 Opie Native", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        statusMenu.addItem(quitItem)
        statusItem.menu = statusMenu
    }

    private func styleTitle(_ style: OpieMenuStyle) -> String {
        switch style {
        case .classic: "经典模式"
        case .frosted: "毛玻璃效果"
        case .liquidGlass: "Liquid Glass"
        }
    }

    @objc private func toggleMenu() {
        dismissEmoji()
        menu.toggle()
    }

    @objc private func changeStyle(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let style = OpieMenuStyle(rawValue: raw) else { return }
        menu.setStyle(style)
        let stored = style == .frosted ? "liquidGlass" :
            (style == .liquidGlass ? "systemLiquidGlass" : "classic")
        UserDefaults.standard.set(stored, forKey: Self.preferenceKey)
        for (option, item) in styleItems { item.state = option == menu.style ? .on : .off }
    }

    @objc private func quit() { NSApp.terminate(nil) }

    private func perform(_ item: OpieMenuItem) {
        guard let action = DemoAction(rawValue: item.id) else { return }
        let origin = menu.lastPresentationCenter ?? NSEvent.mouseLocation
        if action == .emoji { showEmojiPicker(at: origin) }
        else { actions.perform(action, restore: previousApp) }
    }

    private func showEmojiPicker(at point: NSPoint) {
        let size = NSSize(width: 268, height: 400)
        let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) ?? NSScreen.main
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(
            x: min(max(point.x - size.width / 2, visible.minX + 4), visible.maxX - size.width - 4),
            y: min(max(point.y - size.height / 2, visible.minY + 4), visible.maxY - size.height - 4)
        )
        let panel = EmojiPanel(contentRect: NSRect(origin: origin, size: size),
                               styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        let picker = EmojiPickerView(onPick: { [weak self] emoji in
            guard let self else { return }
            self.dismissEmoji()
            self.actions.insert(emoji, into: self.previousApp)
        }, onClose: { [weak self] in self?.dismissEmoji() })
        panel.contentView = NSHostingView(rootView: picker)
        let smallSize = NSSize(width: size.width * 0.91, height: size.height * 0.91)
        panel.setFrame(NSRect(x: origin.x + (size.width - smallSize.width) / 2,
                              y: origin.y + (size.height - smallSize.height) / 2,
                              width: smallSize.width, height: smallSize.height), display: false)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()
        emojiWindow = panel
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.18, 0.82, 0.25, 1)
            panel.animator().alphaValue = 1
            panel.animator().setFrame(NSRect(origin: origin, size: size), display: true)
        }
    }

    private func dismissEmoji() {
        emojiWindow?.orderOut(nil)
        emojiWindow = nil
    }
}

private final class EmojiPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}
