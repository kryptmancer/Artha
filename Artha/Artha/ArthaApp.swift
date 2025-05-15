//
//  ArthaApp.swift
//  Artha
//
//  Created by Aryan Kafle on 14/05/2025.
//

import SwiftUI
import AVFoundation

@main
struct ArthaApp: App {
    @State private var micPermissionGranted = false
    @State private var isShowingPermissionAlert = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app view if permission is granted
                if micPermissionGranted {
                    ContentView()
                } else {
                    // Permission request view
                    VStack(spacing: 20) {
                        Text("Artha needs microphone access")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("This app transcribes speech in real-time and requires microphone access to function.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                        
                        Button(action: requestMicrophonePermission) {
                            Text("Grant Microphone Access")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.edgesIgnoringSafeArea(.all))
                    .alert(isPresented: $isShowingPermissionAlert) {
                        Alert(
                            title: Text("Microphone Access Denied"),
                            message: Text("Please enable microphone access in Settings to use Artha."),
                            primaryButton: .default(Text("Open Settings"), action: openSettings),
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
            .onAppear {
                checkMicrophonePermission()
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private func checkMicrophonePermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            micPermissionGranted = true
        case .denied:
            micPermissionGranted = false
            isShowingPermissionAlert = true
        case .undetermined:
            requestMicrophonePermission()
        @unknown default:
            requestMicrophonePermission()
        }
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    self.micPermissionGranted = true
                } else {
                    self.isShowingPermissionAlert = true
                }
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
