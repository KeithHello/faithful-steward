import SwiftUI

struct VoiceInputButton: View {
    @ObservedObject var viewModel: RecordTransactionViewModel

    var body: some View {
        VStack(spacing: 8) {
            Text("長按麥克風說話")
                .font(.caption)
                .foregroundColor(.textSecondary)

            ZStack {
                // 聲波動畫
                if viewModel.isRecording {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 2)
                            .scaleEffect(viewModel.isRecording ? 1.2 + CGFloat(i) * 0.3 : 1.0)
                            .opacity(viewModel.isRecording ? 0.5 - Double(i) * 0.15 : 0)
                            .animation(
                                .easeInOut(duration: 1.2).repeatForever().delay(Double(i) * 0.2),
                                value: viewModel.isRecording
                            )
                    }
                }

                Button(action: {}) {
                    Image(systemName: viewModel.isRecording ? "mic.fill" : "mic")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(viewModel.isRecording ? Color.errorRed : Color.brandPrimary)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.3)
                        .onChanged { _ in viewModel.startRecording() }
                        .onEnded { _ in viewModel.stopRecording() }
                )
            }
            .frame(height: 80)
        }
    }
}
