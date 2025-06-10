//
//  AuthViewModel.swift
//  APISample
//
//  Created by Hardik Darji on 29/05/25.
//

import Combine
import SwiftUI

//CONST DEFINE HERE.. MAKE SAPEROTE FILE FOR CONSTANT
let keyAccessTokent = "keyAccessTokent"
let keyRefreshTokent = "keyRefreshTokent"
let encryptionKey = "abcDEtKey"

class AuthViewModel: ObservableObject, LoadableViewModelProtocol {
    @Published var authResult: AuthResult? = nil
    @Published var isLoading = false
    @Published var error: String?
    @Published var displayMsg: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func getAuth(reuestModel: AuthRequest) {
        isLoading = true
        error = nil
        guard let encryptedRequest = reuestModel.toEncryptedRequest(using: encryptionKey) else {
            return
        }
        print("Encrypted request: \(encryptedRequest.verificationCode)")
        
        APIClient.shared
            .request(
                endpoint: APIEndpoint.auth.url,
                method: .POST,
                requestBody: encryptedRequest,
                resultType: AuthResult.self
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let err) = completion {
                    self?.error = err.localizedDescription
                }
            } receiveValue: { [weak self] response in
                //in genereal
                //self?.responseMessage = response.message
                self?.authResult = response.result
                self?.displayMsg = response.statusText
                
                //STORE IN USER DEFAULT
                if let accessToken = self?.authResult?.accessToken,
                   let refreshToken = self?.authResult?.refreshToken {
                    UserDefaults.standard.set(accessToken, forKey: keyAccessTokent)
                    UserDefaults.standard.set(refreshToken, forKey: keyRefreshTokent)
                    UserDefaults.standard.synchronize()
                }
                
            }
            .store(in: &cancellables)
    }
    
    func getProfile(reuestModel: ProfileRequest) {
        isLoading = true
        error = nil
        guard let encryptedRequest = reuestModel.toEncryptedRequest(using: encryptionKey) else {
            return
        }
        print("Encrypted request: \(encryptedRequest.verificationCode)")
        
        APIClient.shared
            .request(
                endpoint: APIEndpoint.profile.url,
                method: .POST,
                requestBody: encryptedRequest,
                resultType: UserProfile.self
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let err) = completion {
                    self?.error = err.localizedDescription
                }
            } receiveValue: { [weak self] response in
                //in genereal
                //self?.responseMessage = response.message
                //self?.authResult = response.result
                self?.displayMsg = response.statusText
            }
            .store(in: &cancellables)
    }
    
}
