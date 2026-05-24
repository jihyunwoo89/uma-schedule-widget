import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Renders the bundled gametora course-map image when available, then the cached remote
/// image, otherwise the self-drawn course diagram. Course maps are bundled in UmaCore's
/// asset catalog (`course_{id1}_{id2}`) so they're available at widget timeline-build time.
/// On non-UIKit platforms (e.g. the macOS test host) it always shows the diagram.
public struct TrackImageView: View {
    public let track: TrackCondition
    private let cache: TrackImageCache

    public init(track: TrackCondition, cache: TrackImageCache = .shared()) {
        self.track = track
        self.cache = cache
    }

    public var body: some View {
        #if canImport(UIKit)
        if let name = track.courseMap, let ui = UIImage(named: name, in: .module, compatibleWith: nil) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFit()
        } else if let url = track.imageURL, let data = cache.data(for: url), let ui = UIImage(data: data) {
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
