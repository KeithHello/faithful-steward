import Speech
import AVFoundation
import Combine

/// SFSpeechRecognizer 封裝（權限、錄音、辨識）
/// 對應 architecture 圖中的 SpeechRecognizer
final class SpeechRecognizer: NSObject, ObservableObject {
    private let speechRecognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let locale = Locale(identifier: "zh-TW")

    @Published var isRecording = false
    @Published var isAuthorized = false

    override init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        super.init()
    }

    func requestAuthorization() async -> Bool {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        isAuthorized = status == .authorized
        return isAuthorized
    }

    func startRecording() -> AsyncStream<String> {
        AsyncStream { continuation in
            guard isAuthorized else {
                continuation.finish()
                return
            }

            audioEngine = AVAudioEngine()
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true

            recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
                if let result = result {
                    continuation.yield(result.bestTranscription.formattedString)
                }
                if error != nil || (result?.isFinal ?? false) {
                    continuation.finish()
                }
            }

            // 啟動錄音
            let inputNode = audioEngine?.inputNode
            let recordingFormat = inputNode?.outputFormat(forBus: 0)
            inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }

            audioEngine?.prepare()
            try? audioEngine?.start()
            isRecording = true
        }
    }

    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        audioEngine = nil
        recognitionTask = nil
        isRecording = false
    }
}
