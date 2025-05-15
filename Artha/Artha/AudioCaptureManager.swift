//
//  AudioCaptureManager.swift
//  Artha
//
//  Created by Aryan Kafle on 14/05/2025.
//

import Foundation
import AVFoundation
import Combine

class AudioCaptureManager: NSObject {
    // Publishers for status updates
    private let statusSubject = PassthroughSubject<String, Never>()
    var statusPublisher: AnyPublisher<String, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    // Publisher for listening state
    private let isListeningSubject = CurrentValueSubject<Bool, Never>(false)
    var isListeningPublisher: AnyPublisher<Bool, Never> {
        isListeningSubject.eraseToAnyPublisher()
    }
    
    // Audio components
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    
    // Buffer parameters
    private let bufferSize: AVAudioFrameCount = 4096
    private let sampleRate = 16000
    
    // VAD parameters
    private let vadEnergyThreshold: Float = 0.01
    private let vadSilenceThreshold: TimeInterval = 1.0  // Silence duration before considering speech ended
    private var lastVoiceDetectedTime: Date?
    private var isDetectingVoice = false
    
    // Audio processing callback
    private var audioBufferCallback: ((Data) -> Void)?
    
    override init() {
        super.init()
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        guard let inputNode = inputNode else {
            statusSubject.send("Failed to get audio input node")
            return
        }
        
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, 
                                            sampleRate: Double(sampleRate), 
                                            channels: 1, 
                                            interleaved: false)
        
        guard let format = recordingFormat else {
            statusSubject.send("Failed to create audio format")
            return
        }
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, time in
            guard let self = self else { return }
            self.processAudioBuffer(buffer)
        }
    }
    
    func startCapturing(audioBufferHandler: @escaping (Data) -> Void) {
        audioBufferCallback = audioBufferHandler
        
        do {
            try audioEngine?.start()
            isListeningSubject.send(true)
            statusSubject.send("Listening...")
        } catch {
            statusSubject.send("Failed to start audio engine: \(error.localizedDescription)")
        }
    }
    
    func stopCapturing() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        isListeningSubject.send(false)
        statusSubject.send("Stopped")
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Convert buffer to raw audio data
        guard let channelData = buffer.floatChannelData?[0],
              let callback = audioBufferCallback else { return }
        
        let frameCount = Int(buffer.frameLength)
        let audioData = Data(bytes: channelData, count: frameCount * MemoryLayout<Float>.size)
        
        // Perform VAD - check if there's voice activity
        let energy = calculateAudioEnergy(channelData, frameCount: frameCount)
        let hasVoice = energy > vadEnergyThreshold
        
        if hasVoice {
            lastVoiceDetectedTime = Date()
            if !isDetectingVoice {
                isDetectingVoice = true
                statusSubject.send("Voice detected")
            }
            
            // Only send data when voice is detected
            callback(audioData)
        } else {
            // Check if silence has been long enough to consider speech ended
            if isDetectingVoice, 
               let lastVoiceTime = lastVoiceDetectedTime,
               Date().timeIntervalSince(lastVoiceTime) > vadSilenceThreshold {
                isDetectingVoice = false
                statusSubject.send("Listening...")
            }
        }
    }
    
    private func calculateAudioEnergy(_ buffer: UnsafePointer<Float>, frameCount: Int) -> Float {
        var sum: Float = 0
        for i in 0..<frameCount {
            let sample = buffer[i]
            sum += sample * sample
        }
        return frameCount > 0 ? sqrt(sum / Float(frameCount)) : 0
    }
    
    deinit {
        stopCapturing()
    }
} 