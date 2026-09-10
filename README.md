# ✈️ Light FS

Light FS is a high-performance, minimalist native macOS desktop wrapper for **GeoFS**. It elevates the flight simulation experience out of the crowded browser tab environment and into a dedicated, sleek desktop client.

Built with **Swift** and **SwiftUI**, Light FS optimizes the web-based simulation for Apple Silicon and Intel Macs, providing a "Pro Client" experience with zero browser clutter.

## ✨ Features

### 🚀 Performance & Optimization
- **Metal/WebGL Acceleration**: Configured to leverage full hardware acceleration for smooth flight.
- **Asset Caching**: Aggressive local caching to reduce initial load times and stutter.
- **Process Isolation**: High-priority WebKit process to avoid reload throttling.

### 🖥️ Minimalist Design
- **Frameless Experience**: A true native app feel with a hidden title bar and transparent window background.
- **Canvas-Fill Layout**: Custom CSS injection ensures the GeoFS simulation fills $100\%$ of the window with no margins or white gaps.
- **Clutter-Free**: Automatically strips away browser UI, social login buttons, and ad banners for total immersion.

### 🛠️ Pro Client Tools
- **Floating HUD**: A draggable, semi-transparent utility pill showing real-time FPS.
- **Quick Actions**: One-click access to Reload, Reset Spawn, and Clear Cache.
- **Persistence**: The HUD remembers its position across app launches using `@AppStorage`.

### ⌨️ Professional Input Handling
- **Silent Controls**: Custom event handling to suppress the macOS "invalid action" system chime during flight.
- **Global Hotkeys**:
  - `Cmd + R`: Soft Reload
  - `Cmd + Shift + R`: Hard Reload / Reset Position
  - `Cmd + Shift + C`: Clear Cache

## 📦 Installation

1. Download the latest `LightFS_Install.iso`.
2. Mount the ISO image.
3. Run the `Install.app` helper or simply drag `LightFS.app` into your `/Applications` folder.
4. Launch **Light FS** and start flying!

## 🛠 Technical Stack
- **Language**: Swift 6.0
- **UI Framework**: SwiftUI
- **Engine**: WebKit (`WKWebView`)
- **OS**: macOS 14+

---
*Disclaimer: Light FS is a community-driven wrapper for GeoFS. All flight simulation assets and services are provided by GeoFS.*
