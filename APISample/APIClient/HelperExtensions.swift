//
//  Extensions.swift
//  APISample
//
//  Created by Hardik Darji on 28/05/25.
//
import Foundation
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

