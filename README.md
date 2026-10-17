# OpieMenu

**English** | [简体中文](README.zh-CN.md)

A native macOS radial menu that opens at the pointer, built with Swift and AppKit. The repository includes a reusable Swift Package and `OpieNative`, a menu bar demo app. Its look and interaction were inspired by [Opie](https://opies.io/). This is an independent, unofficial project and is not affiliated with Opie.

## Preview

![OpieMenu radial menu in action](docs/assets/show.gif)

## Add it to your app

Requires macOS 14 or later and Swift 6. In Xcode, choose **File → Add Package Dependencies…**, enter `https://github.com/mylxsw/opie-menu-macos.git`, and add the `OpieMenu` product to your app target.

For a Swift Package manifest:

```swift
dependencies: [.package(url: "https://github.com/mylxsw/opie-menu-macos.git", branch: "main")],
targets: [
    .executableTarget(
        name: "YourApp",
        dependencies: [.product(name: "OpieMenu", package: "opie-menu-macos")]
    )
]
```

You can also copy `Packages/OpieMenu` into your project as a standalone local package. See the [package guide](Packages/OpieMenu/README.md) for a minimal example, keyboard shortcuts, callbacks, and the public API.

## Run the demo

```sh
./build-app.sh
open build/OpieNative.app
```

The demo runs in the menu bar. Press **Control + Option + Space** to open the menu at the pointer. Press the shortcut again or Escape to close it. Hold the shortcut, move toward a slice, and release to activate it; a quick tap only opens the menu. You can also drag and release with the mouse or click a slice directly. Arrow keys move the selection; Return or number keys 1–7 activate a slice.

Use the menu bar icon to switch between **Classic**, **Frosted**, and **Liquid Glass**. The selection is saved for the next launch.

## Features

- A pointer-following outer ring that stretches into a narrow peak, stays responsive beyond the menu window, and ripples back with a fast jelly recoil when released.
- Animated opening and closing, warm selection highlights, a soft violet glow, labels, and placement that avoids screen edges across multiple displays.
- Three appearances: a solid dark ring, a frosted ring backed by `NSGlassEffectView` on macOS 26 or `NSVisualEffectView` on earlier versions, and a Liquid Glass ring using SwiftUI `glassEffect(_:in:)` on macOS 26. Liquid Glass falls back to Frosted on older systems.
- A searchable emoji panel in the demo app, with categories, copy, and an attempt to paste into the previous app.
- Demo actions for Dark Mode, Keep Awake, Mute, Mission Control, and Screenshot. Night Shift opens Display settings because macOS does not expose a public toggle API. Automatic emoji pasting needs Accessibility permission; copying still works without it.

The package handles presentation and interaction; the host app supplies the menu items and their actions. It has no third-party dependencies.

## Verify

```sh
swift test
./build-app.sh
build/OpieNative.app/Contents/MacOS/OpieNative --smoke-test
```

Tests cover item counts, slice selection, the glass cutout, and release recoil. The demo smoke test checks opening, closing, styles, selection callbacks, and hotkey registration.

## License

The code is available under the [MIT License](LICENSE). macOS system symbols are provided by the operating system and are not covered by this license.
