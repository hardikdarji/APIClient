//
//  Common.swift
//  FloatingInputField
//
//  Created by Hardik Darji on 28/05/25.
//

import SwiftUI

protocol LoadableViewModelProtocol: ObservableObject {
    var isLoading: Bool { get }
    var error: String? { get }
}

struct ApiLoadableView<Content: View, VM: ObservableObject>: View where VM: LoadableViewModelProtocol {
    @ObservedObject var viewModel: VM
    let content: () -> Content
    var errorTextPrefix: String = "Error: "
    var isShowLoading: Bool = true
    var isShowError: Bool = true
    var body: some View {
        VStack {
            if viewModel.isLoading && isShowLoading{
                ProgressView()
            } else if let error = viewModel.error, isShowError {
                Text("\(errorTextPrefix)\(error)")
                    .foregroundColor(.red)
            } else {
                content()
            }
        }
        
    }
}

//UPLOAD FILE SAMPLE USAGE

struct UploadResponse: Decodable {
    let originalname: String
    let filename: String
    let location: String
}
