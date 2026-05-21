import Foundation

public extension Bundle {
    /// The UmaCore SPM resource bundle, exposed for app + widget targets (e.g. widget
    /// gallery `.configurationDisplayName`/`.description` localized via the SYSTEM locale).
    static let umaCore: Bundle = .module
}
