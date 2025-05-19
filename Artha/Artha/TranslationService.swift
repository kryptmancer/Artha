//
// TranslationService.swift
// Artha
//
// Created for simplified translation handling
//

import Foundation

class TranslationService {
    static let shared = TranslationService()
    
    private init() {}
    
    func translateText(from text: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Simplified for simulation
        let translations = [
            "नमस्ते": "Hello",
            "धन्यवाद": "Thank you",
            "माफ गर्नुहोस्": "Excuse me",
            "तपाईंलाई कस्तो छ?": "How are you?",
            "मलाई राम्रो छ": "I am fine",
            "म नेपाली हुँ": "I am Nepali",
            "मेरो नाम": "My name is"
        ]
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let translation = translations[text] {
                completion(.success(translation))
            } else {
                completion(.success("Translation not available for: \(text)"))
            }
        }
    }
} 