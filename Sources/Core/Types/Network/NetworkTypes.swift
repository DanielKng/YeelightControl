import Foundation

// MARK: - HTTP Method

public enum Core_HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - Network Managing Protocol

public protocol Core_NetworkAPIManaging {
    /// Performs a network request and returns the decoded response
    func request<T: Decodable>(
        _ endpoint: String,
        method: Core_HTTPMethod,
        headers: [String: String]?,
        parameters: [String: Any]?,
        responseType: T.Type
    ) async throws -> T
    
    /// Downloads a file from a URL to a local destination
    func download(from url: URL, to destination: URL) async throws
    
    /// Uploads a file from a local source to a URL
    func upload(from source: URL, to url: URL, method: Core_HTTPMethod, headers: [String: String]?) async throws -> Data
    
    /// Cancels all ongoing network requests
    func cancelAllRequests()
} 