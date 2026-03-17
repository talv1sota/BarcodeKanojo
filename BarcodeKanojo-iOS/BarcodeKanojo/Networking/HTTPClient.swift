import Foundation

/// Low-level URLSession HTTP client.
/// Mirrors Android HttpApi.kt — GET, POST (form-encoded), Multipart POST.
/// Cookie session is handled automatically via HTTPCookieStorage.shared.
final class HTTPClient {

    // MARK: - Errors

    enum HTTPError: Error, LocalizedError {
        case badURL
        case badRequest(String)
        case unauthorized
        case notFound
        case serverError
        case networkError(Int)
        case decodingError(Error)

        var errorDescription: String? {
            switch self {
            case .badURL: return "Invalid URL."
            case .badRequest(let msg): return msg
            case .unauthorized: return "Unauthorized. Please log in again."
            case .notFound: return "Not found."
            case .serverError: return "Server is down. Try again later."
            case .networkError(let code): return "Network error \(code). Try again later."
            case .decodingError(let err): return "Failed to decode response: \(err.localizedDescription)"
            }
        }
    }

    // MARK: - Properties

    private let session: URLSession
    private let settings: AppSettings

    // MARK: - Init

    init(settings: AppSettings = .shared) {
        self.settings = settings

        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Request Builders

    private func baseURL() -> String {
        settings.baseURL
    }

    private func makeURL(_ path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard var components = URLComponents(string: baseURL() + path) else {
            throw HTTPError.badURL
        }
        let nonEmpty = queryItems.filter { $0.value != nil && !($0.value?.isEmpty ?? true) }
        if !nonEmpty.isEmpty {
            components.queryItems = nonEmpty
        }
        guard let url = components.url else {
            throw HTTPError.badURL
        }
        return url
    }

    private func headers() -> [String: String] {
        let locale = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
        let userAgent = Constants.userAgentPrefix + "CFNetwork/\(cfNetworkVersion()) Darwin/\(darwinVersion())"
        return [
            "Accept-Charset": Constants.acceptCharset,
            "User-Agent": userAgent,
            "Accept-Language": locale
        ]
    }

    // MARK: - Execute

    private func execute(_ request: URLRequest) async throws -> Data {
        // Debug logging
        print("▶ \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")")
        if let body = request.httpBody, let bodyStr = String(data: body, encoding: .utf8) {
            let preview = bodyStr.count > 500 ? String(bodyStr.prefix(500)) + "…" : bodyStr
            print("  Body: \(preview)")
        }
        let cookies = HTTPCookieStorage.shared.cookies(for: request.url!) ?? []
        print("  Cookies: \(cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; "))")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw HTTPError.networkError(0)
        }
        print("◀ HTTP \(http.statusCode)")
        if let bodyStr = String(data: data, encoding: .utf8) {
            let preview = bodyStr.count > 800 ? String(bodyStr.prefix(800)) + "…" : bodyStr
            print("  Response: \(preview)")
        }

        switch http.statusCode {
        case 200:
            return data
        case 400, 409:
            let message = String(data: data, encoding: .utf8) ?? "Bad request"
            throw HTTPError.badRequest(message)
        case 401:
            throw HTTPError.unauthorized
        case 404:
            throw HTTPError.notFound
        case 500:
            throw HTTPError.serverError
        default:
            throw HTTPError.networkError(http.statusCode)
        }
    }

    // MARK: - GET

    func get(path: String, params: [String: String?] = [:]) async throws -> Data {
        let queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        let url = try makeURL(path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers().forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return try await execute(request)
    }

    // MARK: - POST (form-encoded)

    func post(path: String, params: [String: String?] = [:]) async throws -> Data {
        let url = try makeURL(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers().forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = params
            .compactMapValues { $0 }
            .filter { !$0.value.isEmpty }
            .map { "\($0.key.urlEncoded)=\($0.value.urlEncoded)" }
            .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        return try await execute(request)
    }

    // MARK: - Multipart POST

    func multipart(path: String, fields: [String: String?] = [:], files: [String: Data] = [:]) async throws -> Data {
        let url = try makeURL(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let boundary = Constants.multipartBoundary
        request.setValue("multipart/form-data;boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let crlf = "\r\n"

        for (name, value) in fields {
            guard let v = value, !v.isEmpty else { continue }
            body.append("--\(boundary)\(crlf)")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\(crlf)\(crlf)")
            body.append(v)
            body.append(crlf)
        }

        for (name, data) in files {
            body.append("--\(boundary)\(crlf)")
            body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"image.png\"\(crlf)")
            body.append("Content-Type: application/octet-stream\(crlf)\(crlf)")
            body.append(data)
            body.append(crlf)
        }

        body.append("--\(boundary)--\(crlf)")
        request.httpBody = body

        return try await execute(request)
    }

    // MARK: - Decode Helper

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("❌ Decode error for \(T.self): \(error)")
            throw HTTPError.decodingError(error)
        }
    }

    // MARK: - System Version Helpers

    private func cfNetworkVersion() -> String { "1490.0.4" }
    private func darwinVersion() -> String { "23.0.0" }
}

// MARK: - Data helpers

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

private extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
