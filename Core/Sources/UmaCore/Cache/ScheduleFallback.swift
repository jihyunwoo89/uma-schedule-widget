import Foundation

public protocol ScheduleProviding: Sendable {
    func load() throws -> ScheduleDocument
}

public enum ScheduleFallbackError: Error {
    case resourceNotFound(String)
}

public struct ScheduleFallback: Sendable {
    private let bundle: Bundle
    private let resourceName: String

    public init(bundle: Bundle, resourceName: String) {
        self.bundle = bundle
        self.resourceName = resourceName
    }

    public static var production: ScheduleFallback {
        ScheduleFallback(bundle: .module, resourceName: "schedule_fallback")
    }

    public func load() throws -> ScheduleDocument {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw ScheduleFallbackError.resourceNotFound(resourceName)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ScheduleDocument.self, from: try Data(contentsOf: url))
    }
}

extension ScheduleFallback: ScheduleProviding {}
