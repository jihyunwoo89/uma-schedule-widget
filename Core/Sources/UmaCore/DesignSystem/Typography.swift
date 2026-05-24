import SwiftUI

public enum Typography {
    public enum Token: CaseIterable, Hashable, Sendable {
        case title, headline, body, caption, monoCaption
    }

    nonisolated(unsafe) public static var currentTheme: FontTheme = .system

    public static func font(for token: Token, theme: FontTheme? = nil) -> Font {
        let design = fontDesign(for: theme ?? currentTheme)
        switch token {
        case .title:       return .system(size: 28, weight: .bold,     design: design)
        case .headline:    return .system(size: 17, weight: .semibold, design: design)
        case .body:        return .system(size: 15, weight: .regular,  design: design)
        case .caption:     return .system(size: 12, weight: .medium,   design: design)
        case .monoCaption: return .system(size: 11, weight: .semibold, design: .monospaced)
        }
    }

    public static func systemFont(size: CGFloat, weight: Font.Weight = .regular, theme: FontTheme? = nil) -> Font {
        .system(size: size, weight: weight, design: fontDesign(for: theme ?? currentTheme))
    }

    public static func fontDesign(for theme: FontTheme) -> Font.Design {
        switch theme {
        case .system:  return .default
        case .rounded: return .rounded
        case .mono:    return .monospaced
        case .serif:   return .serif
        }
    }
}

public extension View {
    func font(_ token: Typography.Token) -> some View { self.font(Typography.font(for: token)) }
}
