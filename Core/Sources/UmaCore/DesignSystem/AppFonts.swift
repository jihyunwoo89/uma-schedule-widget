import SwiftUI
import CoreText

/// Bundled OFL Korean fonts (apply to Hangul, unlike SF's design variants).
/// Registered at runtime in both the app and the widget extension.
public enum AppFonts {
    // PostScript names of the bundled fonts.
    public static let rounded = "GowunDodum-Regular"   // 둥근 (Gowun Dodum)
    public static let mono    = "NanumGothicCoding"    // 모노 (Nanum Gothic Coding)
    public static let serif   = "NanumMyeongjo"        // 명조 (Nanum Myeongjo)

    private static let bundledFiles = ["GowunDodum-Regular", "NanumGothicCoding", "NanumMyeongjo"]
    nonisolated(unsafe) private static var didRegister = false

    /// Register the bundled fonts for the current process (idempotent). Call at launch.
    public static func registerIfNeeded() {
        guard !didRegister else { return }
        didRegister = true
        for name in bundledFiles {
            let url = Bundle.module.url(forResource: name, withExtension: "ttf")
                ?? Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
            guard let url else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    /// PostScript name for a theme, or nil for the system default.
    public static func psName(for theme: FontTheme) -> String? {
        switch theme {
        case .system:  return nil
        case .rounded: return rounded
        case .mono:    return mono
        case .serif:   return serif
        }
    }
}

public extension Font {
    /// Themed content font: bundled Korean font for non-system themes (so Hangul
    /// actually changes), else the system font. Honors `Typography.currentTheme`.
    static func uma(_ size: CGFloat, weight: Font.Weight = .regular, theme: FontTheme? = nil) -> Font {
        let t = theme ?? Typography.currentTheme
        if let name = AppFonts.psName(for: t) {
            return .custom(name, fixedSize: size).weight(weight)
        }
        return .system(size: size, weight: weight)
    }
}

public extension View {
    /// Apply the themed content font (replaces `.font(.system(size:weight:))` for text).
    func umaFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.font(.uma(size, weight: weight))
    }
}
