# Swift Security Rules

## Secrets & Credentials

- **NEVER** hardcode API keys, tokens, passwords, or secrets in source code
- **NEVER** commit `.env` files, `Secrets.plist`, or credential files to git
- Store secrets in: Keychain (runtime), environment variables (build time), or App Store Connect (server-side)
- Use `ProcessInfo.processInfo.environment["KEY"]` for build-time secrets only
- For user credentials, always use Keychain Services:

```swift
// Keychain wrapper pattern
final class KeychainService {
    static func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary) // Remove existing
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
}
```

## Input Validation

- Validate ALL user input before using it
- Sanitize strings before displaying in web views (`WKWebView`)
- Never construct SQL/predicate queries from raw user input
- Use parameterized queries with SwiftData/CoreData
- Validate URL inputs before opening:

```swift
guard let url = URL(string: userInput),
      ["https", "http"].contains(url.scheme?.lowercased()) else {
    return // Reject non-HTTP URLs
}
```

## Network Security

- **HTTPS only** — never disable App Transport Security (ATS)
- Pin certificates for high-security APIs (banking, health data)
- Use `URLSession` with default configuration — never disable SSL validation
- Set reasonable timeouts: `URLRequest.timeoutInterval = 30`
- Handle all HTTP status codes, not just 200

```swift
// Never do this:
// let config = URLSessionConfiguration.default
// config.tlsMinimumSupportedProtocolVersion = .tlsProtocol1 // INSECURE

// Always validate response
guard let httpResponse = response as? HTTPURLResponse,
      (200...299).contains(httpResponse.statusCode) else {
    throw NetworkError.invalidResponse
}
```

## Data Protection

- Use appropriate file protection levels:
  - `.completeProtection` for sensitive data (health, financial)
  - `.completeUntilFirstUserAuthentication` for data needed at launch
- Encrypt sensitive local data using `CryptoKit`:

```swift
import CryptoKit

func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
    let sealedBox = try AES.GCM.seal(data, using: key)
    return sealedBox.combined!
}
```

## Biometric Authentication

- Use `LAContext` for biometric auth, always provide password fallback
- Never store biometric data yourself — let the system handle it
- Check `canEvaluatePolicy` before attempting evaluation

## Privacy

- **Privacy manifests** (required for App Store): declare all API usage in `PrivacyInfo.xcprivacy`
- Required API declarations: UserDefaults, file timestamp, disk space, system boot time
- Request only necessary permissions — explain each in Info.plist:
  - `NSCameraUsageDescription`
  - `NSPhotoLibraryUsageDescription`
  - `NSLocationWhenInUseUsageDescription`
  - etc.
- Never collect data not disclosed in the privacy nutrition label
- Implement data deletion capability (required by Apple)

## Common Vulnerabilities to Avoid

| Vulnerability | Prevention |
|---------------|------------|
| Insecure data storage | Use Keychain for credentials, encrypted CoreData for sensitive data |
| Insufficient transport security | HTTPS only, certificate pinning for sensitive APIs |
| Insecure authentication | Use ASWebAuthenticationSession for OAuth, never roll your own auth |
| Code injection | Never use `NSPredicate(format:)` with user input — use `#Predicate` |
| Broken cryptography | Use `CryptoKit` — never implement custom crypto |
| Insecure logging | Never log PII, tokens, or credentials — even in DEBUG |
| Jailbreak detection bypass | Don't rely solely on jailbreak detection for security |

## App Store Review Security Checklist

- [ ] No hardcoded secrets in source
- [ ] PrivacyInfo.xcprivacy includes all required API reasons
- [ ] All permission descriptions in Info.plist are clear and specific
- [ ] HTTPS used for all network requests
- [ ] User data can be deleted on request
- [ ] Sensitive data encrypted at rest
- [ ] No private API usage
- [ ] No clipboard snooping without user action
