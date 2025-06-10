//  Created by Hardik Darji on 28/05/25.
//
import Foundation
import Combine

let baseURL: String = BaseURL.production.rawValue
// or BaseURL.production.rawValue for production
enum BaseURL: String {
    case development = "https://api.staging.server.com/"
    case production = "https://api.production.server.com/"
}
enum APIEndpoint: String {
    case auth = "auth/google",
         AuthRefresh = "auth/refresh",
         profile = "user/profile"
    var url: String {
        return baseURL + self.rawValue
    }
}

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}

//APIError
enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case noInternet
    case invalidResponse
    case decodingError(Error)
    case serverError(message: String, code: Int)
    case packageNameMissing(message: String, code: Int)
    case encryptionError(message: String, code: Int)
    case accessTokenExpired(message: String, code: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL."
        case .requestFailed(let error): return error.localizedDescription
        case .noInternet: return "No internet connection."
        case .invalidResponse: return "Invalid response from server."
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .serverError(let message, let code): return "Server Error [\(code)]: \(message)"
        case .encryptionError(let message, let code): return "Encryption failed [\(code)]: \(message)"
        case .packageNameMissing(let message, let code): return " [\(code)]: \(message)"
        case .accessTokenExpired(let message, let code): return " [\(code)]: \(message)"

        }
    }
}
//APIResponse Wrapper
struct APIResponse<T: Decodable>: Decodable {
    let statusCode: Int?
    let statusDesc: String?
    let statusText: String?
    let result: T?
}

class APIClient {
    static let shared = APIClient()
    private init() {}
    
    private var commonHeaders: [String: String] {
        [
            "Authorization": "Bearer \(UserDefaults.standard.string(forKey: keyAccessTokent) ?? "-")",
            // uncomment to check 401: "Access token expired" ERROR
            // "Authorization": "Bearer fkldsajfldsafjlkdsajflkdsjfl;dsajfldsajfldsajfldsajfldsajfldsjafdsaf.ds.dfdjsalfkdjsafldsfdlsafjdlsfjldsjfldsajfldsjlfdjsalfjdlsfjlasf",
            "packageName" : "com.app.package.development",
            "version" : "1.1",
            "language" : "English",
            "Content-Type": "application/json"
        ]
    }
   
    func request<T: Decodable, U: Encodable>(
        endpoint: String,
        method: HTTPMethod,
        requestBody: U?,
        resultType: T.Type
    ) -> AnyPublisher<APIResponse<T> ,APIError> {
        
        guard let url = URL(string: endpoint) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }
        
        print("## URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        commonHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let body = requestBody {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                return Fail(error: .requestFailed(error)).eraseToAnyPublisher()
            }
        }
        print("## HEADERS: \(String(describing: commonHeaders))")
        print("## Body: \(String(describing: requestBody))")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> APIResponse<T> in

                // ✅ Print raw JSON response
                if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                   let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
                   let prettyPrintedString = String(data: prettyData, encoding: .utf8) {
                    print("## RESPONSE: \(prettyPrintedString)")
                } else {
                    print("⚠️ Could not pretty-print JSON")
                }
                
                guard response is HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                let decodedWrapper = try JSONDecoder().decode(APIResponse<T>.self, from: data)
                
                if decodedWrapper.statusCode == 200, let result = decodedWrapper.result {
                    return decodedWrapper
                }
                else if decodedWrapper.statusCode == 401 {
                    throw APIError.accessTokenExpired(message: decodedWrapper.statusText ?? "serverError", code: decodedWrapper.statusCode ?? -1)
                }
                else if decodedWrapper.statusCode == 405 {
                    throw APIError.packageNameMissing(message: decodedWrapper.statusText ?? "serverError", code: decodedWrapper.statusCode ?? -1)
                }
                else if decodedWrapper.statusCode == 406 || decodedWrapper.statusCode == 407 {
                    throw APIError.encryptionError(message: decodedWrapper.statusText ?? "serverError", code: decodedWrapper.statusCode ?? -1)
                }
                else {
                    throw APIError.serverError(message: decodedWrapper.statusText ?? "serverError", code: decodedWrapper.statusCode ?? -1)
                }
            }
            .mapError { error -> APIError in
                if let apiError = error as? APIError {
                    return apiError
                }
                
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorNotConnectedToInternet {
                    return .noInternet
                }
                
                if let decodingError = error as? DecodingError {
                    return .decodingError(decodingError)
                }
                
                return .requestFailed(error)
            }
            .eraseToAnyPublisher()
    }
    
    
    func uploadFile<T: Decodable>(
        to urlString: String,
        fileData: Data,
        fileName: String,
        mimeType: String = "image/png",
        formKey: String = "file",
        resultType: T.Type
    ) -> AnyPublisher<T, APIError> {
        
        guard let url = URL(string: urlString) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add the file field
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(formKey)\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")
        
        // Close boundary
        body.append("--\(boundary)--\r\n")
        
        request.httpBody = body
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> T in
                if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                   let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
                   let prettyPrintedString = String(data: prettyData, encoding: .utf8) {
                    print("📦 Upload Response:\n\(prettyPrintedString)")
                }
                //https://api.escuelajs.co/api/v1/files/64c4.png
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                    throw APIError.invalidResponse
                }
                
                return try JSONDecoder().decode(T.self, from: data)
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                if let decodingError = error as? DecodingError {
                    return .decodingError(decodingError)
                }
                return .requestFailed(error)
            }
            .eraseToAnyPublisher()
    }
    
}

struct EmptyBody: Encodable {}

struct SampleResponse: Decodable {
    let message: String
    let success: Bool
}
/*
// ViewModel with Combine + MVVM
import Combine
import SwiftUI

class SampleViewModel: ObservableObject, LoadableViewModelProtocol {
    @Published var responseMessage: String = ""
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func getData() {
        isLoading = true
        error = nil
        
        APIClient.shared
            .request(
                endpoint: APIEndpoint.test2.url,
                method: .GET,
                requestBody: Optional<EmptyBody>.none,
                resultType: SampleResponse.self
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let err) = completion {
                    self?.error = err.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.responseMessage = response.message
            }
            .store(in: &cancellables)
    }
    
}

*/
