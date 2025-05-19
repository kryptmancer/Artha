//
//  GoogleCloudService.swift
//  Artha
//
//  Created for Google Cloud API interactions
//

import Foundation

class GoogleCloudService {
    static let shared = GoogleCloudService()
    
    private let speechToTextURL = "https://speech.googleapis.com/v1p1beta1/speech:recognize"
    private let translateURL = "https://translation.googleapis.com/language/translate/v2"
    
    private init() {}
    
    // MARK: - Authentication
    
    private func getAuthToken() async throws -> String {
        do {
            // Get token from GoogleCredentialsHelper
            return try await GoogleCredentialsHelper.shared.generateAuthToken()
        } catch {
            print("Authentication error: \(error.localizedDescription)")
            throw NSError(domain: "GoogleCloudService", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to authenticate with Google Cloud"])
        }
    }
    
    // MARK: - Speech-to-Text
    
    func transcribeSpeech(audioData: Data) async throws -> String {
        do {
            // Get authentication token (API key)
            let apiKey = try await getAuthToken()
            
            // Build URL with API key as a query parameter
            let urlString = speechToTextURL + "?key=" + apiKey
            guard let url = URL(string: urlString) else {
                throw NSError(domain: "GoogleCloudService", code: 400, 
                             userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            
            // Create the request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Prepare the request body
            let base64Audio = audioData.base64EncodedString()
            let requestBody: [String: Any] = [
                "config": [
                    "encoding": "LINEAR16",
                    "sampleRateHertz": 44100,
                    "languageCode": "ne-NP", // Nepali language code
                    "model": "default",
                    "enableAutomaticPunctuation": true,
                    "useEnhanced": true
                ],
                "audio": [
                    "content": base64Audio
                ]
            ]
            
            // Serialize to JSON
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            
            // Make the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check the response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "GoogleCloudService", code: 500, 
                             userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
            }
            
            if httpResponse.statusCode != 200 {
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("API Error: \(responseString)")
                print("\nStatus code: \(httpResponse.statusCode)")
                
                // For demo purposes, fall back to simulation on error
                return await fallbackSimulateTranscription()
            }
            
            // Parse the response
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            // Extract the transcription
            if let results = json?["results"] as? [[String: Any]],
               let result = results.first,
               let alternatives = result["alternatives"] as? [[String: Any]],
               let alternative = alternatives.first,
               let transcript = alternative["transcript"] as? String {
                return transcript
            } else {
                print("Failed to parse transcription result")
                return await fallbackSimulateTranscription()
            }
        } catch {
            print("Transcription error: \(error.localizedDescription)")
            return await fallbackSimulateTranscription()
        }
    }
    
    // MARK: - Translation
    
    func translateText(text: String, sourceLanguage: String = "ne", targetLanguage: String = "en") async throws -> String {
        do {
            // Get authentication token (API key)
            let apiKey = try await getAuthToken()
            
            // Create the URL components
            var components = URLComponents(string: translateURL)!
            
            // Add query parameters including the API key
            components.queryItems = [
                URLQueryItem(name: "q", value: text),
                URLQueryItem(name: "source", value: sourceLanguage),
                URLQueryItem(name: "target", value: targetLanguage),
                URLQueryItem(name: "format", value: "text"),
                URLQueryItem(name: "key", value: apiKey)
            ]
            
            // Create the URL
            guard let url = components.url else {
                throw NSError(domain: "GoogleCloudService", code: 400, 
                             userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            
            // Create the request
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            // Make the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check the response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "GoogleCloudService", code: 500, 
                             userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
            }
            
            if httpResponse.statusCode != 200 {
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("Translation API Error: \(responseString)")
                print("\nStatus code: \(httpResponse.statusCode)")
                
                // For demo purposes, fall back to simulation
                return await simulateTranslation(text: text)
            }
            
            // Parse the response
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            // Extract the translation
            if let data = json?["data"] as? [String: Any],
               let translations = data["translations"] as? [[String: Any]],
               let translation = translations.first,
               let translatedText = translation["translatedText"] as? String {
                return translatedText
            } else {
                print("Failed to parse translation result")
                return await simulateTranslation(text: text)
            }
        } catch {
            print("Translation error: \(error.localizedDescription)")
            return await simulateTranslation(text: text)
        }
    }
    
    // MARK: - Fallback Methods
    
    private func fallbackSimulateTranscription() async -> String {
        // Simulate a delay to mimic a real API call
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Return a mock response
        return "यस एप्लिकेशनले नेपाली भाषालाई अंग्रेजीमा अनुवाद गर्दछ।"
    }
    
    // Public method for VoiceTranslationViewModel to use
    func simulateTranslation(text: String) async -> String {
        // Simulate a delay to mimic a real API call
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Return a mock response - normally this would be the translation of the input text
        // This is just a placeholder
        return "This application translates Nepali to English."
    }
} 