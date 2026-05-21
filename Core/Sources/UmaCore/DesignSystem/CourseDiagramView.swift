import SwiftUI

public extension Surface {
    /// Diagram track fill color. Turf = green, dirt = brown.
    var trackHex: String {
        switch self {
        case .turf: return "#3FA56B"
        case .dirt: return "#9C6B3F"
        }
    }
    var trackColor: Color { Color(hex: trackHex) ?? .gray }
}

/// Lightweight self-drawn oval course used when no remote track image is available.
public struct CourseDiagramView: View {
    public let track: TrackCondition
    public init(track: TrackCondition) { self.track = track }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(track.surface.trackColor.opacity(0.18))
            Ellipse()
                .stroke(track.surface.trackColor, lineWidth: 6)
                .padding(14)
            VStack(spacing: 2) {
                Text("\(track.distanceMeters)m")
                    .font(.system(size: 18, weight: .bold))
                if let dir = track.direction {
                    Text(dir).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                }
            }
        }
    }
}
