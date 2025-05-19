//
//  APIKey.swift
//  Artha
//
//  Created to handle API key management
//

import Foundation

enum APIKey {
    // Fetch the API key from `GenerativeAI-Info.plist`
    static var `default`: String {
        guard let filePath = Bundle.main.path(forResource: "GenerativeAI-Info", ofType: "plist")
        else {
            fatalError("Couldn't find file 'GenerativeAI-Info.plist'.")
        }
        
        let plist = NSDictionary(contentsOfFile: filePath)
        
        guard let value = plist?.object(forKey: "API_KEY") as? String else {
            fatalError("Couldn't find key 'API_KEY' in 'GenerativeAI-Info.plist'.")
        }
        
        if value == "YOUR_GEMINI_API_KEY" {
            fatalError("Please add your Gemini API key to 'GenerativeAI-Info.plist'.")
        }
        
        return value
    }

    // Fetch the Google Cloud API key from the environment or info.plist
    static func getGoogleCloudAPIKey() throws -> String {
        // Check if API key is defined in NewInfo.plist
        guard let filePath = Bundle.main.path(forResource: "NewInfo", ofType: "plist") else {
            print("Warning: NewInfo.plist not found")
            return "" // Return empty string to trigger fallback
        }
        
        let plist = NSDictionary(contentsOfFile: filePath)
        
        // Try to get API key from plist
        if let value = plist?.object(forKey: "GOOGLE_CLOUD_API_KEY") as? String, 
           !value.isEmpty && value != "YOUR_GOOGLE_CLOUD_API_KEY" {
            return value
        }
        
        // If no API key is found in plist, check for environment variable
        // This is useful for development and CI/CD pipelines
        if let envKey = ProcessInfo.processInfo.environment["GOOGLE_CLOUD_API_KEY"], 
           !envKey.isEmpty {
            return envKey
        }
        
        // No API key found, return empty string to trigger fallback
        print("Warning: No Google Cloud API key found")
        return ""
    }
} 