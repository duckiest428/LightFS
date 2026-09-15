import Foundation
import Darwin

// Snapshot of the current flight, sampled from GeoFS by GeoFSWebView.
struct FlightPresence: Equatable, Sendable {
    var aircraft: String
    var altitude: Int
    var kias: Int
    var onGround: Bool
    var paused: Bool
}

// Minimal Discord Rich Presence client speaking Discord's local IPC protocol
// over the discord-ipc-N unix socket. No external dependencies.
nonisolated final class DiscordRPC: @unchecked Sendable {
    static let shared = DiscordRPC()

    // Create an application at https://discord.com/developers/applications,
    // name it "LightFS" (that's what Discord shows as "Playing ..."), and paste
    // its Application ID here. Upload a Rich Presence art asset named "logo".
    static let clientID = "1549222943865970688"

    // Discord allows 5 activity updates per 20 seconds; stay well under.
    private let minUpdateInterval: TimeInterval = 15

    private let queue = DispatchQueue(label: "LightFS.DiscordRPC")
    private let readerQueue = DispatchQueue(label: "LightFS.DiscordRPC.reader")
    private var fd: Int32 = -1
    private var timer: DispatchSourceTimer?
    private var pending: FlightPresence?
    private var lastSent: FlightPresence?
    private var lastSendDate = Date.distantPast
    private let startedAt = Int(Date().timeIntervalSince1970)

    private enum Opcode: UInt32 {
        case handshake = 0, frame = 1, close = 2, ping = 3, pong = 4
    }

    private init() {}

    func start() {
        guard !Self.clientID.hasPrefix("YOUR_") else {
            print("[DiscordRPC] Set DiscordRPC.clientID to enable Rich Presence")
            return
        }
        queue.async {
            guard self.timer == nil else { return }
            let timer = DispatchSource.makeTimerSource(queue: self.queue)
            timer.schedule(deadline: .now(), repeating: self.minUpdateInterval)
            timer.setEventHandler { self.tick() }
            timer.resume()
            self.timer = timer
        }
    }

    func stop() {
        queue.sync {
            timer?.cancel()
            timer = nil
            disconnect()
        }
    }

    func update(_ presence: FlightPresence) {
        queue.async {
            self.pending = presence
            if Date().timeIntervalSince(self.lastSendDate) >= self.minUpdateInterval {
                self.tick()
            }
        }
    }

    // MARK: - Connection lifecycle (always on `queue`)

    private func tick() {
        if fd < 0 {
            connect()
            if fd < 0 { return }
        }
        flush()
    }

    private func connect() {
        guard let socket = openSocket() else { return }
        fd = socket

        // Handshake must be answered with a READY dispatch.
        setReceiveTimeout(seconds: 5)
        guard send(.handshake, ["v": 1, "client_id": Self.clientID]),
              let (op, body) = readFrame(fd: socket),
              op == Opcode.frame.rawValue,
              (body["evt"] as? String) == "READY"
        else {
            print("[DiscordRPC] Handshake failed")
            disconnect()
            return
        }
        setReceiveTimeout(seconds: 0)
        lastSent = nil
        print("[DiscordRPC] Connected")

        // Drain responses so Discord's writes never block, and answer pings.
        readerQueue.async { [weak self] in
            while let (op, body) = readFrame(fd: socket) {
                guard let self else { return }
                switch Opcode(rawValue: op) {
                case .ping:
                    self.queue.async { if self.fd == socket { _ = self.send(.pong, body) } }
                case .close:
                    self.queue.async { if self.fd == socket { self.disconnect() } }
                    return
                default:
                    if (body["evt"] as? String) == "ERROR" {
                        print("[DiscordRPC] Error: \(body["data"] ?? "")")
                    }
                }
            }
            self?.queue.async { if self?.fd == socket { self?.disconnect() } }
        }
    }

    private func disconnect() {
        guard fd >= 0 else { return }
        // Closing the socket makes Discord clear the activity.
        shutdown(fd, SHUT_RDWR)
        close(fd)
        fd = -1
    }

    private func flush() {
        guard let presence = pending, presence != lastSent else { return }
        let payload: [String: Any] = [
            "cmd": "SET_ACTIVITY",
            "nonce": UUID().uuidString,
            "args": [
                "pid": Int(ProcessInfo.processInfo.processIdentifier),
                "activity": activity(for: presence),
            ],
        ]
        if send(.frame, payload) {
            lastSent = presence
            lastSendDate = Date()
        } else {
            disconnect()
        }
    }

    private func activity(for p: FlightPresence) -> [String: Any] {
        let aircraft = p.aircraft.isEmpty ? "an aircraft" : p.aircraft
        let details: String
        let state: String
        if p.paused {
            details = "Paused · \(aircraft)"
            state = "\(p.altitude.formatted()) ft"
        } else if p.onGround {
            details = "On the ground · \(aircraft)"
            state = p.kias > 5 ? "Taxiing at \(p.kias) kts" : "Parked"
        } else {
            details = "Flying \(aircraft)"
            state = "\(p.altitude.formatted()) ft · \(p.kias) kts"
        }
        return [
            "details": details,
            "state": state,
            "timestamps": ["start": startedAt],
            "assets": [
                "large_image": "logo",
                "large_text": "LightFS — GeoFS for macOS",
            ],
            "buttons": [
                ["label": "Fly GeoFS", "url": "https://www.geo-fs.com"],
            ],
        ]
    }

    // MARK: - Socket I/O

    private func openSocket() -> Int32? {
        let env = ProcessInfo.processInfo.environment
        let bases = [env["XDG_RUNTIME_DIR"], env["TMPDIR"], env["TMP"], env["TEMP"], "/tmp"].compactMap { $0 }

        for base in bases {
            for index in 0..<10 {
                let path = (base as NSString).appendingPathComponent("discord-ipc-\(index)")
                let socketFD = socket(AF_UNIX, SOCK_STREAM, 0)
                guard socketFD >= 0 else { continue }

                var noSigPipe: Int32 = 1
                setsockopt(socketFD, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int32>.size))

                var addr = sockaddr_un()
                addr.sun_family = sa_family_t(AF_UNIX)
                let pathBytes = Array(path.utf8)
                let fits = withUnsafeMutableBytes(of: &addr.sun_path) { buffer -> Bool in
                    guard pathBytes.count < buffer.count else { return false }
                    buffer.copyBytes(from: pathBytes)
                    return true
                }
                guard fits else { close(socketFD); continue }

                let result = withUnsafePointer(to: &addr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        Darwin.connect(socketFD, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
                    }
                }
                if result == 0 { return socketFD }
                close(socketFD)
            }
        }
        return nil
    }

    private func setReceiveTimeout(seconds: Int) {
        var tv = timeval(tv_sec: seconds, tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
    }

    private func send(_ op: Opcode, _ payload: [String: Any]) -> Bool {
        guard fd >= 0, let json = try? JSONSerialization.data(withJSONObject: payload) else { return false }
        var frame = Data()
        withUnsafeBytes(of: op.rawValue.littleEndian) { frame.append(contentsOf: $0) }
        withUnsafeBytes(of: UInt32(json.count).littleEndian) { frame.append(contentsOf: $0) }
        frame.append(json)
        return frame.withUnsafeBytes { writeAll(fd: fd, $0) }
    }
}

// MARK: - Framing helpers

nonisolated private func writeAll(fd: Int32, _ buffer: UnsafeRawBufferPointer) -> Bool {
    guard let base = buffer.baseAddress else { return true }
    var offset = 0
    while offset < buffer.count {
        let written = write(fd, base + offset, buffer.count - offset)
        if written < 0 && errno == EINTR { continue }
        if written <= 0 { return false }
        offset += written
    }
    return true
}

nonisolated private func readExactly(fd: Int32, count: Int) -> Data? {
    var data = Data(count: count)
    var offset = 0
    let ok = data.withUnsafeMutableBytes { buffer -> Bool in
        guard let base = buffer.baseAddress else { return true }
        while offset < count {
            let got = read(fd, base + offset, count - offset)
            if got < 0 && errno == EINTR { continue }
            if got <= 0 { return false }
            offset += got
        }
        return true
    }
    return ok ? data : nil
}

nonisolated private func readFrame(fd: Int32) -> (UInt32, [String: Any])? {
    guard let header = readExactly(fd: fd, count: 8) else { return nil }
    let op = header.withUnsafeBytes { UInt32(littleEndian: $0.loadUnaligned(fromByteOffset: 0, as: UInt32.self)) }
    let length = header.withUnsafeBytes { UInt32(littleEndian: $0.loadUnaligned(fromByteOffset: 4, as: UInt32.self)) }
    guard length < 1 << 20, let body = readExactly(fd: fd, count: Int(length)) else { return nil }
    let json = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any] ?? [:]
    return (op, json)
}
