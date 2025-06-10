//
//  APIClient.swift
//  FloatingInputField
//
//  Created by Hardik Darji on 28/05/25.
//
import Foundation
import Combine

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}
enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case statusCodeError(Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL."
        case .requestFailed(let err): return "Request failed: \(err.localizedDescription)"
        case .invalidResponse: return "Invalid response from server."
        case .statusCodeError(let code): return "Unexpected status code: \(code)."
        case .decodingError(let err): return "Decoding error: \(err.localizedDescription)"
        }
    }
}

class APIClient {
    
    static let shared = APIClient()
    
    private init() {}
    
    private var commonHeaders: [String: String] {
        return [
            "Authorization": "Bearer YOUR_AUTH_TOKEN",
            "Content-Type": "application/json"
        ]
    }
    
    func request<T: Decodable, U: Encodable>(
        endpoint: String,
        method: HTTPMethod,
        requestBody: U?,
        responseType: T.Type
    ) async -> Result<T, APIError> {
        
        guard let url = URL(string: endpoint) else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        commonHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let body = requestBody {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                return .failure(.requestFailed(error))
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                return .failure(.statusCodeError(httpResponse.statusCode))
            }

            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                return .success(decodedResponse)
            } catch {
                return .failure(.decodingError(error))
            }
        } catch {
            return .failure(.requestFailed(error))
        }
    }
}

struct SampleRequest: Encodable {
    let id: Int
    let name: String
}

struct SampleResponse: Decodable {
    let message: String
    let success: Bool
}

@MainActor
func callSampleAPI() async {
    let requestData = SampleRequest(id: 1, name: "John Doe")
    let result = await APIClient.shared.request(
        endpoint: "https://api.example.com/sample",
        method: .POST,
        requestBody: requestData,
        responseType: SampleResponse.self
    )
    
    switch result {
    case .success(let response):
        print("Success: \(response.message)")
    case .failure(let error):
        print("Error: \(error.localizedDescription)")
    }
}
struct EmptyBody: Encodable {}

// Example usage
/*
 let result = await APIClient.shared.request(
     endpoint: "https://api.example.com/sample",
     method: .GET,
     requestBody: Optional<EmptyBody>.none,  // or nil if you refactor to allow nil
     responseType: SampleResponse.self
 )
*/

 
