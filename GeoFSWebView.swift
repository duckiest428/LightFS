import SwiftUI
import WebKit

// Custom WKWebView to suppress system chimes for unhandled keystrokes
class LightFSWebView: WKWebView {
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Returning true tells macOS that the event was handled,
        // which suppresses the "invalid action" system chime.
        return super.performKeyEquivalent(with: event) || true
    }
}

struct GeoFSWebView: NSViewRepresentable {
    @Binding var fps: Int
    let url: URL = URL(string: "https://www.geo-fs.com/geofs.php")!

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // 1. GPU & WebGL Acceleration
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        // 2. Custom User-Agent to ensure desktop experience
        config.applicationNameForUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"

        // 3. Aggressive Asset Caching
        config.websiteDataStore = .default()

        // 4. FPS Monitoring Script Injection
        let fpsScript = WKUserScript(
            source: """
            (function() {
                var lastTime = performance.now();
                var frames = 0;
                var fps = 0;

                function updateFPS() {
                    var now = performance.now();
                    frames++;
                    if (now >= lastTime + 1000) {
                        fps = Math.round((frames * 1000) / (now - lastTime));
                        window.webkit.messageHandlers.fps.postMessage(fps);
                        frames = 0;
                        lastTime = now;
                    }
                    requestAnimationFrame(updateFPS);
                }
                requestAnimationFrame(updateFPS);
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(fpsScript)

        // 5. CSS Injection to remove GeoFS UI clutter
        let cssScript = WKUserScript(
            source: """
            (function() {
                var style = document.createElement('style');
                style.innerHTML = `
                    /* Force Full-Screen Canvas */
                    html, body, iframe, .geofs-canvas, #canvas {
                        width: 100vw !important;
                        height: 100vh !important;
                        margin: 0 !important;
                        padding: 0 !important;
                        overflow: hidden !important;
                    }

                    /* Remove Top-Right Clutter (Logins, Help, Account) */
                    .geofs-account, .geofs-social-buttons, .geofs-top-bar-right,
                    [class*="social"], .geofs-help-button, #geofs-help {
                        display: none !important;
                    }

                    /* Remove Right-Side Controls & Fullscreen Arrow */
                    #right-panel, .geofs-right-panel, .geofs-fullscreen-button,
                    #geofs-fullscreen, .sidebar-panel, #sidebar {
                        display: none !important;
                    }

                    /* Remove Ad Banners */
                    .geofs-ad, .geofs-banner, #geofs-ad-container, .ad-container, .banner-ad, iframe[src*="ads"] {
                        display: none !important;
                    }
                `;
                document.head.appendChild(style);
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(cssScript)

        config.userContentController.add(context.coordinator, name: "fps")

        let webView = LightFSWebView(frame: .zero, configuration: config)
        webView.load(URLRequest(url: url))

        // Setup Notification observers
        NotificationCenter.default.addObserver(forName: .reloadGeoFS, object: nil, queue: .main) { _ in
            webView.reload()
        }
        NotificationCenter.default.addObserver(forName: .resetGeoFS, object: nil, queue: .main) { _ in
            webView.load(URLRequest(url: url))
        }
        NotificationCenter.default.addObserver(forName: .clearGeoFSCache, object: nil, queue: .main) { _ in
            webView.clearAllCache()
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No updates needed here
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: GeoFSWebView

        init(_ parent: GeoFSWebView) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "fps", let fpsValue = message.body as? Int {
                DispatchQueue.main.async {
                    self.parent.fps = fpsValue
                }
            }
        }
    }
}

// Extension for HUD actions
extension WKWebView {
    func clearAllCache() {
        let dataTypes = Set([WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let dateFrom = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: dateFrom) {
            print("Cache cleared")
        }
    }
}
