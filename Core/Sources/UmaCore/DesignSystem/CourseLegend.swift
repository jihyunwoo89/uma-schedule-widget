import SwiftUI

/// Legend explaining the gametora course-map encoding (segment colors + markers).
/// Colors sampled directly from the bundled course-map PNGs so they match exactly.
public enum CourseLegendStyle: Sendable { case full, compact }

public struct CourseLegend: View {
    public let style: CourseLegendStyle
    public init(style: CourseLegendStyle = .full) { self.style = style }

    // Exact colors sampled from the course-map images.
    static let turf   = Color(hex: "#00900C") ?? .green
    static let dirt   = Color(hex: "#483024") ?? .brown
    static let early  = Color(hex: "#FCD818") ?? .yellow   // 초반
    static let mid    = Color(hex: "#6048A8") ?? .purple   // 중반
    static let late   = Color(hex: "#3CCCF0") ?? .cyan     // 종반
    static let spurt  = Color(hex: "#E41848") ?? .red      // 라스트 스퍼트
    static let arrow  = Color(hex: "#F0600C") ?? .orange   // 직선/코너
    static let posKeep = Color(hex: "#6048A8") ?? .purple  // 포지션킵 끝
    static let spurtStart = Color(hex: "#2E9BE0") ?? .blue // 스퍼트 시작

    public var body: some View {
        switch style {
        case .full:    full
        case .compact: compact
        }
    }

    // MARK: full — app detail (left of the map)
    private var full: some View {
        VStack(alignment: .leading, spacing: 8) {
            section(.detailLegendSectionTrack, [
                .swatch(Self.turf, .detailLegendTurf),
                .swatch(Self.dirt, .detailLegendDirt),
            ])
            section(.detailLegendSectionPhase, [
                .swatch(Self.early, .detailLegendEarly),
                .swatch(Self.mid,   .detailLegendMid),
                .swatch(Self.late,  .detailLegendLate),
                .swatch(Self.spurt, .detailLegendSpurt),
            ])
            section(.detailLegendSectionTerrain, [
                .symbol("arrow.left.and.right", Self.arrow, .detailLegendStraight),
                .symbol("arrow.turn.up.right",  Self.arrow, .detailLegendCorner),
            ])
            section(.detailLegendSectionEtc, [
                .symbol("chevron.right.2", Self.posKeep,    .detailLegendPositionKeep),
                .symbol("chevron.right.2", Self.spurtStart, .detailLegendSpurtStart),
            ])
        }
    }

    private func section(_ header: L.Key, _ items: [Item]) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(L.string(header))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(WidgetColors.title)
            ForEach(items) { $0.view }
        }
    }

    // MARK: compact — L1 widget (phase colors only; surface is already in the text)
    private var compact: some View {
        HStack(spacing: 9) {
            chip(Self.early, .detailLegendEarly)
            chip(Self.mid,   .detailLegendMid)
            chip(Self.late,  .detailLegendLate)
            chip(Self.spurt, .detailLegendSpurt)
        }
    }

    private func chip(_ color: Color, _ key: L.Key) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color).frame(width: 11, height: 6)
            Text(L.string(key))
                .font(.system(size: 8.5, weight: .medium))
                .foregroundStyle(WidgetColors.cond)
                .lineLimit(1)
        }
    }

    // MARK: item model
    struct Item: Identifiable {
        let id = UUID()
        let icon: AnyView
        let key: L.Key

        static func swatch(_ color: Color, _ key: L.Key) -> Item {
            Item(icon: AnyView(RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color).frame(width: 16, height: 9)), key: key)
        }
        static func symbol(_ name: String, _ color: Color, _ key: L.Key) -> Item {
            Item(icon: AnyView(Image(systemName: name)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color).frame(width: 16)), key: key)
        }

        var view: some View {
            HStack(spacing: 6) {
                icon
                Text(L.string(key))
                    .font(.system(size: 10.5))
                    .foregroundStyle(WidgetColors.raceName)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
