import UIKit
import SnapKit

@MainActor
final class SessionViewController: UIViewController {
    private let viewModel: SessionViewModel

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let stateLabel = UILabel()
    private let connectionLabel = UILabel()
    private let errorLabel = UILabel()
    private let summaryLabel = UILabel()
    private let transcriptTitleLabel = UILabel()
    private let transcriptView = UITextView()
    private let logTitleLabel = UILabel()
    private let logView = UITextView()
    private let messageField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let connectButton = UIButton(type: .system)
    private let startButton = UIButton(type: .system)
    private let reconnectButton = UIButton(type: .system)
    private let endButton = UIButton(type: .system)
    private let clearHistoryButton = UIButton(type: .system)

    convenience init() {
        self.init(viewModel: SessionViewModel(environment: .live()))
    }

    init(viewModel: SessionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AI Tutor"
        view.backgroundColor = .systemBackground
        setupUI()
        bindViewModel()
        render(viewModel.currentState)
        AppLogger.debug("SessionViewController loaded", category: .session)
    }

    private func setupUI() {
        titleLabel.text = "English Speaking Tutor"
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0

        subtitleLabel.text = "Speak or type a short answer. The tutor gives one focused correction and one follow-up."
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.numberOfLines = 0

        stateLabel.font = .preferredFont(forTextStyle: .headline)
        stateLabel.adjustsFontForContentSizeCategory = true
        stateLabel.numberOfLines = 0

        connectionLabel.font = .preferredFont(forTextStyle: .footnote)
        connectionLabel.textColor = .secondaryLabel
        connectionLabel.adjustsFontForContentSizeCategory = true
        connectionLabel.numberOfLines = 0

        errorLabel.font = .preferredFont(forTextStyle: .footnote)
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        summaryLabel.font = .preferredFont(forTextStyle: .caption1)
        summaryLabel.textColor = .secondaryLabel
        summaryLabel.numberOfLines = 0
        summaryLabel.backgroundColor = .tertiarySystemBackground
        summaryLabel.layer.cornerRadius = 10
        summaryLabel.layer.masksToBounds = true

        transcriptTitleLabel.text = "Transcript"
        transcriptTitleLabel.font = .preferredFont(forTextStyle: .headline)
        transcriptTitleLabel.adjustsFontForContentSizeCategory = true

        transcriptView.isEditable = false
        transcriptView.isScrollEnabled = true
        transcriptView.layer.cornerRadius = 12
        transcriptView.backgroundColor = .tertiarySystemBackground
        transcriptView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        transcriptView.font = .preferredFont(forTextStyle: .callout)
        transcriptView.adjustsFontForContentSizeCategory = true

        logTitleLabel.text = "Debug Log"
        logTitleLabel.font = .preferredFont(forTextStyle: .headline)
        logTitleLabel.adjustsFontForContentSizeCategory = true

        logView.isEditable = false
        logView.isScrollEnabled = true
        logView.layer.cornerRadius = 12
        logView.backgroundColor = .secondarySystemBackground
        logView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)

        messageField.placeholder = "Type fallback message"
        messageField.borderStyle = .roundedRect
        messageField.autocorrectionType = .yes
        messageField.autocapitalizationType = .sentences
        messageField.returnKeyType = .send
        messageField.addTarget(self, action: #selector(onSendText), for: .editingDidEndOnExit)

        configurePrimary(connectButton, title: "Connect")
        configurePrimary(startButton, title: "Start")
        configureSecondary(reconnectButton, title: "Reconnect")
        configureSecondary(endButton, title: "End")
        configureSecondary(clearHistoryButton, title: "Clear")
        configureSecondary(sendButton, title: "Send")

        connectButton.addTarget(self, action: #selector(onConnect), for: .touchUpInside)
        startButton.addTarget(self, action: #selector(onStart), for: .touchUpInside)
        reconnectButton.addTarget(self, action: #selector(onReconnect), for: .touchUpInside)
        endButton.addTarget(self, action: #selector(onEnd), for: .touchUpInside)
        clearHistoryButton.addTarget(self, action: #selector(onClearHistory), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(onSendText), for: .touchUpInside)

        let primaryButtons = UIStackView(arrangedSubviews: [connectButton, startButton])
        primaryButtons.axis = .horizontal
        primaryButtons.spacing = 10
        primaryButtons.distribution = .fillEqually

        let secondaryButtons = UIStackView(arrangedSubviews: [reconnectButton, endButton, clearHistoryButton])
        secondaryButtons.axis = .horizontal
        secondaryButtons.spacing = 8
        secondaryButtons.distribution = .fillEqually

        let textInputStack = UIStackView(arrangedSubviews: [messageField, sendButton])
        textInputStack.axis = .horizontal
        textInputStack.spacing = 8
        textInputStack.alignment = .fill
        messageField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        sendButton.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            stateLabel,
            connectionLabel,
            errorLabel,
            primaryButtons,
            secondaryButtons,
            textInputStack,
            summaryLabel,
            transcriptTitleLabel,
            transcriptView,
            logTitleLabel,
            logView
        ])
        stack.axis = .vertical
        stack.spacing = 10

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stack)

        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        stack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(14)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        logView.snp.makeConstraints { make in
            make.height.equalTo(130)
        }

        transcriptView.snp.makeConstraints { make in
            make.height.equalTo(150)
        }
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
    }

    private func render(_ state: SessionViewState) {
        stateLabel.text = state.statusText
        connectionLabel.text = state.connectionText
        summaryLabel.text = "  \(state.latestSummaryText)  "
        transcriptView.text = state.transcriptText
        logView.text = state.logText
        errorLabel.text = state.errorText
        errorLabel.isHidden = state.errorText == nil

        connectButton.isEnabled = state.isConnectEnabled
        startButton.isEnabled = state.isStartEnabled
        reconnectButton.isEnabled = state.isReconnectEnabled
        endButton.isEnabled = state.isEndEnabled
        clearHistoryButton.isEnabled = state.isClearHistoryEnabled
        messageField.isEnabled = state.isTextInputEnabled
        sendButton.isEnabled = state.isTextInputEnabled

        [connectButton, startButton, reconnectButton, endButton, clearHistoryButton, sendButton].forEach { button in
            button.alpha = button.isEnabled ? 1.0 : 0.45
        }

        let range = NSRange(location: max(logView.text.count - 1, 0), length: 0)
        logView.scrollRangeToVisible(range)
        let transcriptRange = NSRange(location: max(transcriptView.text.count - 1, 0), length: 0)
        transcriptView.scrollRangeToVisible(transcriptRange)
    }

    private func configurePrimary(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.layer.cornerRadius = 12
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }

    private func configureSecondary(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.tintColor = .systemBlue
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
    }

    @objc private func onConnect() {
        Task { await viewModel.connect() }
    }

    @objc private func onStart() {
        Task { await viewModel.startSession() }
    }

    @objc private func onReconnect() {
        Task { await viewModel.reconnect() }
    }

    @objc private func onEnd() {
        Task { await viewModel.endSession() }
    }

    @objc private func onSendText() {
        let text = messageField.text ?? ""
        messageField.text = ""
        Task { await viewModel.sendText(text) }
    }

    @objc private func onClearHistory() {
        viewModel.clearHistory()
    }
}
