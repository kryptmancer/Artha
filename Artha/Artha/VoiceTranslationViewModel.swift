//
//  VoiceTranslationViewModel.swift
//  Artha
//
//  Created to handle the voice translation workflow
//

import Foundation
import Combine

class VoiceTranslationViewModel: ObservableObject {
    // Audio recorder
    private let audioRecorder = AudioRecorder()
    
    // State
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var recordingDuration: TimeInterval = 0
    
    // Results
    @Published var nepaliTranscription = ""
    @Published var englishTranslation = ""
    
    // Error handling
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Testing mode (set to true to use simulated responses instead of real API calls)
    private let useSimulation = false
    
    // Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Bind to the audio recorder's state
        audioRecorder.$isRecording
            .assign(to: &$isRecording)
        
        audioRecorder.$recordingDuration
            .assign(to: &$recordingDuration)
    }
    
    // MARK: - Recording Controls
    
    func startRecording() {
        nepaliTranscription = ""
        englishTranslation = ""
        audioRecorder.startRecording()
    }
    
    func stopRecording() {
        audioRecorder.stopRecording()
        processRecording()
    }
    
    // MARK: - Processing
    
    private func processRecording() {
        if useSimulation {
            simulateProcessing()
            return
        }
        
        guard let audioData = audioRecorder.getAudioData() else {
            showError(message: "Failed to get audio data")
            return
        }
        
        isProcessing = true
        
        // Process in background
        Task {
            do {
                // Step 1: Speech-to-Text (Nepali)
                let transcription = try await GoogleCloudService.shared.transcribeSpeech(audioData: audioData)
                
                // Update UI on main thread
                await MainActor.run {
                    self.nepaliTranscription = transcription
                }
                
                // Step 2: Translate to English
                let translation = try await GoogleCloudService.shared.translateText(
                    text: transcription,
                    sourceLanguage: "ne",
                    targetLanguage: "en"
                )
                
                // Update UI on main thread
                await MainActor.run {
                    self.englishTranslation = translation
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.showError(message: error.localizedDescription)
                    self.isProcessing = false
                }
            }
        }
    }
    
    // Simulates the processing for development without API calls
    private func simulateProcessing() {
        isProcessing = true
        
        // Simulate recording output with random Nepali phrases
        let nepaliPhrases = [
            "नमस्ते",
            "तपाईंलाई कस्तो छ?",
            "म नेपाली हुँ",
            "धन्यवाद",
            "मलाई नेपाली भाषा सिक्न मन लाग्छ",
            "के तपाईं मलाई मदत गर्न सक्नुहुन्छ?",
            "खाना धेरै मिठो छ",
            "मलाई नेपाल धेरै मन पर्छ",
            "यो ठाउँ कति राम्रो",
            "म भारत बाट आएको हुँ"
        ]
        
        // Use recording duration to select more complex phrases for longer recordings
        let selectedPhrases: [String]
        if recordingDuration > 5.0 {
            // For longer recordings, use the later (more complex) phrases
            selectedPhrases = Array(nepaliPhrases.suffix(5))
        } else if recordingDuration > 2.0 {
            // For medium recordings, use middle phrases
            selectedPhrases = Array(nepaliPhrases.dropFirst(3).prefix(4))
        } else {
            // For short recordings, use simpler phrases
            selectedPhrases = Array(nepaliPhrases.prefix(3))
        }
        
        // Get a random phrase from the selected group
        let randomIndex = Int.random(in: 0..<selectedPhrases.count)
        let simulatedNepaliText = selectedPhrases[randomIndex]
        
        // Set the Nepali transcription after a delay to simulate processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.nepaliTranscription = simulatedNepaliText
            
            // Now simulate translation
            Task {
                // Use the simulated translation method
                let translation = await GoogleCloudService.shared.simulateTranslation(text: simulatedNepaliText)
                
                await MainActor.run {
                    self.englishTranslation = translation
                    self.isProcessing = false
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    // MARK: - Text Input Translation
    
    func translateText(nepaliText: String) {
        guard !nepaliText.isEmpty else { return }
        
        nepaliTranscription = nepaliText
        englishTranslation = ""
        isProcessing = true
        
        if useSimulation {
            // Use the simulated translation in development
            Task {
                let translation = await GoogleCloudService.shared.simulateTranslation(text: nepaliText)
                
                await MainActor.run {
                    self.englishTranslation = translation
                    self.isProcessing = false
                }
            }
            return
        }
        
        // Real translation with API
        Task {
            do {
                let translation = try await GoogleCloudService.shared.translateText(
                    text: nepaliText,
                    sourceLanguage: "ne",
                    targetLanguage: "en"
                )
                
                await MainActor.run {
                    self.englishTranslation = translation
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.showError(message: error.localizedDescription)
                    self.isProcessing = false
                }
            }
        }
    }
} 