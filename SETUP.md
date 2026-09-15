# Light FS Setup Guide

How to build, run and package Light FS from source.

## Requirements

- **Xcode 26 or later.** The project uses default MainActor isolation and `nonisolated` types, which need a recent Swift compiler.
- **Deployment target:** macOS 14.0
- **Architectures:** Universal (arm64 + x86_64)

## Xcode Configuration

The project is already configured. If you recreate it or change settings, keep the following.

### 1. App Sandbox: **Off**
**Target → Signing & Capabilities:** App Sandbox must stay **disabled**.

Discord Rich Presence talks to the Discord desktop app over a local socket (`$TMPDIR/discord-ipc-0`). A sandboxed app can't reach that socket, so turning the sandbox on silently breaks Rich Presence. The web view can reach `geo-fs.com` without any extra entitlement while the sandbox is off.

> This means Light FS can't ship on the Mac App Store as-is. Distribute it as a DMG instead.

### 2. Hardened Runtime: **On**
Required for notarization. No runtime exceptions (JIT, unsigned memory, and so on) are needed, because WebKit runs its JavaScript engine in its own separate processes.

### 3. Key Build Settings

| Setting | Value |
| :--- | :--- |
| `MACOSX_DEPLOYMENT_TARGET` | `14.0` |
| `SUPPORTED_PLATFORMS` | `macosx` |
| `PRODUCT_BUNDLE_IDENTIFIER` | `com.duckiest.LightFS` |
| `ENABLE_APP_SANDBOX` | `NO` |
| `ENABLE_HARDENED_RUNTIME` | `YES` |
| `SWIFT_OPTIMIZATION_LEVEL` (Release) | `-O` |

No custom `Info.plist` is needed. The generated one already includes the display name, the app category and `LSMinimumSystemVersion`.

### 4. Discord Application
Rich Presence uses the Discord application ID set in `DiscordRPC.clientID` (`DiscordRPC.swift`). To use your own:

1. Create an application at https://discord.com/developers/applications. Its name is what Discord shows after "Playing".
2. Paste its **Application ID** into `DiscordRPC.clientID`.
3. Under **Rich Presence → Art Assets**, upload the app icon with the key **`logo`**.

## Building a Release

1. **Product → Archive**, then **Distribute App → Custom → Copy App** (or **Direct Distribution** to notarize).
2. Package it into a DMG with an `/Applications` shortcut.

If the export sits in an iCloud-synced folder (such as Desktop or Documents), strip extended attributes before packaging, or the code signature fails strict verification:

```bash
xattr -cr LightFS.app
```

### Signing & Notarization
- **Apple Development** signing only works cleanly on your own Mac. Other Macs will block the app until the user allows it in **System Settings → Privacy & Security**.
- For public distribution, sign with a **Developer ID Application** certificate, notarize with `xcrun notarytool`, and staple the ticket to the DMG with `xcrun stapler staple`.

## Input Handling Notes
- **Gamepad API:** WebKit supports the Gamepad API natively. Connect your flight stick *before* launching, or reload (`⌘R`) after connecting it.
- **Keyboard focus:** if keys don't reach the sim, click once inside the simulator view.
- **Shortcuts:** `⌘` shortcuts go to the menu bar (`⌘R`, `⌘⇧R`, `⌘⇧C`, `⌘Q`). All other keys go to GeoFS, without the system alert sound.
