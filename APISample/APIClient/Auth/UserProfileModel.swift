//
//  AuthModel.swift
//  APISample
//
//  Created by Hardik Darji on 29/05/25.
//
import Foundation
struct UserProfile: Codable {
    let updatedAt: String?
    let id: String?
    let lastName: String?
    let enableDistancePreference: Bool?
    let country: String?
    let appleEmailIsPrivate: Bool?
    let state: String?
    let enableAgePreference: Bool?
    let firstName: String?
    let location: Location?
    let dob: String?
    let interests: [String]?
    let isVerified: Bool?
    let notificationSettings: NotificationSettings?
    let distancePreference: Int?
    let email: String?
    let minAgePreference: Int?
    let isPremium: Bool?
    let isProfileCompleted: Bool?
    let isPrivate: Bool?
    let createdAt: String?
    let googleId: String?
    let isActive: Bool?
    let version: Int?
    let city: String?
    let lastActive: String?
    let deviceTokens: [String]?
    let bio: String?
    let maxAgePreference: Int?
    let dailyLikes: LikeLimit?
    let gender: String?
    let age: Int?
    let genderInterest: [String]?
    let photos: [UserPhoto]?
    let superLikes: LikeLimit?
    let lastSocialLoginType: String?

    enum CodingKeys: String, CodingKey {
        case updatedAt
        case id = "_id"
        case lastName
        case enableDistancePreference
        case country
        case appleEmailIsPrivate
        case state
        case enableAgePreference
        case firstName
        case location
        case dob
        case interests
        case isVerified
        case notificationSettings
        case distancePreference
        case email
        case minAgePreference
        case isPremium
        case isProfileCompleted
        case isPrivate
        case createdAt
        case googleId
        case isActive
        case version = "__v"
        case city
        case lastActive
        case deviceTokens
        case bio
        case maxAgePreference
        case dailyLikes
        case gender
        case age
        case genderInterest
        case photos
        case superLikes
        case lastSocialLoginType
    }
}
struct Location: Codable {
    let type: String?
    let coordinates: [Double]?
}
struct LikeLimit: Codable {
    let count: Int?
    let limit: Int?
    let lastReset: String?
}
struct UserPhoto: Codable {
    let id: String?
    let publicId: String?
    let url: String?
    let isPrimary: Bool?
    let uploadedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case publicId
        case url
        case isPrimary
        case uploadedAt
    }
}
struct NotificationSettings: Codable {
    let messages: Bool?
    let likes: Bool?
    let newMatches: Bool?
    let superLikes: Bool?
}
