//
//  TranscriptionManager.swift
//  Artha
//
//  Created for simplified transcription handling
//

import Foundation
import AVFoundation

class TranscriptionManager: NSObject {
    static let shared = TranscriptionManager()
    
    override init() {
        super.init()
    }
    
    func getCurrentTranscription() -> String {
        // Simplified for simulation
        return "Sample transcription text"
    }
} 