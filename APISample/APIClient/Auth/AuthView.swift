//
//  AuthView.swift
//  APISample
//
//  Created by Hardik Darji on 29/05/25.
//


import SwiftUI
#Preview {
    AuthView()
}
struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        
        Text("Call Auth API")
            .padding(12)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .onTapGesture {
                viewModel.getAuth(reuestModel: AuthRequest(idToken: "6837187d05b4d438cf53eb3f", email: "dummy1dev@mailinator.com", firstName: "Sam", lastName: "Davis"))
            }
            .padding(32)
        
        Text("Get user Profile")
            .padding(12)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .onTapGesture {
                viewModel.getProfile(reuestModel: ProfileRequest())
            }
            .padding(32)
        
        ApiLoadableView(viewModel: viewModel) {
            Group {
                if viewModel.displayMsg?.count ?? 0 > 0 {
                    Text(viewModel.displayMsg ?? "")
                    Text("AccessToken: \(UserDefaults.standard.string(forKey: keyAccessTokent) ?? "ACCESS TOKEN NOT EXIST")")
                        .padding()
                } else {
                    EmptyView()
                }
            }
        }
       
    }
}
