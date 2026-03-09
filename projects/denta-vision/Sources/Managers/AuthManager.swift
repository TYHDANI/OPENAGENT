import Foundation
import Security
#if canImport(UIKit)
import UIKit
#endif
import LocalAuthentication
import CryptoKit

/// Manages authentication and HIPAA compliance
@Observable
final class AuthManager {

    // MARK: - Properties

    private(set) var isAuthenticated = false
    private(set) var currentUser: User? = nil
    var showLoginScreen = false

    private let keychain = KeychainService()
    private let biometricAuth = LAContext()

    // Session timeout after 10 minutes of inactivity
    private let sessionTimeout: TimeInterval = 600
    private var lastActivityTime = Date()
    private var sessionTimer: Timer?

    // MARK: - Initialization

    init() {
        setupSessionMonitoring()
        checkExistingSession()
    }

    // MARK: - Authentication

    func login(email: String, password: String) async throws {
        // In production, this would validate against a secure backend
        // For MVP, using local validation with hashed credentials

        guard !email.isEmpty && !password.isEmpty else {
            throw AuthError.invalidCredentials
        }

        // Hash password for comparison
        let hashedPassword = hashPassword(password)

        // Check stored credentials (in production, this would be server-side)
        if let storedUser = retrieveStoredUser(email: email) {
            if storedUser.hashedPassword == hashedPassword {
                await MainActor.run {
                    self.currentUser = storedUser
                    self.isAuthenticated = true
                    self.showLoginScreen = false
                    self.lastActivityTime = Date()
                }

                // Store session token
                storeSessionToken(for: storedUser)

                // Log HIPAA audit event
                logAuditEvent(.login, userId: storedUser.id)
            } else {
                throw AuthError.invalidCredentials
            }
        } else {
            // For demo purposes, create new user on first login
            let newUser = User(
                email: email,
                hashedPassword: hashedPassword,
                role: .practitioner
            )

            storeUser(newUser)

            await MainActor.run {
                self.currentUser = newUser
                self.isAuthenticated = true
                self.showLoginScreen = false
                self.lastActivityTime = Date()
            }

            storeSessionToken(for: newUser)
            logAuditEvent(.accountCreated, userId: newUser.id)
        }
    }

    func logout() {
        guard let userId = currentUser?.id else { return }

        // Log HIPAA audit event before clearing
        logAuditEvent(.logout, userId: userId)

        // Clear session
        currentUser = nil
        isAuthenticated = false
        clearSessionToken()

        // Show login screen
        showLoginScreen = true
    }

    func authenticateWithBiometrics() async throws {
        var error: NSError?

        guard biometricAuth.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.biometricsNotAvailable
        }

        let reason = "Authenticate to access patient data"

        do {
            let success = try await biometricAuth.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            if success {
                // Restore previous session if available
                if let session = retrieveSessionToken() {
                    await MainActor.run {
                        self.currentUser = session.user
                        self.isAuthenticated = true
                        self.showLoginScreen = false
                        self.lastActivityTime = Date()
                    }

                    logAuditEvent(.biometricLogin, userId: session.user.id)
                } else {
                    throw AuthError.noStoredSession
                }
            }
        } catch {
            throw AuthError.biometricsFailed
        }
    }

    // MARK: - Session Management

    func updateActivity() {
        lastActivityTime = Date()
    }

    private func setupSessionMonitoring() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkSessionTimeout()
        }
    }

    private func checkSessionTimeout() {
        let timeSinceLastActivity = Date().timeIntervalSince(lastActivityTime)

        if timeSinceLastActivity > sessionTimeout && isAuthenticated {
            Task { @MainActor in
                self.logout()
            }
        }
    }

    private func checkExistingSession() {
        if let session = retrieveSessionToken() {
            // Verify session is still valid
            let sessionAge = Date().timeIntervalSince(session.createdAt)

            if sessionAge < 86400 { // 24 hour max session
                currentUser = session.user
                isAuthenticated = true
                lastActivityTime = Date()
            } else {
                clearSessionToken()
                showLoginScreen = true
            }
        } else {
            showLoginScreen = true
        }
    }

    // MARK: - Security Helpers

    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Persistence

    private func storeUser(_ user: User) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(user) {
            keychain.store(data, for: "user_\(user.email)")
        }
    }

    private func retrieveStoredUser(email: String) -> User? {
        guard let data = keychain.retrieve("user_\(email)") else { return nil }

        let decoder = JSONDecoder()
        return try? decoder.decode(User.self, from: data)
    }

    private func storeSessionToken(for user: User) {
        let session = SessionToken(user: user, createdAt: Date())
        let encoder = JSONEncoder()

        if let data = try? encoder.encode(session) {
            keychain.store(data, for: "session_token")
        }
    }

    private func retrieveSessionToken() -> SessionToken? {
        guard let data = keychain.retrieve("session_token") else { return nil }

        let decoder = JSONDecoder()
        return try? decoder.decode(SessionToken.self, from: data)
    }

    private func clearSessionToken() {
        keychain.delete("session_token")
    }

    // MARK: - HIPAA Audit Logging

    private func logAuditEvent(_ event: AuditEvent, userId: UUID) {
        #if canImport(UIKit)
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        #else
        let deviceId = Host.current().localizedName ?? "unknown"
        #endif
        let auditEntry = HIPAAAuditEntry(
            eventType: event,
            userId: userId,
            timestamp: Date(),
            deviceId: deviceId
        )

        // In production, this would be sent to a secure audit log server
        // For MVP, storing locally
        var auditLog = retrieveAuditLog()
        auditLog.append(auditEntry)
        storeAuditLog(auditLog)
    }

    private func retrieveAuditLog() -> [HIPAAAuditEntry] {
        guard let data = keychain.retrieve("hipaa_audit_log") else { return [] }

        let decoder = JSONDecoder()
        return (try? decoder.decode([HIPAAAuditEntry].self, from: data)) ?? []
    }

    private func storeAuditLog(_ log: [HIPAAAuditEntry]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(log) {
            keychain.store(data, for: "hipaa_audit_log")
        }
    }
}

// MARK: - Supporting Types

struct User: Codable {
    let id: UUID
    let email: String
    let hashedPassword: String
    let role: UserRole
    let createdAt: Date

    init(
        id: UUID = UUID(),
        email: String,
        hashedPassword: String,
        role: UserRole
    ) {
        self.id = id
        self.email = email
        self.hashedPassword = hashedPassword
        self.role = role
        self.createdAt = Date()
    }
}

enum UserRole: String, Codable {
    case practitioner
    case assistant
    case admin
}

struct SessionToken: Codable {
    let user: User
    let createdAt: Date
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case biometricsNotAvailable
    case biometricsFailed
    case noStoredSession
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .biometricsNotAvailable:
            return "Biometric authentication is not available"
        case .biometricsFailed:
            return "Biometric authentication failed"
        case .noStoredSession:
            return "No stored session found"
        case .sessionExpired:
            return "Your session has expired"
        }
    }
}

enum AuditEvent: String, Codable {
    case login
    case logout
    case biometricLogin
    case accountCreated
    case patientAccess
    case patientModified
    case patientDeleted
    case chartCreated
    case chartModified
    case casePresented
    case exportData
}

struct HIPAAAuditEntry: Codable {
    let id: UUID
    let eventType: AuditEvent
    let userId: UUID
    let timestamp: Date
    let deviceId: String
    let additionalInfo: String?

    init(
        eventType: AuditEvent,
        userId: UUID,
        timestamp: Date,
        deviceId: String,
        additionalInfo: String? = nil
    ) {
        self.id = UUID()
        self.eventType = eventType
        self.userId = userId
        self.timestamp = timestamp
        self.deviceId = deviceId
        self.additionalInfo = additionalInfo
    }
}

// Keychain wrapper
private class KeychainService {
    @discardableResult
    func store(_ data: Data, for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func retrieve(_ key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}