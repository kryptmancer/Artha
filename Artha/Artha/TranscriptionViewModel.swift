//
//  TranscriptionViewModel.swift
//  Artha
//
//  Created for simplified transcription handling
//

import Foundation
import Combine

class TranscriptionViewModel: ObservableObject {
    @Published var transcribedText: String = ""
    @Published var isListening: Bool = false
    
    private var audioBuffer = [Float]()
    private let audioManager = AudioCaptureManager()
    private let transcriptionManager = TranscriptionManager.shared
    
    // Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // Timer for simulating transcription
    private var timer: Timer?
    
    init() {
        // In a real implementation, we would set up the audio recording pipeline here
        // For now, we're just using a mock implementation
        
        #if !targetEnvironment(simulator)
        setupAudioCapture()
        #endif
    }
    
    private func setupAudioCapture() {
        // Configure audio processing (in a real implementation)
        // This is a simplified version that doesn't actually capture audio
    }
    
    func startListening() {
        isListening = true
        
        // In a real implementation, we would start the audio recording pipeline here
        // For now, we're just simulating with a timer
        
        // Start the timer for simulated transcription
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateTranscription()
        }
        timer?.fire() // Update immediately
    }
    
    func stopListening() {
        isListening = false
        
        // Stop the timer
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTranscription() {
        // Get transcription from the manager
        transcribedText = transcriptionManager.getCurrentTranscription()
    }
    
    private func handleAudioBuffer(_ buffer: [Float]) {
        // Add the buffer to our running buffer
        audioBuffer.append(contentsOf: buffer)
        
        // Process the buffer when it gets large enough
        if audioBuffer.count >= 3200 { // approximately 0.2s at 16kHz
            processAudioForTranscription()
            audioBuffer.removeAll()
        }
    }
    
    private func processAudioForTranscription() {
        // Convert audio buffer to a format suitable for the transcription engine
        // This is a simplified version for the simulator
        updateTranscription()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
} 