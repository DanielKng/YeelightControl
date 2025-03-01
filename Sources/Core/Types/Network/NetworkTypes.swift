import Foundation

// MARK: - HTTP Method

public enum Core_HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - Network Request Method

public enum Core_NetworkRequestMethod: String, Codable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
}

// MARK: - Network Request

public struct Core_NetworkRequest {
    public let url: URL
    public let method: Core_NetworkRequestMethod
    public let headers: [String: String]
    public let body: Data?
    public let timeout: TimeInterval
    
    public init(
        url: URL,
        method: Core_NetworkRequestMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval = 30
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.timeout = timeout
    }
}

// MARK: - Network Response

public struct Core_NetworkResponse {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data?
    
    public init(
        statusCode: Int,
        headers: [String: String],
        body: Data?
    ) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

// MARK: - Network Error

public enum Core_NetworkError: Error, Hashable {
    case connectionFailed
    case invalidCommand
    case invalidResponse
    case timeout
    case deviceOffline
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