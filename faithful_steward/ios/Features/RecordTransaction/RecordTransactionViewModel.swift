import Foundation
import Combine

@MainActor
final class RecordTransactionViewModel: ObservableObject {
    private let dataProvider: DataProvider
    private let speechRecognizer: SpeechRecognizer

    @Published var amountText = ""
    @Published var parsedAmount: Double?
    @Published var selectedCategory: Category?
    @Published var isRecording = false
    @Published var voiceResultText = ""
    @Published var errorMessage: String?
    @Published var showConfirmDialog = false
    @Published var shouldShowToast = false
    @Published var toastMessage = ""

    private var cancellables = Set<AnyCancellable>()

    var canConfirm: Bool {
        (parsedAmount ?? 0) > 0 && selectedCategory != nil
    }

    init(dataProvider: DataProvider, speechRecognizer: SpeechRecognizer = SpeechRecognizer()) {
        self.dataProvider = dataProvider
        self.speechRecognizer = speechRecognizer

        // Auto-parse amount text
        $amountText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.parsedAmount = AmountParser.parse(text)
                self?.errorMessage = nil
            }
            .store(in: &cancellables)
    }

    func selectCategory(_ category: Category) {
        selectedCategory = category
        errorMessage = nil
    }

    func startRecording() {
        Task {
            guard await speechRecognizer.requestAuthorization() else {
                errorMessage = "請至設定開啟麥克風權限"
                return
            }
            isRecording = true
            for await text in speechRecognizer.startRecording() {
                voiceResultText = text
            }
        }
    }

    func stopRecording() {
        speechRecognizer.stopRecording()
        isRecording = false

        guard !voiceResultText.isEmpty else { return }
        let result = SpeechParser.parse(voiceResultText)
        if let amount = result.amount { parsedAmount = amount; amountText = String(Int(amount)) }
        if let category = result.category { selectedCategory = category }
        if !result.hasAmount && !result.hasCategory {
            errorMessage = "未偵測到金額與分類，請手動輸入"
        }
    }

    func submitTransaction(note: String? = nil) throws {
        guard let amount = parsedAmount, amount > 0 else {
            throw ValidationError.invalidAmount
        }
        guard let category = selectedCategory else {
            throw ValidationError.noCategory
        }

        let method: InputMethod = voiceResultText.isEmpty ? .text : .voice
        try dataProvider.addTransaction(amount: amount, category: category, note: note, method: method)
        clearInput()
        toastMessage = "記帳成功"
        shouldShowToast = true
    }

    func clearInput() {
        amountText = ""
        parsedAmount = nil
        selectedCategory = nil
        voiceResultText = ""
        errorMessage = nil
    }
}

enum ValidationError: LocalizedError {
    case invalidAmount, noCategory

    var errorDescription: String? {
        switch self {
        case .invalidAmount: return "請輸入有效金額"
        case .noCategory: return "請選擇分類"
        }
    }
}
