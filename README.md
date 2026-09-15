# ✈️ Light FS

Light FS is a lightweight, native macOS client for **[GeoFS](https://www.geo-fs.com)**. It moves the sim out of a crowded browser tab and into its own clean, edge-to-edge window, and shows your flight on your Discord profile.

Built with **Swift**, **SwiftUI** and **WebKit**. Runs natively on **Apple Silicon and Intel** Macs with **macOS 14 Sonoma or later**.

## ✨ Features

- **Edge-to-edge simulator.** GeoFS's ad column and login/help clutter are removed, so the 3D view fills the whole window.
- **Discord Rich Presence.** Your Discord profile shows what you're flying, live:
  - `Flying Cessna 172` · `12,500 ft · 140 kts`
  - `On the ground · Cessna 172` · `Taxiing at 12 kts` / `Parked`
  - `Paused · Cessna 172`
  - Time spent flying, plus a **Fly GeoFS** button
- **Floating HUD.** A draggable FPS counter that remembers where you put it. Click it for quick **Reload**, **Reset** and **Clear Cache** actions.
- **Native window.** A single full-screen-ready window with a transparent title bar and no browser chrome. Closing it quits the app and clears your Discord status.
- **Menu bar actions.** Reload, Reset and Clear Cache are in the **View** menu, with keyboard shortcuts.

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `⌘ R` | Reload GeoFS |
| `⌘ ⇧ R` | Reset (reload a fresh session) |
| `⌘ ⇧ C` | Clear the web cache and reload |
| `⌃ ⌘ F` | Enter or exit full screen |

## 📦 Installation

**Requirements:** macOS 14 Sonoma or later · Apple Silicon or Intel

1. Download the latest `LightFS-1.02.dmg`.
2. Open the DMG and drag **LightFS** onto the **Applications** folder.
3. Eject the **Light FS** disk image.
4. Launch **Light FS** from Applications and start flying!

> **"Light FS can't be opened"?** Light FS isn't notarized by Apple yet, so macOS may block it the first time. Right-click **LightFS** in Applications, choose **Open**, then click **Open** again. On macOS 15 or later, go to **System Settings → Privacy & Security** and click **Open Anyway**. You only need to do this once.

## 💬 Discord Rich Presence

Rich Presence works automatically. Just keep the Discord desktop app open while you fly.

- Your status appears a few seconds after GeoFS finishes loading and updates about every 15 seconds.
- If Discord is closed, Light FS keeps trying to reconnect in the background.
- Quitting Light FS clears your status.
- If nothing shows up, check that **Settings → Activity Privacy → Share your detected activities with others** is turned on in Discord.

> **Building from source?** Light FS runs **outside the App Sandbox**, because the sandbox blocks the local connection to Discord. To use your own Discord application, set `DiscordRPC.clientID` in `DiscordRPC.swift` and upload a Rich Presence art asset named `logo`.

## 🛠 Technical Stack

- **Language**: Swift (SwiftUI + AppKit)
- **Engine**: WebKit (`WKWebView`)
- **Discord**: Built-in, dependency-free client for Discord's local IPC protocol
- **Target**: macOS 14.0+, Universal binary (arm64 + x86_64)
- **Bundle ID**: `com.duckiest.LightFS`

## 📁 Project Structure

| File | Purpose |
| :--- | :--- |
| `LightFSApp.swift` | App entry point, window styling and menu commands |
| `ContentView.swift` | Main view and the floating HUD |
| `GeoFSWebView.swift` | WebKit view, layout clean-up and flight-data scripts |
| `DiscordRPC.swift` | Discord Rich Presence client |

---

*Disclaimer: Light FS is a community-made client for GeoFS and is not affiliated with GeoFS or Discord. All flight simulation assets and services are provided by GeoFS.*
