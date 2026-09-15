import SwiftUI
import AppKit

@main
struct LightFSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // A single-window scene: GeoFS is one session, so File > New Window is pointless.
        Window("Light FS", id: "main") {
            ContentView()
                .frame(minWidth: 1024, minHeight: 768)
                .background(WindowConfigurator())
        }
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .toolbar) {
                Button("Reload GeoFS") {
                    NotificationCenter.default.post(name: .reloadGeoFS, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Reset GeoFS") {
                    NotificationCenter.default.post(name: .resetGeoFS, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Button("Clear Cache") {
                    NotificationCenter.default.post(name: .clearGeoFSCache, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DiscordRPC.shared.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        DiscordRPC.shared.stop()
    }
}

// Styles the hosting NSWindow once SwiftUI has actually created it.
// (NSApplication.windows is often still empty in applicationDidFinishLaunching.)
private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.title = "Light FS"
            window.titlebarAppearsTransparent = true
            window.backgroundColor = .black
            window.styleMask.insert(.fullSizeContentView)
            window.collectionBehavior.insert(.fullScreenPrimary)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
