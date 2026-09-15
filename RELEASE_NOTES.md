# Light FS 1.02

This update brings a truly edge-to-edge simulator, Discord Rich Presence, and support for many more Macs.

**Download:** `LightFS-1.02.dmg` · **Requires:** macOS 14 Sonoma or later · Apple Silicon or Intel

---

## ✨ New

### Discord Rich Presence
Your Discord profile now shows your flight, live:

- **In the air:** `Flying Cessna 172` · `12,500 ft · 140 kts`
- **On the ground:** `Taxiing at 12 kts` or `Parked`
- **Paused:** `Paused · Cessna 172`
- Elapsed flight time and a **Fly GeoFS** button

It works automatically while the Discord desktop app is open, reconnects if Discord restarts, and clears your status when you quit. No setup needed.

### Menu Bar Actions
**Reload**, **Reset** and **Clear Cache** are now in the **View** menu, with their shortcuts listed next to them.

## 🎨 Improved

- **Full-width simulator.** The white column on the right side of the window is gone, and the 3D view now fills the entire window.
- **Runs on more Macs.** Light FS now supports **macOS 14 Sonoma and later**, on both **Apple Silicon and Intel**.
- **Single-window app.** Light FS now uses one dedicated window. Closing it quits the app.
- **Clear Cache** now reloads GeoFS automatically afterwards.
- **HUD buttons** now highlight when you hover over them.
- **Proper app identity.** Light FS now has its own bundle ID and app category, and shows as "Light FS" throughout macOS.
- **DMG installer.** Drag Light FS onto Applications to install.

## 🐞 Fixed

- **⌘Q, ⌘W and ⌘M didn't work.** The simulator was swallowing every ⌘ shortcut. They now work, and flight keys still don't trigger the system alert sound.
- **Window styling sometimes didn't apply** at launch, leaving a standard title bar.
- **⌘N opened a second GeoFS window**, running two simulators at once.
- **Memory leak.** The simulator view was never released from memory.
- **Browser identity string was malformed**, which could affect which version of GeoFS was served.
- **Web Inspector was enabled in release builds.** It's now available in development builds only.

---

## ⚠️ Notes

- **First launch:** Light FS isn't notarized by Apple yet, so macOS may block it the first time you open it.
  - On **macOS 14**, right-click **LightFS** in Applications, choose **Open**, then click **Open** again.
  - On **macOS 15 or later**, click **Open Anyway** in **System Settings → Privacy & Security**.
- **Fresh start:** because Light FS has a new bundle ID, your saved GeoFS login and HUD position reset once after updating.
- **Rich Presence not showing?** In Discord, turn on **Settings → Activity Privacy → Share your detected activities with others**.
