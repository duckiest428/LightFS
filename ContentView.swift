import SwiftUI
import WebKit

struct ContentView: View {
    @State private var fps: Int = 0
    @State private var showActions = false

    // Persisted position for the HUD
    @AppStorage("hud_offset_x") private var hudOffsetX: Double = 0
    @AppStorage("hud_offset_y") private var hudOffsetY: Double = 0
    @State private var currentOffset: CGSize = .zero

    var body: some View {
        ZStack {
            // The Simulation
            GeoFSWebView(fps: $fps)
                .edgesIgnoringSafeArea(.all)
                .background(Color.black)

            // Floating HUD
            VStack(spacing: 0) {
                HStack {
                    // FPS Pill
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showActions.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("\(fps)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(fps > 30 ? .green : (fps > 20 ? .yellow : .red))
                            Text("FPS")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .zIndex(2)
                }
                .padding(.top, 12)

                // Action Popover
                if showActions {
                    HStack(spacing: 12) {
                        HUDActionButton(icon: "arrow.clockwise", label: "Reload", action: reloadPage)
                        HUDActionButton(icon: "airplane", label: "Reset", action: resetSpawn)
                        HUDActionButton(icon: "trash", label: "Clear Cache", action: clearCache)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
                    .zIndex(1)
                }
            }
            .frame(maxWidth: .infinity)
            .offset(x: CGFloat(hudOffsetX) + currentOffset.width, y: CGFloat(hudOffsetY) + currentOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        currentOffset = value.translation
                    }
                    .onEnded { value in
                        hudOffsetX += Double(value.translation.width)
                        hudOffsetY += Double(value.translation.height)
                        currentOffset = .zero
                    }
            )
        }
    }

    private func reloadPage() {
        NotificationCenter.default.post(name: .reloadGeoFS, object: nil)
    }

    private func resetSpawn() {
        NotificationCenter.default.post(name: .resetGeoFS, object: nil)
    }

    private func clearCache() {
        NotificationCenter.default.post(name: .clearGeoFSCache, object: nil)
    }
}

struct HUDActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .hoverEffect()
    }
}

extension View {
    func hoverEffect() -> some View {
        self.onHover { hovering in
            // Visual feedback
        }
    }
}

// Notification names for HUD communication
extension Notification.Name {
    static let reloadGeoFS = Notification.Name("reloadGeoFS")
    static let resetGeoFS = Notification.Name("resetGeoFS")
    static let clearGeoFSCache = Notification.Name("clearGeoFSCache")
}
