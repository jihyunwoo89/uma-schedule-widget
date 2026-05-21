import Foundation

public enum RemoteScheduleError: Error {
    case badStatus(Int)
}

public struct RemoteScheduleClient: Sendable {
    /// (URL) -> (body, statusCode). Injectable so tests avoid the network.
    public typealias Transport = @Sendable (URL) async throws -> (Data, Int)

    private let url: URL
    private let transport: Transport

    public init(url: URL = ScheduleEndpoint.url, transport: @escaping Transport) {
        self.url = url
        self.transport = transport
    }

    /// Production transport over URLSession.
    public static func live(url: URL = ScheduleEndpoint.url) -> RemoteScheduleClient {
        RemoteScheduleClient(url: url) { url in
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            return (data, code)
        }
    }

    public func fetch() async throws -> ScheduleDocument {
        let (data, code) = try await transport(url)
        guard (200...299).contains(code) else { throw RemoteScheduleError.badStatus(code) }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ScheduleDocument.self, from: data)
    }
}
