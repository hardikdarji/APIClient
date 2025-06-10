//
//  AESCryption.swift
//  APISample
//
//  Created by Hardik Darji on 29/05/25.
//
import Foundation
import CryptoKit
import CommonCrypto

class AESCryption {
    
    static func encryptAES128ECB(plainText: String, key: String) -> String? {
        // Convert plain text to Data
        guard let plainData = plainText.data(using: .utf8) else {
            print("Failed to convert plain text to data")
            return nil
        }
        
        // Convert key to Data (UTF-8)
        guard let keyData = key.data(using: .utf8) else {
            print("Failed to convert key to data")
            return nil
        }
        
        // Generate 16-byte key using MD5 (Node.js createCipher behavior)
        var md5Hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        keyData.withUnsafeBytes { keyBytes in
            CC_MD5(keyBytes.baseAddress, CC_LONG(keyData.count), &md5Hash)
        }
        let processedKey = Data(md5Hash)
        
        // Encrypt using CommonCrypto
        let bufferSize = plainData.count + kCCBlockSizeAES128
        var encryptedBytes = [UInt8](repeating: 0, count: bufferSize)
        var numBytesEncrypted: size_t = 0
        
        let cryptStatus = plainData.withUnsafeBytes { plainBytes in
            processedKey.withUnsafeBytes { keyBytes in
                CCCrypt(
                    CCOperation(kCCEncrypt),
                    CCAlgorithm(kCCAlgorithmAES),
                    CCOptions(kCCOptionECBMode | kCCOptionPKCS7Padding),
                    keyBytes.baseAddress,
                    processedKey.count,
                    nil, // IV not used in ECB mode
                    plainBytes.baseAddress,
                    plainData.count,
                    &encryptedBytes,
                    bufferSize,
                    &numBytesEncrypted
                )
            }
        }
        
        guard cryptStatus == kCCSuccess else {
            print("Encryption failed with status: \(cryptStatus)")
            return nil
        }
        
        // Convert encrypted bytes to hex string
        let encryptedData = Data(encryptedBytes.prefix(numBytesEncrypted))
        return encryptedData.hexString
    }
    
    static func decryptAES128ECB(hexData: String, key: String) -> String? {
        // Convert hex string to Data
        guard let encryptedData = Data(hexString: hexData) else {
            print("Failed to convert hex string to data")
            return nil
        }
        
        // Create key using MD5 hash (matching Node.js createDecipher behavior)
        guard let keyData = key.data(using: .utf8) else {
            print("Failed to convert key to data")
            return nil
        }
        
        // Generate 16-byte key using MD5 (Node.js createDecipher behavior)
        var md5Hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        keyData.withUnsafeBytes { keyBytes in
            CC_MD5(keyBytes.baseAddress, CC_LONG(keyData.count), &md5Hash)
        }
        let processedKey = Data(md5Hash)
        
        // Decrypt using CommonCrypto
        let bufferSize = encryptedData.count + kCCBlockSizeAES128
        var decryptedBytes = [UInt8](repeating: 0, count: bufferSize)
        var numBytesDecrypted: size_t = 0
        
        let cryptStatus = encryptedData.withUnsafeBytes { encryptedBytes in
            processedKey.withUnsafeBytes { keyBytes in
                CCCrypt(
                    CCOperation(kCCDecrypt),
                    CCAlgorithm(kCCAlgorithmAES),
                    CCOptions(kCCOptionECBMode | kCCOptionPKCS7Padding),
                    keyBytes.baseAddress,
                    processedKey.count,
                    nil, // IV not used in ECB mode
                    encryptedBytes.baseAddress,
                    encryptedData.count,
                    &decryptedBytes,
                    bufferSize,
                    &numBytesDecrypted
                )
            }
        }
        
        guard cryptStatus == kCCSuccess else {
            print("Decryption failed with status: \(cryptStatus)")
            return nil
        }
        
        // Convert decrypted bytes to Data, then to String
        let decryptedData = Data(decryptedBytes.prefix(numBytesDecrypted))
        
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            print("Failed to convert decrypted data to string")
            print("Decrypted bytes: \(decryptedData.map { String(format: "%02x", $0) }.joined())")
            return nil
        }
        
        return decryptedString
    }
}

// Extension to convert Data to hex string
extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
    
    init?(hexString: String) {
        let hex = hexString.replacingOccurrences(of: " ", with: "")
        guard hex.count % 2 == 0 else { return nil }
        
        var data = Data()
        var index = hex.startIndex
        
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = String(hex[index..<nextIndex])
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        
        self = data
    }
}

/*
// Usage examples
let key = "abcDEtKey"

// Encryption example
let plainText = """
{
   "idToken": "google_id_i9jom6h4b9g2ek2uy2if5u",
   "email": "dummy1dev@mailinator.com",
   "firstName": "Sam",
   "lastName": "Davis"
}
"""
if let encrypted = AESCryption.encryptAES128ECB(plainText: plainText, key: key) {
    print("Encrypted hex: \(encrypted)")
    
    // Test decryption
    if let decrypted = AESCryption.decryptAES128ECB(hexData: encrypted, key: key) {
        print("Decrypted: \(decrypted)")
    }
}
//consol log:
 Encrypted hex: 1be1b50dfd4088035155e2b989a735e9f1300e7396cf928dd98b0e8c8f482cd778891f4feaf32de42a8d8efd4199f947bbeafdd2b68bf82d4bf29fb013d7b0fc25017f5ecc21d8cbb7b8b18264e12e714040c14671f669dd3a7cfa9facc9f83ef3cbb3e25f55f821a9b5decb57ecd47509777bdf9c61968397e9b5654e536c1522038e5de9739f122323088d0bd166f8
 Decrypted: {
    "idToken": "google_id_i9jom6h4b9g2ek2uy2if5u",
    "email": "dummy1dev@mailinator.com",
    "firstName": "Sam",
    "lastName": "Davis"
 }
 */
