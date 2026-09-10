# Light FS Setup Guide

## Xcode Configuration

To ensure Light FS runs with high performance and full connectivity, apply the following settings in your Xcode project:

### 1. App Sandbox (Capabilities)
Navigate to **Project Target** $\rightarrow$ **Signing & Capabilities** $\rightarrow$ **App Sandbox**.
Enable the following:
- [x] **Outgoing Connections (Client)**: This is critical. Without this, the `WKWebView` will be blocked from loading `geo-fs.com`.

### 2. Info.plist Keys
Add the following keys to your `Info.plist` if you intend to use advanced features:

| Key | Value | Description |
| :--- | :--- | :--- |
| `NSAppTransportSecurity` | `Allow Arbitrary Loads` $\rightarrow$ `YES` | Only if you encounter issues with non-HTTPS assets. |
| `NSLocalNetworkUsageDescription` | "Light FS needs local network access for peripheral flight-stick connectivity." | Required if using certain local joystick drivers/proxies. |

### 3. Build Settings
- **Optimization Level**: Ensure `Swift Optimization Level` is set to `[-O]` (Optimize for Speed) in the **Release** configuration to ensure the HUD and WebView bridging is performant.

## Input Handling Notes
- **Gamepad API**: The Gamepad API is supported natively by `WKWebView`. Ensure your flight-stick is connected *before* launching the app or refresh the page (`Cmd+R`) after connecting.
- **Keyboard Focus**: The app uses a frameless window design. If you find the window is not capturing input, click once inside the simulation area to set `WKWebView` as the first responder.
