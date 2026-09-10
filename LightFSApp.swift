import SwiftUI

@main
struct LightFSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1024, minHeight: 768)
        }
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Access the main window to further customize the frameless experience
        if let window = NSApplication.shared.windows.first {
            window.title = "Light FS"
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.backgroundColor = .black

            // Remove the standard title bar completely for maximum immersion
            window.styleMask.insert(.fullSizeContentView)

            // Handle Fullscreen Cmd+F
            setupGlobalShortcuts()
        }
    }

    private func setupGlobalShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags
            let isCmd = flags.contains(.command)
            let isShift = flags.contains(.shift)

            if isCmd {
                switch event.charactersIgnoringModifiers {
                case "r", "R":
                    if isShift {
                        // Cmd + Shift + R: Reset
                        NotificationCenter.default.post(name: .resetGeoFS, object: nil)
                        return nil // Swallow event
                    } else {
                        // Cmd + R: Reload
                        NotificationCenter.default.post(name: .reloadGeoFS, object: nil)
                        return nil // Swallow event
                    }
                case "c", "C":
                    if isShift {
                        // Cmd + Shift + C: Clear Cache
                        NotificationCenter.default.post(name: .clearGeoFSCache, object: nil)
                        return nil // Swallow event
                    }
                default:
                    break
                }
            }
            return event
        }
    }
}
