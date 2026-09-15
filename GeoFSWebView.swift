import SwiftUI
import WebKit

// Custom WKWebView to suppress system chimes for unhandled keystrokes
class LightFSWebView: WKWebView {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if super.performKeyEquivalent(with: event) { return true }
        // Let ⌘ shortcuts fall through to the menu bar (⌘Q, ⌘W, ⌘R, ...).
        if event.modifierFlags.contains(.command) { return false }
        // Swallow everything else so flight keys don't trigger the system chime.
        return true
    }
}

struct GeoFSWebView: NSViewRepresentable {
    @Binding var fps: Int
    let url: URL = URL(string: "https://www.geo-fs.com/geofs.php")!

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // 1. Web Inspector (right-click > Inspect Element) in debug builds
        #if DEBUG
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif

        // 2. Media & fullscreen behaviour for the simulator
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.isElementFullscreenEnabled = true

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
        // Injected at document start so the ad column never takes up layout space.
        let cssScript = WKUserScript(
            source: """
            (function() {
                var style = document.createElement('style');
                style.innerHTML = `
                    /* Remove the right-hand ad column (white 160-300px flex item) */
                    .geofs-adbanner, .geofs-adsense-container, .geofs-adsBlockedMessage {
                        display: none !important;
                        width: 0 !important;
                        min-width: 0 !important;
                    }

                    /* Force Full-Screen Canvas */
                    html, body, .geofs-canvas, #canvas {
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
                (document.head || document.documentElement).appendChild(style);

                // Cesium only resizes its canvas on window resize, so nudge it
                // once the ad column is gone.
                function nudge() { window.dispatchEvent(new Event('resize')); }
                document.addEventListener('DOMContentLoaded', nudge);
                window.addEventListener('load', function() {
                    nudge();
                    setTimeout(nudge, 1000);
                    setTimeout(nudge, 5000);
                });
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(cssScript)

        // 6. Discord Rich Presence: poll flight state and hand it to Swift
        let presenceScript = WKUserScript(
            source: """
            (function() {
                function sample() {
                    try {
                        var g = window.geofs;
                        if (!g || !g.aircraft || !g.aircraft.instance) return;
                        var inst = g.aircraft.instance;
                        var values = (g.animation && g.animation.values) || {};
                        var record = inst.aircraftRecord || {};
                        window.webkit.messageHandlers.presence.postMessage({
                            aircraft: String(record.name || ''),
                            altitude: Math.round(Number(values.altitude) || 0),
                            kias: Math.round(Number(values.kias) || 0),
                            onGround: !!inst.groundContact,
                            paused: typeof g.isPaused === 'function' ? !!g.isPaused() : false
                        });
                    } catch (e) {}
                }
                setInterval(sample, 5000);
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(presenceScript)

        config.userContentController.add(context.coordinator, name: "fps")
        config.userContentController.add(context.coordinator, name: "presence")

        let webView = LightFSWebView(frame: .zero, configuration: config)
        // Desktop user agent so GeoFS serves the full desktop experience
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"
        webView.load(URLRequest(url: url))

        // Setup Notification observers (removed again in dismantleNSView)
        let center = NotificationCenter.default
        let url = self.url
        context.coordinator.observers = [
            center.addObserver(forName: .reloadGeoFS, object: nil, queue: .main) { [weak webView] _ in
                webView?.reload()
            },
            center.addObserver(forName: .resetGeoFS, object: nil, queue: .main) { [weak webView] _ in
                webView?.load(URLRequest(url: url))
            },
            center.addObserver(forName: .clearGeoFSCache, object: nil, queue: .main) { [weak webView] _ in
                webView?.clearAllCache()
            },
        ]

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No updates needed here
    }

    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        coordinator.observers.forEach(NotificationCenter.default.removeObserver)
        coordinator.observers = []
        // The content controller retains its handlers; break the cycle.
        nsView.configuration.userContentController.removeAllScriptMessageHandlers()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: GeoFSWebView
        var observers: [NSObjectProtocol] = []

        init(_ parent: GeoFSWebView) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "fps", let fpsValue = (message.body as? NSNumber)?.intValue {
                DispatchQueue.main.async {
                    self.parent.fps = fpsValue
                }
            } else if message.name == "presence", let body = message.body as? [String: Any] {
                DiscordRPC.shared.update(FlightPresence(
                    aircraft: body["aircraft"] as? String ?? "",
                    altitude: (body["altitude"] as? NSNumber)?.intValue ?? 0,
                    kias: (body["kias"] as? NSNumber)?.intValue ?? 0,
                    onGround: body["onGround"] as? Bool ?? false,
                    paused: body["paused"] as? Bool ?? false
                ))
            }
        }
    }
}

// Extension for HUD actions
extension WKWebView {
    func clearAllCache() {
        let dataTypes = Set([WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let dateFrom = Date(timeIntervalSince1970: 0)
        configuration.websiteDataStore.removeData(ofTypes: dataTypes, modifiedSince: dateFrom) { [weak self] in
            self?.reload()
        }
    }
}
