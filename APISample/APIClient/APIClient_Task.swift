//
//  APIClient.swift

//
//  Created by Hardik Darji on 19/06/25.
//

import Foundation
import SwiftUI

// MARK: - HTTP Method
enum HTTPMethod: String, CaseIterable {
    case GET, POST, PUT, DELETE, PATCH
}

// MARK: - API Error
enum APIError: Error, LocalizedError, Equatable {
    case invalidURL
    case requestFailed(String)
    case invalidResponse
    case statusCodeError(Int, String?)
    case decodingError(String)
    case networkUnavailable
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided."
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .invalidResponse:
            return "Invalid response from server."
        case .statusCodeError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .networkUnavailable:
            return "Network connection unavailable."
        case .timeout:
            return "Request timed out."
        }
    }
    
    var isRetryable: Bool {
        switch self {
//        case .networkUnavailable, .timeout:
        case .statusCodeError(let code, _):
            return code >= 500 || code == 408 || code == 429
        default:
            return false
        }
    }
}

// MARK: - API Configuration
struct APIConfiguration {
    let baseURL: String
    let timeout: TimeInterval
    let defaultHeaders: [String: String]
    
    static let `default` = APIConfiguration(
        baseURL: "https://api.example.com",
        timeout: 30.0,
        defaultHeaders: [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    )
}

// MARK: - API Client
@MainActor
class APIClient: ObservableObject {
    static let shared = APIClient()
    
    private let configuration: APIConfiguration
    private let session: URLSession
    
    private init(configuration: APIConfiguration = .default) {
        self.configuration = configuration
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = configuration.timeout
        config.timeoutIntervalForResource = configuration.timeout * 2
        self.session = URLSession(configuration: config)
    }
    
    // Authentication token management
    @Published var authToken: String? {
        didSet {
            // Optionally persist to keychain
        }
    }
    
    private var authHeaders: [String: String] {
        var headers = configuration.defaultHeaders
        if let token = authToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    // MARK: - Main Request Method
    func request<T: Decodable, U: Encodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        requestBody: U? = nil,
        responseType: T.Type,
        additionalHeaders: [String: String] = [:]
    ) async -> Result<T, APIError> {
        
        // Build full URL
        let fullURL: String
        if endpoint.hasPrefix("http") {
            fullURL = endpoint
        } else {
            fullURL = configuration.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/" + endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        
        guard let url = URL(string: fullURL) else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Set headers
        var allHeaders = authHeaders
        additionalHeaders.forEach { allHeaders[$0] = $1 }
        allHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // Set body for non-GET requests
        if method != .GET, let body = requestBody {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                return .failure(.requestFailed("Failed to encode request body: \(error.localizedDescription)"))
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            return handleResponse(data: data, response: response, responseType: responseType)
        } catch {
            return .failure(mapNetworkError(error))
        }
    }
    
    // MARK: - Convenience Methods
    func get<T: Decodable>(
        endpoint: String,
        responseType: T.Type,
        headers: [String: String] = [:]
    ) async -> Result<T, APIError> {
        await request(
            endpoint: endpoint,
            method: .GET,
            requestBody: EmptyBody?.none,
            responseType: responseType,
            additionalHeaders: headers
        )
    }
    
    func post<T: Decodable, U: Encodable>(
        endpoint: String,
        body: U,
        responseType: T.Type,
        headers: [String: String] = [:]
    ) async -> Result<T, APIError> {
        await request(
            endpoint: endpoint,
            method: .POST,
            requestBody: body,
            responseType: responseType,
            additionalHeaders: headers
        )
    }
    
    func put<T: Decodable, U: Encodable>(
        endpoint: String,
        body: U,
        responseType: T.Type,
        headers: [String: String] = [:]
    ) async -> Result<T, APIError> {
        await request(
            endpoint: endpoint,
            method: .PUT,
            requestBody: body,
            responseType: responseType,
            additionalHeaders: headers
        )
    }
    
    func delete<T: Decodable>(
        endpoint: String,
        responseType: T.Type,
        headers: [String: String] = [:]
    ) async -> Result<T, APIError> {
        await request(
            endpoint: endpoint,
            method: .DELETE,
            requestBody: EmptyBody?.none,
            responseType: responseType,
            additionalHeaders: headers
        )
    }
    
    // MARK: - Private Helpers
    private func handleResponse<T: Decodable>(
        data: Data,
        response: URLResponse,
        responseType: T.Type
    ) -> Result<T, APIError> {
        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(.invalidResponse)
        }
        
        // Handle different status codes
        switch httpResponse.statusCode {
        case 200...299:
            // Success - decode response
            do {
                let decoder = JSONDecoder()
                // Configure date decoding strategy if needed
                decoder.dateDecodingStrategy = .iso8601
                let decodedResponse = try decoder.decode(T.self, from: data)
                return .success(decodedResponse)
            } catch {
                return .failure(.decodingError(error.localizedDescription))
            }
            
        case 400...499:
            // Client errors
            let errorMessage = extractErrorMessage(from: data)
            return .failure(.statusCodeError(httpResponse.statusCode, errorMessage))
            
        case 500...599:
            // Server errors
            let errorMessage = extractErrorMessage(from: data)
            return .failure(.statusCodeError(httpResponse.statusCode, errorMessage))
            
        default:
            return .failure(.statusCodeError(httpResponse.statusCode, "Unexpected status code"))
        }
    }
    
    private func extractErrorMessage(from data: Data) -> String? {
        // Try to extract error message from response body
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json["message"] as? String ?? json["error"] as? String
        }
        return nil
    }
    
    private func mapNetworkError(_ error: Error) -> APIError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .timedOut:
                return .timeout
            default:
                return .requestFailed(urlError.localizedDescription)
            }
        }
        return .requestFailed(error.localizedDescription)
    }
}

// MARK: - Models
struct EmptyBody: Encodable {}

struct SampleRequest: Encodable {
    let id: Int
    let name: String
}

struct SampleResponse: Decodable {
    let message: String
    let success: Bool
}

// MARK: - View Model for SwiftUI Integration
@MainActor
class APIViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sampleResponse: SampleResponse?
    
    private let apiClient = APIClient.shared
    
    func fetchSampleData() async {
        isLoading = true
        errorMessage = nil
        
        let result = await apiClient.get(
            endpoint: "sample",
            responseType: SampleResponse.self
        )
        
        isLoading = false
        
        switch result {
        case .success(let response):
            sampleResponse = response
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    func postSampleData(id: Int, name: String) async {
        isLoading = true
        errorMessage = nil
        
        let requestData = SampleRequest(id: id, name: name)
        let result = await apiClient.post(
            endpoint: "sample",
            body: requestData,
            responseType: SampleResponse.self
        )
        
        isLoading = false
        
        switch result {
        case .success(let response):
            sampleResponse = response
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    func retryLastRequest() async {
        // Implement retry logic based on your needs
        await fetchSampleData()
    }
}

// MARK: - SwiftUI Views
struct ContentView2: View {
    @StateObject private var viewModel = APIViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else {
                    Button("Fetch Data") {
                        Task {
                            await viewModel.fetchSampleData()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Post Data") {
                        Task {
                            await viewModel.postSampleData(id: 1, name: "John Doe")
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                if let response = viewModel.sampleResponse {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Response:")
                            .font(.headline)
                        Text("Message: \(response.message)")
                        Text("Success: \(response.success ? "Yes" : "No")")
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if let error = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error:")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.red)
                        
                        Button("Retry") {
                            Task {
                                await viewModel.retryLastRequest()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("API Demo")
        }
    }
}

// MARK: - Usage Examples
struct APIUsageExamples {
    static func examples() {
        Task {
            let client = await APIClient.shared
            
            // Set auth token
            await MainActor.run {
                client.authToken = "your_auth_token_here"
            }
            
            // GET request
            let getResult = await client.get(
                endpoint: "users/123",
                responseType: SampleResponse.self
            )
            
            // POST request
            let postData = SampleRequest(id: 1, name: "Test")
            let postResult = await client.post(
                endpoint: "users",
                body: postData,
                responseType: SampleResponse.self
            )
            
            // Handle results
            switch getResult {
            case .success(let response):
                print("GET Success: \(response)")
            case .failure(let error):
                print("GET Error: \(error)")
                if error.isRetryable {
                    // Implement retry logic
                    print("Error is retryable")
                }
            }
        }
    }
}

