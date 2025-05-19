//
//  AudioRecorder.swift
//  Artha
//
//  Created for handling audio recording functionality
//

import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var audioURL: URL?
    @Published var recordingDuration: TimeInterval = 0
    
    private var audioRecorder: AVAudioRecorder?
    private var durationTimer: Timer?
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            // Create a temporary file to save the recording
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording.m4a")
            
            // Configure the recorder settings
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 128000,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // Create and prepare the recorder
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            // Start duration timer
            recordingDuration = 0
            durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.recordingDuration += 0.1
            }
            
            audioURL = audioFilename
            isRecording = true
        } catch {
            print("Failed to set up recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        durationTimer?.invalidate()
        isRecording = false
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false)
    }
    
    func getAudioData() -> Data? {
        guard let url = audioURL else { return nil }
        return try? Data(contentsOf: url)
    }
} 