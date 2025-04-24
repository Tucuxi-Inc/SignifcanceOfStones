import SwiftUI

struct RecordingIndicatorView: View {
    let duration: TimeInterval
    
    @State private var isAnimating = false
    @State private var pulseSize = false
    
    var body: some View {
        ZStack {
            // Pulsating background
            Circle()
                .fill(Color.red.opacity(0.3))
                .frame(width: 36, height: 36)
                .scaleEffect(isAnimating ? 1.3 : 1.0)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)
            
            // Second pulse layer for more visibility
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 28, height: 28)
                .scaleEffect(pulseSize ? 1.2 : 0.9)
                .animation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: pulseSize)
            
            // Solid core to ensure visibility
            Circle()
                .fill(Color.red.opacity(0.7))
                .frame(width: 20, height: 20)
            
            // Microphone icon
            Image(systemName: "mic.fill")
                .foregroundColor(.white)
                .font(.system(size: 12))
                .offset(y: -1)
            
            // Recording time display
            VStack {
                Spacer()
                Text(formatDuration(duration))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(3)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(3)
                    .offset(y: 18)
            }
        }
        .onAppear {
            isAnimating = true
            // Delay second animation for effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                pulseSize = true
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%01d:%02d", minutes, seconds)
    }
}

// Recording status view that shows during active recording
struct RecordingStatusView: View {
    let text: String
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Animated recording indicator
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
                .opacity(isAnimating ? 0.5 : 1)
                .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnimating)
            
            // Live transcription text
            Text(text.isEmpty ? "Listening..." : text)
                .font(.callout)
                .foregroundColor(.primary.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 20) {
        RecordingIndicatorView(duration: 12.5)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        
        RecordingStatusView(text: "Hello, how are you today?")
        
        RecordingStatusView(text: "")
    }
    .padding()
} 