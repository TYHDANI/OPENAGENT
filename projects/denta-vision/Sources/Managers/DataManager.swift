import Foundation
import Security
import CryptoKit

/// Manages all data operations with HIPAA-compliant encryption and persistence
@Observable
final class DataManager {

    // MARK: - Properties

    private let keychain = KeychainService()

    private(set) var patients: [Patient] = []
    private(set) var dentalCharts: [DentalChart] = []
    private(set) var casePresentations: [CasePresentation] = []

    private(set) var isLoading = false
    private(set) var errorMessage: String? = nil

    // MARK: - Initialization

    init() {}

    func initializeDataStore() {
        loadAllData()
    }

    // MARK: - CRUD Operations

    // MARK: Patients

    func createPatient(_ patient: Patient) throws {
        // Encrypt sensitive data before storing
        var encryptedPatient = patient
        encryptedPatient.medicalHistory = try encryptString(patient.medicalHistory)

        patients.append(encryptedPatient)
        saveToLocalStorage()
    }

    func updatePatient(_ patient: Patient) throws {
        guard let index = patients.firstIndex(where: { $0.id == patient.id }) else {
            throw DataError.patientNotFound
        }

        var encryptedPatient = patient
        encryptedPatient.medicalHistory = try encryptString(patient.medicalHistory)
        encryptedPatient.updatedAt = Date()

        patients[index] = encryptedPatient
        saveToLocalStorage()
    }

    func deletePatient(_ patient: Patient) {
        patients.removeAll { $0.id == patient.id }
        // Also delete related data
        dentalCharts.removeAll { $0.patientId == patient.id }
        casePresentations.removeAll { $0.patientId == patient.id }
        saveToLocalStorage()
    }

    // MARK: Dental Charts

    func createDentalChart(_ chart: DentalChart) throws {
        // Encrypt notes
        var encryptedChart = chart
        encryptedChart.notes = try encryptString(chart.notes)

        dentalCharts.append(encryptedChart)
        saveToLocalStorage()
    }

    func updateDentalChart(_ chart: DentalChart) throws {
        guard let index = dentalCharts.firstIndex(where: { $0.id == chart.id }) else {
            throw DataError.chartNotFound
        }

        var encryptedChart = chart
        encryptedChart.notes = try encryptString(chart.notes)
        encryptedChart.updatedAt = Date()

        dentalCharts[index] = encryptedChart
        saveToLocalStorage()
    }

    // MARK: Case Presentations

    func createCasePresentation(_ casePresentation: CasePresentation) {
        casePresentations.append(casePresentation)
        saveToLocalStorage()
    }

    func updateCasePresentation(_ casePresentation: CasePresentation) throws {
        guard let index = casePresentations.firstIndex(where: { $0.id == casePresentation.id }) else {
            throw DataError.caseNotFound
        }

        var updated = casePresentation
        updated.updatedAt = Date()

        casePresentations[index] = updated
        saveToLocalStorage()
    }

    // MARK: - Search & Filtering

    func searchPatients(query: String) -> [Patient] {
        guard !query.isEmpty else { return patients }

        let lowercasedQuery = query.lowercased()
        return patients.filter { patient in
            patient.firstName.lowercased().contains(lowercasedQuery) ||
            patient.lastName.lowercased().contains(lowercasedQuery) ||
            patient.email?.lowercased().contains(lowercasedQuery) ?? false
        }
    }

    func getDentalCharts(for patientId: UUID) -> [DentalChart] {
        dentalCharts.filter { $0.patientId == patientId }
            .sorted { $0.recordingDate > $1.recordingDate }
    }

    func getCasePresentations(for patientId: UUID) -> [CasePresentation] {
        casePresentations.filter { $0.patientId == patientId }
            .sorted { $0.presentationDate > $1.presentationDate }
    }

    // MARK: - Encryption

    private func encryptString(_ string: String) throws -> String {
        // Get or create encryption key from keychain
        let key = try getOrCreateEncryptionKey()

        guard let data = string.data(using: .utf8) else {
            throw DataError.encryptionFailed
        }

        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined?.base64EncodedString() ?? ""
    }

    private func decryptString(_ encryptedString: String) throws -> String {
        let key = try getOrCreateEncryptionKey()

        guard let data = Data(base64Encoded: encryptedString),
              let sealedBox = try? AES.GCM.SealedBox(combined: data) else {
            throw DataError.decryptionFailed
        }

        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw DataError.decryptionFailed
        }

        return string
    }

    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        let keyIdentifier = "com.dentimatch.encryptionKey"

        if let keyData = keychain.retrieve(keyIdentifier) {
            return SymmetricKey(data: keyData)
        }

        // Generate new key
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }

        guard keychain.store(keyData, for: keyIdentifier) else {
            throw DataError.keychainError
        }

        return key
    }

    // MARK: - Persistence

    private func saveToLocalStorage() {
        // For MVP, using JSON file storage with encryption
        // In production, would use Core Data with encrypted store

        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory,
                                                       in: .userDomainMask).first!
            let dataURL = documentsURL.appendingPathComponent("dentimatch_data.encrypted")

            let dataContainer = DataContainer(
                patients: patients,
                dentalCharts: dentalCharts,
                casePresentations: casePresentations
            )

            let encoder = JSONEncoder()
            let data = try encoder.encode(dataContainer)

            // Encrypt the entire data file
            let key = try getOrCreateEncryptionKey()
            let sealedBox = try AES.GCM.seal(data, using: key)

            try sealedBox.combined?.write(to: dataURL)

        } catch {
            errorMessage = "Failed to save data: \(error.localizedDescription)"
        }
    }

    private func loadAllData() {
        isLoading = true

        Task {
            do {
                let documentsURL = FileManager.default.urls(for: .documentDirectory,
                                                           in: .userDomainMask).first!
                let dataURL = documentsURL.appendingPathComponent("dentimatch_data.encrypted")

                guard FileManager.default.fileExists(atPath: dataURL.path) else {
                    isLoading = false
                    return
                }

                let encryptedData = try Data(contentsOf: dataURL)
                guard let sealedBox = try? AES.GCM.SealedBox(combined: encryptedData) else {
                    throw DataError.decryptionFailed
                }

                let key = try getOrCreateEncryptionKey()
                let decryptedData = try AES.GCM.open(sealedBox, using: key)

                let decoder = JSONDecoder()
                let container = try decoder.decode(DataContainer.self, from: decryptedData)

                await MainActor.run {
                    self.patients = container.patients
                    self.dentalCharts = container.dentalCharts
                    self.casePresentations = container.casePresentations
                    self.isLoading = false
                }

                // Decrypt sensitive fields
                for i in patients.indices {
                    patients[i].medicalHistory = try decryptString(patients[i].medicalHistory)
                }

                for i in dentalCharts.indices {
                    dentalCharts[i].notes = try decryptString(dentalCharts[i].notes)
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load data: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum DataError: LocalizedError {
    case patientNotFound
    case chartNotFound
    case caseNotFound
    case encryptionFailed
    case decryptionFailed
    case keychainError

    var errorDescription: String? {
        switch self {
        case .patientNotFound: return "Patient not found"
        case .chartNotFound: return "Dental chart not found"
        case .caseNotFound: return "Case presentation not found"
        case .encryptionFailed: return "Failed to encrypt data"
        case .decryptionFailed: return "Failed to decrypt data"
        case .keychainError: return "Keychain access error"
        }
    }
}

private struct DataContainer: Codable {
    let patients: [Patient]
    let dentalCharts: [DentalChart]
    let casePresentations: [CasePresentation]
}

// Simple Keychain wrapper for encryption keys
private class KeychainService {
    func store(_ data: Data, for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary) // Delete old if exists
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
}