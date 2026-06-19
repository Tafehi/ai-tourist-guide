import SwiftUI

struct VoiceInputButton: View {
    @Binding var text: String
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var isAuthorized = false

    var body: some View {
        Button(action: toggleRecording) {
            Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                .font(.body)
                .foregroundStyle(speechRecognizer.isRecording ? .red : .accentColor)
                .symbolEffect(.pulse, isActive: speechRecognizer.isRecording)
        }
        .buttonStyle(.plain)
        .task {
            isAuthorized = await speechRecognizer.requestAuthorization()
        }
        .disabled(!isAuthorized)
        .onChange(of: speechRecognizer.transcript) { _, newValue in
            if !newValue.isEmpty {
                text = newValue
            }
        }
    }

    private func toggleRecording() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
        } else {
            speechRecognizer.startRecording()
        }
    }
}
