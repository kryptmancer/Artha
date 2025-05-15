//
//  ContentView.swift
//  Artha
//
//  Created by Aryan Kafle on 14/05/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TranscriptionViewModel()
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Main content
            VStack(alignment: .leading, spacing: 20) {
                // Transcription
                TranscriptionDisplayView(
                    originalText: viewModel.transcribedText,
                    translatedText: viewModel.translatedText
                )
                
                Spacer()
                
                // Status indicator
                HStack {
                    Circle()
                        .fill(viewModel.isListening ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    
                    Text(viewModel.statusText)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.startListening()
        }
    }
}

struct TranscriptionDisplayView: View {
    var originalText: String
    var translatedText: String
    
    var body: some View {
        ZStack {
            // Blurred background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .background(.ultraThinMaterial)
                .blur(radius: 3)
            
            VStack(alignment: .leading, spacing: 16) {
                // Original transcription
                VStack(alignment: .leading, spacing: 4) {
                    Text("Original")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(originalText.isEmpty ? "Listening for speech..." : originalText)
                        .font(.body)
                        .foregroundColor(.white)
                }
                
                // Translated text (if enabled)
                if !translatedText.isEmpty {
                    Divider().background(Color.gray.opacity(0.3))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("English")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(translatedText)
                            .font(.body)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    ContentView()
}
