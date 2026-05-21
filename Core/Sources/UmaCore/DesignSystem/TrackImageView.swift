import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Renders the cached remote track image if present, otherwise the self-drawn course diagram.
/// Reads cache synchronously (WidgetKit-safe). On non-UIKit platforms (e.g. the macOS test
/// host) it always shows the diagram — the widget only ships on iOS.
public struct TrackImageView: View {
    public let track: TrackCondition
    private let cache: TrackImageCache

    public init(track: TrackCondition, cache: TrackImageCache = .shared()) {
        self.track = track
        self.cache = cache
    }

    public var body: some View {
        #if canImport(UIKit)
        if let url = track.imageURL, let data = cache.data(for: url), let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            CourseDiagramView(track: track)
        }
        #else
        CourseDiagramView(track: track)
        #endif
    }
}
