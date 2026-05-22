import SwiftUI

/// Maps a Korean support-card type to its asset icon and accent color. (DESIGN §8.4)
public enum SupportType {
    /// Korean type → asset name in Media.xcassets. Nil for unknown types.
    public static func assetName(forType ko: String) -> String? {
        switch ko.trimmingCharacters(in: .whitespaces) {
        case "스피드":   return "ic_speed"
        case "스태미나": return "ic_stamina"
        case "파워":     return "ic_power"
        case "근성":     return "ic_guts"
        case "지능":     return "ic_wisdom"
        case "그룹":     return "ic_group"
        case "친구":     return "ic_friend"
        default:        return nil
        }
    }

    /// Korean type → name text color. Nil for unknown types.
    public static func color(forType ko: String) -> Color? {
        let hex: String?
        switch ko.trimmingCharacters(in: .whitespaces) {
        case "스피드":   hex = "#0D84F5"
        case "스태미나": hex = "#E63E21"
        case "파워":     hex = "#E59C0D"
        case "근성":     hex = "#E44179"
        case "지능":     hex = "#36B783"
        case "그룹":     hex = "#82C63C"
        case "친구":     hex = "#E6990C"
        default:        hex = nil
        }
        return hex.flatMap { Color(hex: $0) }
    }
}

/// Square support-type icon from the asset catalog. Renders nothing for unknown types.
public struct SupportTypeIcon: View {
    public let type: String
    public let size: CGFloat
    public init(type: String, size: CGFloat = 13) { self.type = type; self.size = size }

    @ViewBuilder
    public var body: some View {
        if let name = SupportType.assetName(forType: type) {
            Image(name, bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        } else {
            EmptyView()
        }
    }
}
