import Foundation

nonisolated enum AppError: Error, Equatable, Sendable {
    case network(String)
    case notFound
    case unauthorized
    case unknown(String)
}
