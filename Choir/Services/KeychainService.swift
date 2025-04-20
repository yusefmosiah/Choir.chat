import Foundation
import Security
import LocalAuthentication

class KeychainService {
    // Access control for biometric authentication
    private func biometricAccessControl() -> SecAccessControl? {
        // Check if biometric authentication is available
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                print("Biometric authentication not available: \(error)")
            }
            return nil
        }

        // Create access control with biometric authentication
        var createError: Unmanaged<CFError>?
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            [.biometryAny, .userPresence], // Allow biometry or passcode
            &createError
        )

        if let error = createError?.takeRetainedValue() {
            print("Error creating access control: \(error)")
            return nil
        }

        return access
    }

    // Check if biometric authentication is available
    func canUseBiometricAuthentication() -> Bool {
        let context = LAContext()
        var error: NSError?

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if let error = error {
            print("Error checking biometric availability: \(error)")
            return false
        }

        return canEvaluate
    }

    // Get the biometric type (Face ID or Touch ID)
    func biometricType() -> String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Passcode"
        }
    }

    func save(_ data: String?, forKey key: String, useBiometric: Bool = true) throws {
        guard let data = data?.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Add biometric protection if requested and available
        if useBiometric {
            if let accessControl = biometricAccessControl() {
                query[kSecAttrAccessControl as String] = accessControl

                // Explicitly set these for biometric auth
                query[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIAllow
            } else {
                print("Biometric access control not available, using standard protection")
                query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            }
        } else {
            // Standard protection without biometrics
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        // First try to delete any existing item
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(deleteQuery as CFDictionary)

        // Then add the new item
        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            throw KeychainError.saveFailed(status: status)
        }
    }

    // Check if a key exists in the keychain without triggering biometric auth
    func hasKey(_ key: String) throws -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUIFail, // Don't show auth UI
            kSecReturnData as String: false // Don't return the actual data
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)

        if status == errSecSuccess {
            return true
        } else if status == errSecItemNotFound {
            return false
        } else if status == errSecInteractionNotAllowed {
            // Item exists but requires authentication
            return true
        } else {
            throw KeychainError.loadFailed(status: status)
        }
    }

    func load(_ key: String, withPrompt prompt: String? = nil, requireBiometric: Bool = false) throws -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        // Add authentication prompt if provided
        if let prompt = prompt {
            query[kSecUseOperationPrompt as String] = prompt
            query[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIAllow
        }

        // Force biometric authentication if required
        if requireBiometric {
            // Check if biometric authentication is available
            let context = LAContext()
            var authError: NSError?

            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                query[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIAllow

                // If no prompt was provided, use a default one
                if prompt == nil {
                    query[kSecUseOperationPrompt as String] = "Authenticate to access secure data"
                }
            } else {
                throw KeychainError.biometricNotAvailable
            }
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            if status != errSecItemNotFound {
                throw KeychainError.loadFailed(status: status)
            }
            return nil
        }

        return string
    }

    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deleteFailed(status: status)
        }
    }

    func getAllKeys(withPrefix prefix: String? = nil) throws -> [String] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return []
        }

        if status != errSecSuccess {
            throw KeychainError.loadFailed(status: status)
        }

        guard let items = result as? [[String: Any]] else {
            return []
        }

        let keys = items.compactMap { item -> String? in
            guard let key = item[kSecAttrAccount as String] as? String else {
                return nil
            }

            if let prefix = prefix {
                return key.hasPrefix(prefix) ? key : nil
            } else {
                return key
            }
        }

        return keys
    }
}

enum KeychainError: Error, LocalizedError {
    case invalidData
    case saveFailed(status: OSStatus)
    case loadFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
    case biometricNotAvailable

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data provided"
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .loadFailed(let status):
            return "Failed to load from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(status)"
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        }
    }
}
