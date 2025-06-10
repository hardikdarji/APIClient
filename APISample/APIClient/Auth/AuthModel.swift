//
//  AuthModel.swift
//  APISample
//
//  Created by Hardik Darji on 29/05/25.
//
import Foundation

// Request Model
struct EncryptedRequest: Codable {
    let verificationCode: String
}

//Protocol EncryptableRequest
protocol EncryptableRequest: Codable {
    func toEncryptedRequest(using key: String) -> EncryptedRequest?
}

extension EncryptableRequest {
    func toEncryptedRequest(using key: String) -> EncryptedRequest? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes

        guard let jsonData = try? encoder.encode(self),
              let jsonString = String(data: jsonData, encoding: .utf8),
              let encrypted = AESCryption.encryptAES128ECB(plainText: jsonString, key: key) else {
            return nil
        }

        return EncryptedRequest(verificationCode: encrypted)
    }
}

struct AuthRequest: EncryptableRequest {
    let idToken: String?
    let email: String?
    let firstName: String?
    let lastName: String?
}

struct ProfileRequest: EncryptableRequest {
    
}

struct AuthResponse: Codable {
    let statusCode: Int
    let statusDesc: String
    let statusText: String
    let result: AuthResult?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode) ?? -1
        self.statusDesc = try container.decodeIfPresent(String.self, forKey: .statusDesc) ?? "Unknown"
        self.statusText = try container.decodeIfPresent(String.self, forKey: .statusText) ?? ""
        self.result = try container.decodeIfPresent(AuthResult.self, forKey: .result)
    }
}

struct AuthResult: Codable {
    let user: AuthUser?
    let accessToken: String
    let refreshToken: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.user = try container.decodeIfPresent(AuthUser.self, forKey: .user)
        self.accessToken = try container.decodeIfPresent(String.self, forKey: .accessToken) ?? ""
        self.refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken) ?? ""
    }
}

struct AuthUser: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let isProfileCompleted: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        self.firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        self.lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        self.email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        self.isProfileCompleted = try container.decodeIfPresent(Bool.self, forKey: .isProfileCompleted) ?? false
    }
}
