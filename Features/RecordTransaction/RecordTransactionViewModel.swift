import Foundation
import Combine
import SwiftUI

/// 记账功能 ViewModel：管理金额输入、分类选择、语音辨识流程与提交流程。
@MainActor
class RecordTransactionViewModel: ObservableObject {
    // MARK: - 依赖

    private let dataProvider: DataProvider
    private let speechRecognizer: SpeechRecognizer

    // MARK: - 发布属性（View 绑定）

    /// 金额输入栏文字
    @Published var amountText: String = ""

    /// 解析后的金额（nil 表示无效或未输入）
    @Published var parsedAmount: Double? = nil

    /// 选中的分类
    @Published var selectedCategory: Category? = nil

    /// 是否正在录音
    @Published var isRecording: Bool = false

    /// 输入方式（explicitly tracked）
    @Published var inputMethod: InputMethod = .text

    /// 语音辨识结果文字（显示用）
    @Published var voiceResultText: String = ""

    /// 错误讯息（nil 表示无错误）
    @Published var errorMessage: String? = nil

    /// 是否显示确认弹窗
    @Published var showConfirmation: Bool = false

    /// 是否显示记账成功
    @Published var showSuccess: Bool = false

    // MARK: - 计算属性

    /// 是否可以点击确认（金额 > 0 且分类已选）
    var canConfirm: Bool {
        guard let amount = parsedAmount else { return false }
        return amount > 0 && selectedCategory != nil
    }

    /// 当前输入是否为语音模式
    var isVoiceMode: Bool {
        !voiceResultText.isEmpty
    }

    // MARK: - 初始化

    init(dataProvider: DataProvider, speechRecognizer: SpeechRecognizer = SpeechRecognizer()) {
        self.dataProvider = dataProvider
        self.speechRecognizer = speechRecognizer
        setupAmountTextBinding()
    }

    // MARK: - 文字栏监听

    /// 监听 amountText 变化，即时解析金额
    private func setupAmountTextBinding() {
        // 使用 Combine 的 @Published 投影来监听
        $amountText
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.parseAmount(text)
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    /// 解析金额文字
    private func parseAmount(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            parsedAmount = nil
            errorMessage = nil
            return
        }

        if let amount = AmountParser.parse(text) {
            parsedAmount = amount
            errorMessage = nil
        } else {
            // 若包含非数字内容且非中文数字，不立即报错（使用者可能正在输入）
            parsedAmount = nil
        }
    }

    // MARK: - 文字输入流程

    /// 处理文字栏提交
    func onTextSubmit() {
        let trimmed = amountText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if let amount = AmountParser.parse(trimmed) {
            parsedAmount = amount
            amountText = String(format: "%.0f", amount)
            inputMethod = .text
            errorMessage = nil
        } else {
            errorMessage = LocalizedString.amountParsingFailed
            parsedAmount = nil
        }
    }

    // MARK: - 语音输入流程

    /// 开始录音
    func startRecording() {
        Task {
            let authorized = await speechRecognizer.requestAuthorization()
            if !authorized {
                errorMessage = LocalizedString.speechPermissionDenied
                return
            }

            do {
                voiceResultText = ""
                errorMessage = nil
                isRecording = true

                let stream = try speechRecognizer.startRecording()

                // 以 Task 消费串流，收集所有辨识结果
                Task {
                    var lastText = ""
                    for await text in stream {
                        lastText = text
                        // 更新即时辨识结果
                        await MainActor.run {
                            self.voiceResultText = text
                        }
                    }
                    // 串流结束后处理最终结果
                    if !lastText.isEmpty {
                        await MainActor.run {
                            self.processVoiceResult(lastText)
                        }
                    }
                    await MainActor.run {
                        self.isRecording = false
                    }
                }
            } catch {
                isRecording = false
                errorMessage = error.localizedDescription
            }
        }
    }

    /// 停止录音
    func stopRecording() {
        speechRecognizer.stopRecording()
        isRecording = false
    }

    /// 处理语音辨识最终结果
    func processVoiceResult(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = LocalizedString.speechNoResult
            return
        }

        let result = SpeechParser.parse(text)
        voiceResultText = text
        inputMethod = .voice

        if let amount = result.amount, amount > 0 {
            parsedAmount = amount
            amountText = String(format: "%.0f", amount)
        } else {
            errorMessage = LocalizedString.speechNoAmount
        }

        if let category = result.category {
            selectedCategory = category
        }
    }

    // MARK: - 提交流程

    /// 显示确认弹窗前验证
    func requestConfirmation() {
        guard canConfirm else {
            if parsedAmount == nil || (parsedAmount ?? 0) <= 0 {
                errorMessage = LocalizedString.amountMustBePositive
            } else if selectedCategory == nil {
                errorMessage = LocalizedString.categoryNotSelected
            }
            return
        }
        errorMessage = nil
        showConfirmation = true
    }

    /// 提交交易纪录
    func submitTransaction() {
        guard let amount = parsedAmount, amount > 0,
              let category = selectedCategory else {
            return
        }

        do {
            let method: InputMethod = inputMethod
            try dataProvider.addTransaction(
                amount: amount,
                category: category,
                note: nil,
                method: method
            )
            clearInput()
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 清除所有输入状态
    func clearInput() {
        amountText = ""
        parsedAmount = nil
        selectedCategory = nil
        voiceResultText = ""
        isRecording = false
        inputMethod = .text
        errorMessage = nil
        showConfirmation = false
    }
}
