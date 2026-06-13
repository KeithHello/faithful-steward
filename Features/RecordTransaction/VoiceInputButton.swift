import SwiftUI

/// 长按录音按钮：按下触发录音、显示声波动画、松开停止录音并回传辨识结果。
struct VoiceInputButton: View {
    /// 是否正在录音
    let isRecording: Bool
    /// 辨识结果回调
    let onStartRecording: () -> Void
    /// 停止录音回调
    let onStopRecording: () -> Void

    /// 声波动画相关状态
    @State private var waveScale: CGFloat = 1.0
    @State private var waveOpacity: Double = 0.6
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 8) {
            // 声波动画环
            ZStack {
                // 外层波纹
                Circle()
                    .stroke(Color.blue.opacity(waveOpacity * 0.3), lineWidth: 3)
                    .frame(width: 80, height: 80)
                    .scaleEffect(waveScale)
                    .opacity(isRecording ? waveOpacity : 0)

                Circle()
                    .stroke(Color.blue.opacity(waveOpacity * 0.2), lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .scaleEffect(waveScale * 1.3)
                    .opacity(isRecording ? waveOpacity * 0.6 : 0)

                // 内圈麦克风按钮
                Circle()
                    .fill(isRecording ? Color.red : Color.blue)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    .shadow(color: (isRecording ? Color.red : Color.blue).opacity(0.4),
                            radius: 8, x: 0, y: 4)
            }
            .frame(width: 100, height: 100)

            // 提示文字
            Text(isRecording ? LocalizedString.recording : LocalizedString.recordingHint)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startWaveAnimation()
            } else {
                stopWaveAnimation()
            }
        }
        .simultaneousGesture(dragGesture)
        .accessibilityLabel(isRecording ? "停止錄音" : "開始錄音")
    }

    // MARK: - 手势

    /// 长按手势：按下 → 开始录音，松开 → 停止录音
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isRecording {
                    onStartRecording()
                }
            }
            .onEnded { _ in
                if isRecording {
                    onStopRecording()
                }
            }
    }

    // MARK: - 声波动画

    private func startWaveAnimation() {
        waveScale = 1.0
        waveOpacity = 0.6

        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                waveScale = waveScale == 1.0 ? 1.2 : 1.0
                waveOpacity = waveOpacity == 0.6 ? 0.2 : 0.6
            }
        }
    }

    private func stopWaveAnimation() {
        timer?.invalidate()
        timer = nil
        withAnimation(.easeOut(duration: 0.3)) {
            waveScale = 1.0
            waveOpacity = 0
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        VoiceInputButton(
            isRecording: false,
            onStartRecording: {},
            onStopRecording: {}
        )
        .padding()

        VoiceInputButton(
            isRecording: true,
            onStartRecording: {},
            onStopRecording: {}
        )
        .padding()
    }
}
