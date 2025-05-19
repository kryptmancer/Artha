//
//  VoiceWaveformView.swift
//  Artha
//
//  Created for audio recording visualization
//

import SwiftUI

struct VoiceWaveformView: View {
    let isRecording: Bool
    let duration: TimeInterval
    
    private let numberOfBars = 30
    private let minBarHeight: CGFloat = 3
    private let maxBarHeight: CGFloat = 30
    
    @State private var heights: [CGFloat] = []
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<numberOfBars, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white)
                    .frame(width: 3, height: heights.count > index ? heights[index] : minBarHeight)
                    .animation(.spring(), value: heights)
            }
        }
        .frame(height: maxBarHeight)
        .onAppear {
            initializeHeights()
            startAnimationIfNeeded()
        }
        .onChange(of: isRecording) { newValue in
            if newValue {
                startAnimationIfNeeded()
            } else {
                stopAnimation()
                initializeHeights()
            }
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func initializeHeights() {
        heights = Array(repeating: minBarHeight, count: numberOfBars)
    }
    
    private func startAnimationIfNeeded() {
        guard isRecording else { return }
        
        // If timer is already running, no need to start another one
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                updateHeights()
            }
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateHeights() {
        var newHeights: [CGFloat] = []
        
        for _ in 0..<numberOfBars {
            // Generate random heights to simulate audio waveform
            let randomValue = CGFloat.random(in: 0.1...1.0)
            let height = minBarHeight + (maxBarHeight - minBarHeight) * randomValue
            newHeights.append(height)
        }
        
        heights = newHeights
    }
} 