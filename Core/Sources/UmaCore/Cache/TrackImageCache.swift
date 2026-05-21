import Foundation
import CryptoKit

/// File cache for remote track images, living in the App Group container so both the app
/// (which downloads) and the widget (which reads) can access it. WidgetKit views load the
/// bytes synchronously from disk — no async image loading in widget bodies.
public struct TrackImageCache: Sendable {
    private let directory: URL
    private let fm = FileManager.default

    public init(directory: URL) { self.directory = directory }

    /// Shared instance rooted in the App Group container's `track-images/` folder.
    public static func shared() -> TrackImageCache {
        let base = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroupStore.suiteName)
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("track-images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return TrackImageCache(directory: dir)
    }

    public static func fileName(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return hex + "." + (url.pathExtension.isEmpty ? "img" : url.pathExtension)
    }

    private func fileURL(for url: URL) -> URL { directory.appendingPathComponent(Self.fileName(for: url)) }

    public func data(for url: URL) -> Data? { try? Data(contentsOf: fileURL(for: url)) }

    public func store(_ data: Data, for url: URL) throws { try data.write(to: fileURL(for: url)) }

    /// Download + cache if not already present. Safe to call from the app or a TimelineProvider.
    public func ensureCached(_ url: URL, transport: @Sendable (URL) async throws -> Data) async {
        guard data(for: url) == nil else { return }
        if let bytes = try? await transport(url) { try? store(bytes, for: url) }
    }
}
