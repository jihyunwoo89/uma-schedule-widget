import SwiftUI

public enum Typography {
    public enum Token: CaseIterable, Hashable, Sendable {
        case title, headline, body, caption, monoCaption
    }

    nonisolated(unsafe) public static var currentTheme: FontTheme = .system

    public static func font(for token: Token, theme: FontTheme? = nil) -> Font {
        let t = theme ?? currentTheme
        switch token {
        case .title:       return .uma(28, weight: .bold,     theme: t)
        case .headline:    return .uma(17, weight: .semibold, theme: t)
        case .body:        return .uma(15, weight: .regular,  theme: t)
        case .caption:     return .uma(12, weight: .medium,   theme: t)
        case .monoCaption: return .system(size: 11, weight: .semibold, design: .monospaced)
        }
    }

    public static func systemFont(size: CGFloat, weight: Font.Weight = .regular, theme: FontTheme? = nil) -> Font {
        .uma(size, weight: weight, theme: theme ?? currentTheme)
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
