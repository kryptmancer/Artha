//
//  GoogleCredentialsHelper.swift
//  Artha
//
//  Created for managing Google Cloud credentials
//

import Foundation

// This class helps with Google Cloud authentication
// WARNING: In a production app, NEVER store service account credentials directly in your app
class GoogleCredentialsHelper {
    static let shared = GoogleCredentialsHelper()
    
    private var credentials: GoogleCredentials
    
    private init() {
        // Initialize with hardcoded credentials first
        let fallbackCredentials = GoogleCredentials(
            projectId: "psychic-karma-459822-q4",
            privateKeyId: "51c9a4e78b14fcdfe9e0a9e6a1368312d5a4afb1",
            privateKey: "", // Removed for security
            clientEmail: "nepali@psychic-karma-459822-q4.iam.gserviceaccount.com",
            clientId: "107463292087649516872",
            apiKey: "" // Will be loaded from file
        )
        
        // Initialize the property first to avoid using self before initialization
        self.credentials = fallbackCredentials
        
        // Then try to load from file
        if let loadedCredentials = loadCredentialsFromFile() {
            // Update with loaded credentials if available
            self.credentials = loadedCredentials
        } else {
            print("Warning: Using fallback credentials. API calls may not work correctly.")
        }
    }
    
    private func loadCredentialsFromFile() -> GoogleCredentials? {
        guard let filePath = Bundle.main.path(forResource: "google-credentials", ofType: "json") else {
            print("Warning: google-credentials.json not found in app bundle")
            return nil
        }
        
        do {
            let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let json = try JSONSerialization.jsonObject(with: fileData) as? [String: Any]
            
            guard let projectId = json?["project_id"] as? String,
                  let privateKeyId = json?["private_key_id"] as? String,
                  let privateKey = json?["private_key"] as? String,
                  let clientEmail = json?["client_email"] as? String,
                  let clientId = json?["client_id"] as? String else {
                print("Warning: Invalid JSON structure in credentials file")
                return nil
            }
            
            // Load API key as a fallback, but we'll primarily use service account authentication
            var apiKey = ""
            if let apiKeyFromPlist = try? APIKey.getGoogleCloudAPIKey(), !apiKeyFromPlist.isEmpty {
                apiKey = apiKeyFromPlist
            }
            
            return GoogleCredentials(
                projectId: projectId,
                privateKeyId: privateKeyId,
                privateKey: privateKey,
                clientEmail: clientEmail,
                clientId: clientId,
                apiKey: apiKey
            )
        } catch {
            print("Error loading credentials file: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Generate a token for Google Cloud API authentication
    func generateAuthToken() async throws -> String {
        // Check if credentials are loaded properly
        guard !credentials.privateKey.isEmpty else {
            throw NSError(domain: "GoogleCredentialsHelper", code: 401, 
                        userInfo: [NSLocalizedDescriptionKey: "No valid private key found"])
        }
        
        // For Google Cloud API access from mobile apps, it's best to use API keys
        // Using the authorized API key for this project
        let apiKey = "AIzaSyDz4LZ2OvZyfAgWUjnsFmCq79bPUHox6CU"
        
        print("Using API key authentication")
        return apiKey
        
        // Note: If the above API key doesn't work, you'll need to verify that the key
        // is enabled for Speech-to-Text and Translation APIs in the Google Cloud Console
    }
}

// Structure to hold service account credentials
struct GoogleCredentials {
    let projectId: String
    let privateKeyId: String
    let privateKey: String
    let clientEmail: String
    let clientId: String
    let apiKey: String
} 