//
//  ContentView.swift
//  Artha
//
//  Created by Aryan Kafle on 14/05/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = VoiceTranslationViewModel()
    @State private var showingMicrophonePermissionAlert = false
    
    // For text input
    @State private var nepaliText = ""
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Nepali Voice Translator")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 30)
                
                // Language pair indicator
                HStack(spacing: 12) {
                    Text("नेपाली")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("English")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.3))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                )
                
                // Recording visualization and controls
                VStack {
                    // Animated waveform
                    VoiceWaveformView(isRecording: viewModel.isRecording, duration: viewModel.recordingDuration)
                        .padding(.horizontal)
                        .frame(height: 50)
                        .opacity(viewModel.isRecording ? 1 : 0.3)
                    
                    // Record button
                    Button(action: {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            viewModel.startRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isRecording ? Color.red : Color.blue)
                                .frame(width: 70, height: 70)
                                .shadow(radius: 5)
                            
                            if viewModel.isRecording {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .frame(width: 20, height: 20)
                            } else {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(viewModel.isProcessing)
                    .opacity(viewModel.isProcessing ? 0.5 : 1.0)
                    
                    // Recording status
                    VStack(spacing: 5) {
                        Text(recordingStatusText)
                            .font(.caption)
                            .foregroundColor(.white)
                            .opacity(0.8)
                        
                        if viewModel.isRecording {
                            Text("बोल्नुहोस्... (Speak now in Nepali)")
                                .font(.callout)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.green.opacity(0.5), lineWidth: 1)
                                )
                                .transition(.opacity)
                                .animation(.easeInOut, value: viewModel.isRecording)
                        } else if viewModel.isProcessing {
                            Text("प्रशोधन गर्दै... (Processing speech)")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                )
                                .transition(.opacity)
                                .animation(.easeInOut, value: viewModel.isProcessing)
                        }
                    }
                    .padding(.top, 5)
                }
                .padding(.vertical, 20)
                
                // Text divider
                Text("OR")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Nepali text input
                VStack(alignment: .leading) {
                    Text("Enter Nepali Text")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.leading, 5)
                    
                    TextEditor(text: $nepaliText)
                        .font(.system(size: 18))
                        .frame(height: 100)
                        .padding(10)
                        .background(Color.black.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .overlay(
                            Text(nepaliText.isEmpty ? "नेपाली मा टाइप गर्नुहोस्..." : "")
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                                .padding(.top, 16)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading),
                            alignment: .topLeading
                        )
                }
                .padding(.horizontal)
                
                // Translate button for text input
                Button(action: {
                    viewModel.translateText(nepaliText: nepaliText)
                }) {
                    HStack {
                        if viewModel.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 5)
                        }
                        Text(viewModel.isProcessing ? "Translating..." : "Translate Text")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .frame(width: 220)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                }
                .disabled(nepaliText.isEmpty || viewModel.isProcessing)
                .opacity(nepaliText.isEmpty || viewModel.isProcessing ? 0.6 : 1.0)
                .padding(.top, 5)
                
                // Results section
                VStack(spacing: 15) {
                    // Nepali transcription
                    if !viewModel.nepaliTranscription.isEmpty {
                        resultView(title: "Nepali Transcription", text: viewModel.nepaliTranscription)
                    }
                    
                    // English translation
                    if !viewModel.englishTranslation.isEmpty {
                        resultView(title: "English Translation", text: viewModel.englishTranslation)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.2))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .opacity(viewModel.nepaliTranscription.isEmpty ? 0 : 1)
                )
                .padding(.horizontal, 5)
                .animation(.easeInOut(duration: 0.3), value: viewModel.nepaliTranscription.isEmpty)
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var recordingStatusText: String {
        if viewModel.isRecording {
            return "Recording... \(String(format: "%.1f", viewModel.recordingDuration))s"
        } else if viewModel.isProcessing {
            return "Processing..."
        } else {
            return "Tap to record Nepali speech"
        }
    }
    
    private func resultView(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = text
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.horizontal, 5)
            
            Text(text)
                .font(.system(size: 18, weight: .regular))
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                )
                .background(Color.black.opacity(0.7))
                .cornerRadius(12)
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.15), radius: 1, x: 0, y: 0)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    ContentView()
}
