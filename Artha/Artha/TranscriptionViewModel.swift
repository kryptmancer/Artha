//
//  TranscriptionViewModel.swift
//  Artha
//
//  Created by Aryan Kafle on 14/05/2025.
//

import Foundation
import Combine
import AVFoundation

class TranscriptionViewModel: NSObject, ObservableObject {
    // Published properties for UI updates
    @Published var transcribedText: String = ""
    @Published var translatedText: String = ""
    @Published var isListening: Bool = false
    @Published var statusText: String = "Ready"
    
    // Audio components
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioSession: AVAudioSession?
    private var recognitionTask: Task<Void, Error>?
    private var speechSynthesizer: AVSpeechSynthesizer?
    
    // Audio buffer for transcription
    private var audioBuffer = [Float]()
    private let audioManager = AudioCaptureManager()
    private let transcriptionManager = TranscriptionManager()
    
    // Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupListeners()
        setupAudioSession()
    }
    
    private func setupListeners() {
        // Subscribe to transcription updates
        transcriptionManager.transcriptionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.handleTranscription(text)
            }
            .store(in: &cancellables)
        
        // Subscribe to audio session status
        audioManager.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.statusText = status
            }
            .store(in: &cancellables)
        
        // Subscribe to listening state
        audioManager.isListeningPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isListening in
                self?.isListening = isListening
            }
            .store(in: &cancellables)
    }
    
    private func setupAudioSession() {
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            statusText = "Audio session setup failed: \(error.localizedDescription)"
        }
    }
    
    func startListening() {
        audioManager.startCapturing { [weak self] buffer in
            guard let self = self else { return }
            // Send audio buffer to transcription manager
            self.transcriptionManager.processAudioBuffer(buffer)
        }
    }
    
    func stopListening() {
        audioManager.stopCapturing()
    }
    
    private func handleTranscription(_ text: String) {
        if !text.isEmpty {
            // Update transcribed text
            self.transcribedText = text
            
            // For now, just display English text as per requirements
            // In future, this is where we'd handle translations
            
            // Check if earphones are connected and perform TTS if needed
            checkEarphonesAndSpeak(text)
        }
    }
    
    private func checkEarphonesAndSpeak(_ text: String) {
        // Check if audio is routing to earphones/headphones
        guard let outputs = audioSession?.currentRoute.outputs,
              outputs.contains(where: { $0.portType == .headphones || 
                                       $0.portType == .bluetoothA2DP || 
                                       $0.portType == .bluetoothHFP }) else {
            return // No earphones connected
        }
        
        // Initialize speech synthesizer if needed
        if speechSynthesizer == nil {
            speechSynthesizer = AVSpeechSynthesizer()
        }
        
        // Create utterance for the transcribed text
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Speak the text through earphones
        speechSynthesizer?.speak(utterance)
    }
    
    deinit {
        stopListening()
    }
} 