import Foundation
import Speech
import AVFoundation

/// SFSpeechRecognizer 封装：权限请求、录音、语音辨识。
/// 录音过程透过 AsyncStream 推送部分辨识结果，结束录音时推送最终完整文字。
class SpeechRecognizer: ObservableObject {
    /// 繁体中文语音辨识器
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-TW"))

    /// 录音引擎
    private let audioEngine = AVAudioEngine()

    /// 当前辨识任务
    private var recognitionTask: SFSpeechRecognitionTask?

    /// 当前辨识请求
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    /// AsyncStream 接续（用于推送辨识结果）
    private var continuation: AsyncStream<String>.Continuation?

    /// 是否已授权语音辨识
    @Published var isAuthorized: Bool = false

    /// 是否正在录音
    @Published var isRecording: Bool = false

    /// 辨识结果串流
    private var resultStream: AsyncStream<String>?

    init() {
        // 检查初始授权状态
        checkAuthorizationStatus()
    }

    // MARK: - 权限

    /// 检查当前授权状态
    private func checkAuthorizationStatus() {
        let status = SFSpeechRecognizer.authorizationStatus()
        isAuthorized = (status == .authorized)
    }

    /// 请求语音辨识授权
    /// - Returns: 是否获得授权
    func requestAuthorization() async -> Bool {
        let status = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        let authorized = (status == .authorized)
        await MainActor.run {
            self.isAuthorized = authorized
        }
        return authorized
    }

    /// 检查语音辨识器是否可用
    var isAvailable: Bool {
        speechRecognizer?.isAvailable ?? false
    }

    // MARK: - 录音与辨识

    /// 开始录音并返回 AsyncStream 串流辨识结果。
    /// - Returns: AsyncStream<String> 推送部分与最终辨识文字
    func startRecording() throws -> AsyncStream<String> {
        // 清理旧状态
        stopRecording()

        let (stream, continuation) = AsyncStream<String>.makeStream()
        self.continuation = continuation
        self.resultStream = stream

        // 设定并启动录音
        try setupAndStartAudioEngine()
        try startRecognitionTask()

        return stream
    }

    /// 停止录音与辨识
    func stopRecording() {
        // 停止辨识任务
        recognitionTask?.finish()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // 停止录音引擎
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // 结束 AsyncStream
        continuation?.finish()
        continuation = nil

        isRecording = false
    }

    // MARK: - Private

    /// 设定并启动 AVAudioEngine
    private func setupAndStartAudioEngine() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
    }

    /// 启动语音辨识任务
    private func startRecognitionTask() throws {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognizerError.notAvailable
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognizerError.requestFailed
        }

        // 允许部分结果（提高即时性）
        recognitionRequest.shouldReportPartialResults = true
        // 不强制离线（允许线上辨识提高准确率）
        recognitionRequest.requiresOnDeviceRecognition = false

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.continuation?.yield("")
                return
            }

            if let result = result {
                let text = result.bestTranscription.formattedString

                if result.isFinal {
                    // 最终结果
                    self.continuation?.yield(text)
                    self.stopRecording()
                } else {
                    // 部分结果（即时推送）
                    self.continuation?.yield(text)
                }
            }
        }
    }
}

// MARK: - 错误类型

enum SpeechRecognizerError: LocalizedError {
    case notAvailable
    case requestFailed
    case audioEngineFailed
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return LocalizedString.speechNotAvailable
        case .requestFailed:
            return "語音辨識請求失敗"
        case .audioEngineFailed:
            return "錄音引擎啟動失敗"
        case .notAuthorized:
            return LocalizedString.speechPermissionDenied
        }
    }
}
