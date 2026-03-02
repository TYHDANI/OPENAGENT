import Speech
import AVFoundation
import Foundation

/// Handles voice recognition for dental charting with clinical terminology support
@Observable
final class VoiceRecognitionService: NSObject {

    // MARK: - Properties

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private(set) var isRecording = false
    private(set) var transcribedText = ""
    private(set) var errorMessage: String? = nil

    // Dental terminology mapping for better recognition
    private let dentalTerms = DentalTerminology()

    // Callback for processed dental commands
    var onDentalCommand: ((DentalCommand) -> Void)?

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: - Recording Control

    func startRecording() throws {
        guard !isRecording else { return }

        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session (iOS only)
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #endif

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceError.recognitionRequestFailed
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcript = result.bestTranscription.formattedString
                self.transcribedText = transcript

                // Process for dental commands
                self.processDentalTranscript(transcript)
            }

            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }

        // Install tap on audio input
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
        errorMessage = nil
    }

    func stopRecording() {
        guard isRecording else { return }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isRecording = false
    }

    // MARK: - Dental Processing

    private func processDentalTranscript(_ transcript: String) {
        // Parse transcript for dental commands
        let commands = parseDentalCommands(from: transcript)

        for command in commands {
            onDentalCommand?(command)
        }
    }

    private func parseDentalCommands(from transcript: String) -> [DentalCommand] {
        var commands: [DentalCommand] = []
        let words = transcript.lowercased().components(separatedBy: .whitespaces)

        // Look for tooth references
        if let toothCommand = parseToothCommand(words: words) {
            commands.append(toothCommand)
        }

        // Look for treatment references
        if let treatmentCommand = parseTreatmentCommand(words: words) {
            commands.append(treatmentCommand)
        }

        // Look for periodontal measurements
        if let perioCommand = parsePeriodontalCommand(words: words) {
            commands.append(perioCommand)
        }

        return commands
    }

    private func parseToothCommand(words: [String]) -> DentalCommand? {
        // Pattern: "tooth [number] [condition]"
        guard let toothIndex = words.firstIndex(of: "tooth") else { return nil }

        if toothIndex + 1 < words.count {
            let nextWord = words[toothIndex + 1]

            // Try to parse tooth number
            if let toothNumber = parseToothNumber(nextWord) {
                // Look for condition after tooth number
                if toothIndex + 2 < words.count {
                    let conditionWord = words[toothIndex + 2]
                    if let condition = dentalTerms.matchCondition(conditionWord) {
                        return .toothCondition(
                            toothNumber: toothNumber,
                            condition: condition
                        )
                    }
                }
            }
        }

        return nil
    }

    private func parseTreatmentCommand(words: [String]) -> DentalCommand? {
        // Look for treatment keywords
        for (index, word) in words.enumerated() {
            if let treatmentType = dentalTerms.matchTreatment(word) {
                // Look for tooth numbers nearby
                var toothNumbers: [Int] = []

                // Check words before and after for tooth numbers
                let range = max(0, index - 3)..<min(words.count, index + 3)
                for i in range {
                    if let tooth = parseToothNumber(words[i]) {
                        toothNumbers.append(tooth)
                    }
                }

                if !toothNumbers.isEmpty {
                    return .treatment(
                        type: treatmentType,
                        toothNumbers: toothNumbers
                    )
                }
            }
        }

        return nil
    }

    private func parsePeriodontalCommand(words: [String]) -> DentalCommand? {
        // Pattern: "probing [numbers]" or "pocket depth [numbers]"
        if let probingIndex = words.firstIndex(of: "probing") ?? words.firstIndex(of: "pocket") {
            var measurements: [Int] = []

            // Look for numbers after the keyword
            for i in (probingIndex + 1)..<min(words.count, probingIndex + 7) {
                if let number = Int(words[i]) {
                    measurements.append(number)
                }
            }

            if measurements.count == 6 {
                // Also try to find which tooth this is for
                var toothNumber: Int?
                for i in max(0, probingIndex - 3)..<probingIndex {
                    if let tooth = parseToothNumber(words[i]) {
                        toothNumber = tooth
                        break
                    }
                }

                return .periodontalMeasurement(
                    toothNumber: toothNumber,
                    measurements: measurements
                )
            }
        }

        return nil
    }

    private func parseToothNumber(_ word: String) -> Int? {
        // Handle various tooth numbering formats
        let cleaned = word.replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "number", with: "")
            .trimmingCharacters(in: .whitespaces)

        if let number = Int(cleaned), (1...32).contains(number) {
            return number
        }

        // Handle word numbers
        return dentalTerms.toothWordToNumber[cleaned]
    }
}

// MARK: - Supporting Types

enum DentalCommand {
    case toothCondition(toothNumber: Int, condition: ToothCondition)
    case treatment(type: TreatmentType, toothNumbers: [Int])
    case periodontalMeasurement(toothNumber: Int?, measurements: [Int])
    case note(text: String)
}

enum VoiceError: LocalizedError {
    case notAuthorized
    case recognitionRequestFailed
    case audioSessionFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition not authorized"
        case .recognitionRequestFailed:
            return "Failed to create recognition request"
        case .audioSessionFailed:
            return "Failed to configure audio session"
        }
    }
}

// Clinical terminology mapping
struct DentalTerminology {
    // Common tooth number words
    let toothWordToNumber: [String: Int] = [
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
        "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14,
        "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18,
        "nineteen": 19, "twenty": 20, "twenty-one": 21, "twenty-two": 22,
        "twenty-three": 23, "twenty-four": 24, "twenty-five": 25,
        "twenty-six": 26, "twenty-seven": 27, "twenty-eight": 28,
        "twenty-nine": 29, "thirty": 30, "thirty-one": 31, "thirty-two": 32
    ]

    // Condition synonyms
    private let conditionMappings: [String: ToothCondition] = [
        "cavity": .cavity,
        "caries": .cavity,
        "decay": .decay,
        "decayed": .decay,
        "filling": .filling,
        "filled": .filling,
        "crown": .crown,
        "crowned": .crown,
        "root canal": .rootCanal,
        "endo": .rootCanal,
        "missing": .missing,
        "extracted": .missing,
        "implant": .implant,
        "bridge": .bridge,
        "crack": .crack,
        "cracked": .crack,
        "abscess": .abscess,
        "abscessed": .abscess,
        "healthy": .healthy,
        "normal": .healthy
    ]

    // Treatment synonyms
    private let treatmentMappings: [String: TreatmentType] = [
        "filling": .filling,
        "fill": .filling,
        "restoration": .filling,
        "crown": .crown,
        "cap": .crown,
        "root canal": .rootCanal,
        "endo": .rootCanal,
        "extraction": .extraction,
        "extract": .extraction,
        "pull": .extraction,
        "implant": .implant,
        "bridge": .bridge,
        "veneer": .veneer,
        "cleaning": .cleaning,
        "prophylaxis": .cleaning,
        "prophy": .cleaning,
        "deep cleaning": .deepCleaning,
        "srp": .deepCleaning,
        "scaling": .deepCleaning
    ]

    func matchCondition(_ word: String) -> ToothCondition? {
        return conditionMappings[word.lowercased()]
    }

    func matchTreatment(_ word: String) -> TreatmentType? {
        return treatmentMappings[word.lowercased()]
    }
}