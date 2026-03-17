import Foundation

/// Server response status codes.
/// Source: Response.java lines 13-22
enum ResponseCode: Int, Codable, Sendable {
    case success = 200
    case notEnoughTicket = 202
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case serverError = 500
    case networkError = 502
    case serviceUnavailable = 503
    case finishedConsumeTicket = 600
}
