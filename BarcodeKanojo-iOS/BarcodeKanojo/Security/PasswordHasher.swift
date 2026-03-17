import Foundation
import CryptoKit

/// Password hashing utility matching the Android client's algorithm.
/// Source: Password.kt lines 22-44
///
/// Algorithm: SHA-512 of (password + salt) UTF-8 bytes, output as uppercase hexadecimal string.
/// The Android client calls `hashPassword(password, "")` with an empty salt for login.
enum PasswordHasher {

    /// Hash a password with an optional salt using SHA-512.
    ///
    /// - Parameters:
    ///   - password: The plaintext password.
    ///   - salt: Optional salt string (default empty, matching Android login behavior).
    /// - Returns: Uppercase hexadecimal string of the SHA-512 hash.
    static func hash(password: String, salt: String = "") -> String {
        let input = password + salt
        guard let data = input.data(using: .utf8) else { return "" }
        let digest = SHA512.hash(data: data)
        return digest.map { String(format: "%02X", $0) }.joined()
    }
}
