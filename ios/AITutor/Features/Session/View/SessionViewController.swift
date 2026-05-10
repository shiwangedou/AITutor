import UIKit
import SnapKit

@MainActor
final class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let environment: AppEnvironment
    private var records: [SessionRecord] = []
    private let aiChatButton = UIButton(type: .system)
    private let customGoalButton = UIButton(type: .system)
    private let wordsPracticeButton = UIButton(type: .system)
    private let historyLabel = UILabel()
    private let historyTableView = UITableView(frame: .zero, style: .plain)
    private let stack = UIStackView()
    private let drawerDimmingView = UIView()
    private let drawerView = UIView()
    private let drawerStack = UIStackView()
    private var drawerLeadingConstraint: Constraint?
    private var isDrawerOpen = false

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "AITutor-English Coach"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(onToggleDrawer)
        )
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        render()
    }

    private func setupUI() {
        stack.axis = .vertical
        stack.spacing = 14
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        configurePrimaryButton(aiChatButton, title: "AI Chat", subtitle: "Start a real-time speaking session")
        aiChatButton.addTarget(self, action: #selector(onAIChat), for: .touchUpInside)
        configureSecondaryButton(customGoalButton, title: "Custom Goal", subtitle: "Set a goal, then jump into chat")
        customGoalButton.addTarget(self, action: #selector(onCustomGoal), for: .touchUpInside)
        configureSecondaryButton(wordsPracticeButton, title: "Words Practice", subtitle: "Practice target words with sentence feedback")
        wordsPracticeButton.addTarget(self, action: #selector(onWordsPractice), for: .touchUpInside)
        historyLabel.text = "History"
        historyLabel.font = .preferredFont(forTextStyle: .headline)
        historyLabel.adjustsFontForContentSizeCategory = true

        historyTableView.dataSource = self
        historyTableView.delegate = self
        historyTableView.separatorStyle = .singleLine
        historyTableView.backgroundColor = .systemBackground
        historyTableView.register(HomeHistoryCell.self, forCellReuseIdentifier: HomeHistoryCell.reuseID)
        historyTableView.rowHeight = UITableView.automaticDimension
        historyTableView.estimatedRowHeight = 78
        historyTableView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(260)
        }

        stack.addArrangedSubview(aiChatButton)
        stack.addArrangedSubview(customGoalButton)
        stack.addArrangedSubview(wordsPracticeButton)
        stack.addArrangedSubview(historyLabel)
        stack.addArrangedSubview(historyTableView)

        setupDrawer()
    }

    private func render() {
        records = environment.sessionStorage.loadRecentSessions()
        historyLabel.text = records.isEmpty ? "History (No sessions yet)" : "History (\(records.count))"
        historyTableView.reloadData()
    }

    private func configurePrimaryButton(_ button: UIButton, title: String, subtitle: String) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.subtitle = subtitle
        config.cornerStyle = .large
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        button.configuration = config
        button.contentHorizontalAlignment = .leading
    }

    private func configureSecondaryButton(_ button: UIButton, title: String, subtitle: String) {
        var config = UIButton.Configuration.gray()
        config.title = title
        config.subtitle = subtitle
        config.cornerStyle = .large
        config.baseBackgroundColor = .secondarySystemBackground
        config.baseForegroundColor = .label
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        button.configuration = config
        button.contentHorizontalAlignment = .leading
    }

    private func setupDrawer() {
        drawerDimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        drawerDimmingView.alpha = 0
        drawerDimmingView.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onCloseDrawer))
        drawerDimmingView.addGestureRecognizer(tap)

        drawerView.backgroundColor = .systemBackground
        drawerView.layer.shadowColor = UIColor.black.cgColor
        drawerView.layer.shadowOpacity = 0.18
        drawerView.layer.shadowRadius = 12
        drawerView.layer.shadowOffset = CGSize(width: 2, height: 0)

        drawerStack.axis = .vertical
        drawerStack.spacing = 8

        let customizeButton = makeDrawerActionButton("Customize", #selector(onCustomize))
        let diagnosticsButton = makeDrawerActionButton("Diagnostics", #selector(onDiagnostics))
        let privacyButton = makeDrawerActionButton("Privacy", #selector(onPrivacy))
        let clearHistoryButton = makeDrawerActionButton("Clear History", #selector(onClearHistory))
        let resetProfileButton = makeDrawerActionButton("Reset Learning Profile", #selector(onResetLearningProfile))
        drawerStack.addArrangedSubview(customizeButton)
        drawerStack.addArrangedSubview(diagnosticsButton)
        drawerStack.addArrangedSubview(privacyButton)
        drawerStack.addArrangedSubview(makeDrawerSeparator())
        drawerStack.addArrangedSubview(clearHistoryButton)
        drawerStack.addArrangedSubview(resetProfileButton)

        view.addSubview(drawerDimmingView)
        view.addSubview(drawerView)
        drawerView.addSubview(drawerStack)

        drawerDimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        drawerView.snp.makeConstraints { make in
            make.top.bottom.equalTo(view.safeAreaLayoutGuide)
            make.width.equalTo(250)
            drawerLeadingConstraint = make.leading.equalToSuperview().offset(-260).constraint
        }
        drawerStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(12)
        }
    }

    private func makeDrawerActionButton(_ title: String, _ action: Selector) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = .label
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 6, bottom: 10, trailing: 6)
        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeDrawerSeparator() -> UIView {
        let line = UIView()
        line.backgroundColor = .separator
        line.snp.makeConstraints { make in
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        return line
    }

    private func setDrawer(open: Bool, animated: Bool) {
        isDrawerOpen = open
        drawerLeadingConstraint?.update(offset: open ? 0 : -260)
        if open {
            drawerDimmingView.isHidden = false
        }
        let animations = {
            self.drawerDimmingView.alpha = open ? 1 : 0
            self.view.layoutIfNeeded()
        }
        let completion: (Bool) -> Void = { _ in
            if !open {
                self.drawerDimmingView.isHidden = true
            }
        }
        if animated {
            UIView.animate(withDuration: 0.22, animations: animations, completion: completion)
        } else {
            animations()
            completion(true)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(records.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeHistoryCell.reuseID, for: indexPath) as? HomeHistoryCell ?? HomeHistoryCell(style: .default, reuseIdentifier: HomeHistoryCell.reuseID)
        if records.isEmpty {
            cell.configureEmptyState("No history yet. Finish one chat session to see summaries here.")
            cell.onTapSummary = nil
            return cell
        }

        let record = records[indexPath.row]
        let title = record.learningProfile?.goalLine == "No custom goal" ? (record.learningProfile?.summaryLine ?? record.tutorSubject) : record.learningProfile?.goalLine ?? record.tutorSubject
        let snippet = (record.aiSummary ?? record.summary).trimmingCharacters(in: .whitespacesAndNewlines)
        cell.configure(
            title: title,
            snippet: snippet.isEmpty ? "No summary text available." : snippet,
            metadata: "\(AppDateFormatter.shortDateTime(record.endedAt)) · \(Int(record.durationSeconds))s"
        )
        cell.onTapSummary = { [weak self] in
            self?.openSummary(for: record)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !records.isEmpty else { return }
        let record = records[indexPath.row]
        let profile = record.learningProfile ?? .default
        let resumeContext = SessionResumeContext.make(from: record)
        navigationController?.pushViewController(
            SessionViewController(
                environment: environment,
                learningProfile: profile,
                autoConnect: true,
                resumeContext: resumeContext,
                resumeRecord: record
            ),
            animated: true
        )
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard !records.isEmpty else { return nil }
        let record = records[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }
            do {
                try self.environment.sessionStorage.deleteSession(id: record.id)
                self.records.removeAll { $0.id == record.id }
                if self.records.isEmpty {
                    tableView.reloadData()
                } else {
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
                self.historyLabel.text = self.records.isEmpty ? "History (No sessions yet)" : "History (\(self.records.count))"
                completion(true)
            } catch {
                completion(false)
            }
        }
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }

    @objc private func onToggleDrawer() {
        setDrawer(open: !isDrawerOpen, animated: true)
    }

    @objc private func onCloseDrawer() {
        setDrawer(open: false, animated: true)
    }

    @objc private func onAIChat() {
        setDrawer(open: false, animated: true)
        let profile = environment.learningProfileStore.loadDefaultProfile()
        navigationController?.pushViewController(SessionViewController(environment: environment, learningProfile: profile, autoConnect: true), animated: true)
    }

    @objc private func onCustomGoal() {
        setDrawer(open: false, animated: true)
        let alert = UIAlertController(title: "Custom Goal", message: "Input a goal for this chat session.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "e.g. Practice hotel check-in conversation"
            textField.text = self.environment.learningProfileStore.loadDefaultProfile().customGoal
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Start Chat", style: .default, handler: { [weak self, weak alert] _ in
            guard let self else { return }
            var profile = self.environment.learningProfileStore.loadDefaultProfile()
            profile.customGoal = alert?.textFields?.first?.text
            profile = profile.normalized()
            self.environment.learningProfileStore.saveDefaultProfile(profile)
            self.navigationController?.pushViewController(
                SessionViewController(environment: self.environment, learningProfile: profile, autoConnect: true),
                animated: true
            )
        }))
        present(alert, animated: true)
    }

    @objc private func onWordsPractice() {
        setDrawer(open: false, animated: true)
        navigationController?.pushViewController(WordsPracticeViewController(environment: environment), animated: true)
    }

    @objc private func onCustomize() {
        setDrawer(open: false, animated: true)
        let editor = LearningProfileEditorViewController(
            profile: environment.learningProfileStore.loadDefaultProfile()
        ) { [weak self] profile in
            self?.environment.learningProfileStore.saveDefaultProfile(profile)
            self?.render()
        }
        let navigation = UINavigationController(rootViewController: editor)
        present(navigation, animated: true)
    }

    private func openSummary(for record: SessionRecord) {
        let summaryText = (record.aiSummary ?? record.summary).trimmingCharacters(in: .whitespacesAndNewlines)
        let sheet = SessionSummarySheetViewController(
            titleText: record.learningProfile?.goalLine == "No custom goal" ? (record.learningProfile?.summaryLine ?? record.tutorSubject) : (record.learningProfile?.goalLine ?? record.tutorSubject),
            summaryText: summaryText.isEmpty ? "No summary available." : summaryText
        )
        let navigation = UINavigationController(rootViewController: sheet)
        if let presentation = navigation.sheetPresentationController {
            presentation.detents = [.medium(), .large()]
            presentation.prefersGrabberVisible = true
            presentation.preferredCornerRadius = 18
        }
        present(navigation, animated: true)
    }

    @objc private func onDiagnostics() {
        setDrawer(open: false, animated: true)
        navigationController?.pushViewController(DiagnosticsViewController(environment: environment), animated: true)
    }

    @objc private func onPrivacy() {
        setDrawer(open: false, animated: true)
        navigationController?.pushViewController(PrivacyViewController(), animated: true)
    }

    @objc private func onClearHistory() {
        setDrawer(open: false, animated: true)
        let alert = UIAlertController(
            title: "Clear History",
            message: "This will remove all local session records on this device.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive, handler: { [weak self] _ in
            try? self?.environment.sessionStorage.clear()
            self?.render()
        }))
        present(alert, animated: true)
    }

    @objc private func onResetLearningProfile() {
        setDrawer(open: false, animated: true)
        let alert = UIAlertController(
            title: "Reset Learning Profile",
            message: "Restore default learning mode, tutor style, difficulty, and goal?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { [weak self] _ in
            self?.environment.learningProfileStore.resetDefaultProfile()
        }))
        present(alert, animated: true)
    }
}

private struct PracticeWord {
    let text: String
    let meaning: String
    let sample: String
    let challengePrompt: String
    let expansionHint: String
}

@MainActor
private final class WordsPracticeViewController: UITableViewController {
    private let environment: AppEnvironment
    private let words: [PracticeWord] = [
        PracticeWord(
            text: "introduce",
            meaning: "to tell others who you are",
            sample: "Let me introduce myself.",
            challengePrompt: "Use \"introduce\" to greet a new teammate in one natural sentence.",
            expansionHint: "presentation"
        ),
        PracticeWord(
            text: "schedule",
            meaning: "a plan of activities and time",
            sample: "My interview schedule is full this week.",
            challengePrompt: "Use \"schedule\" to explain a busy day and suggest one free time slot.",
            expansionHint: "availability"
        ),
        PracticeWord(
            text: "reservation",
            meaning: "a booking made in advance",
            sample: "I have a hotel reservation for tonight.",
            challengePrompt: "Use \"reservation\" in a short check-in request at a hotel front desk.",
            expansionHint: "confirmation"
        ),
        PracticeWord(
            text: "improve",
            meaning: "to make something better",
            sample: "I want to improve my spoken English.",
            challengePrompt: "Use \"improve\" to describe a personal learning plan this month.",
            expansionHint: "progress"
        ),
        PracticeWord(
            text: "confident",
            meaning: "feeling sure and positive",
            sample: "I feel more confident after practice.",
            challengePrompt: "Use \"confident\" in a sentence before an interview or presentation.",
            expansionHint: "self-assured"
        )
    ]

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Words Practice"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PracticeWordCell")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        words.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let word = words[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "PracticeWordCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = word.text.capitalized
        content.secondaryText = "\(word.meaning)\nExample: \(word.sample)\nChallenge: \(word.challengePrompt)"
        content.secondaryTextProperties.numberOfLines = 3
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        startLivePractice(with: words[indexPath.row])
    }

    private func startLivePractice(with word: PracticeWord) {
        let defaultProfile = environment.learningProfileStore.loadDefaultProfile()
        let customGoal = "Words Practice: \(word.text) - \(word.meaning)"
        let profile = LearningProfile(
            learningMode: .pronunciationPractice,
            tutorStyle: defaultProfile.tutorStyle,
            difficulty: defaultProfile.difficulty,
            customGoal: customGoal
        ).normalized()
        let practiceRules = """
        Words Practice mode. Target word: "\(word.text)".
        Meaning: \(word.meaning).
        Example: \(word.sample).
        Challenge: \(word.challengePrompt).
        Suggested expansion word: \(word.expansionHint).
        For each learner turn, give:
        1) Score (0-10) focused on word usage and naturalness.
        2) One short correction.
        3) Better sentence.
        4) Next challenge question.
        Include one related expansion word each turn. Prioritize spoken practice.
        """
        let resumeContext = SessionResumeContext(
            sourceSessionID: nil,
            summary: practiceRules,
            aiSummary: nil,
            transcriptExcerpt: nil
        )
        let chat = SessionViewController(
            environment: environment,
            learningProfile: profile,
            autoConnect: true,
            chatSubtitle: word.text.capitalized,
            resumeContext: resumeContext.hasContent ? resumeContext : nil
        )
        navigationController?.pushViewController(chat, animated: true)
    }
}

private final class HomeHistoryCell: UITableViewCell {
    static let reuseID = "HomeHistoryCell"
    var onTapSummary: (() -> Void)?

    private let titleLabel = UILabel()
    private let snippetLabel = UILabel()
    private let metaLabel = UILabel()
    private let summaryButton = UIButton(type: .system)
    private let textStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .systemBackground

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 1
        snippetLabel.font = .preferredFont(forTextStyle: .subheadline)
        snippetLabel.textColor = .secondaryLabel
        snippetLabel.numberOfLines = 2
        metaLabel.font = .preferredFont(forTextStyle: .caption1)
        metaLabel.textColor = .tertiaryLabel

        var summaryConfig = UIButton.Configuration.plain()
        summaryConfig.image = UIImage(systemName: "text.page")
        summaryConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        summaryButton.configuration = summaryConfig
        summaryButton.tintColor = .systemBlue
        summaryButton.addTarget(self, action: #selector(onSummaryTapped), for: .touchUpInside)
        summaryButton.setContentHuggingPriority(.required, for: .horizontal)
        summaryButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        summaryButton.accessibilityLabel = "View summary"

        textStack.axis = .vertical
        textStack.spacing = 4
        [titleLabel, snippetLabel, metaLabel].forEach { textStack.addArrangedSubview($0) }

        let root = UIStackView(arrangedSubviews: [textStack, summaryButton])
        root.axis = .horizontal
        root.spacing = 12
        root.alignment = .center

        contentView.addSubview(root)
        root.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(title: String, snippet: String, metadata: String) {
        titleLabel.text = title
        snippetLabel.text = snippet
        metaLabel.text = metadata
        summaryButton.isHidden = false
        summaryButton.isEnabled = true
    }

    func configureEmptyState(_ message: String) {
        titleLabel.text = "No Sessions"
        snippetLabel.text = message
        metaLabel.text = ""
        summaryButton.isHidden = true
        summaryButton.isEnabled = false
    }

    @objc private func onSummaryTapped() {
        onTapSummary?()
    }
}

@MainActor
private final class SessionSummarySheetViewController: UIViewController {
    private let titleText: String
    private let summaryText: String
    private let textView = UITextView()

    init(titleText: String, summaryText: String) {
        self.titleText = titleText
        self.summaryText = summaryText
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Summary"
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 0
        titleLabel.text = titleText

        textView.isEditable = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.text = summaryText
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        let stack = UIStackView(arrangedSubviews: [titleLabel, textView])
        stack.axis = .vertical
        stack.spacing = 12
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        textView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(180)
        }
    }
}

@MainActor
final class SessionViewController: UIViewController, UITableViewDataSource {
    private enum TaskKind: Hashable {
        case sessionControl
        case voiceControl
        case textSend
    }

    private let viewModel: SessionViewModel
    private let autoConnect: Bool
    private let chatSubtitle: String?

    private let titleStatusDot = UIView()
    private let profileLabel = UILabel()
    private let stateLabel = UILabel()
    private let hintLabel = UILabel()
    private let errorLabel = UILabel()
    private let summaryView = UITextView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputContainer = UIView()
    private let messageField = UITextField()
    private let waveformView = VoiceWaveformView()
    private let sendButton = UIButton(type: .system)
    private let micButton = UIButton(type: .system)
    private let voiceModeMenuView = UIView()
    private let autoVoiceModeButton = UIButton(type: .system)
    private let manualVoiceModeButton = UIButton(type: .system)
    private let reconnectButton = UIButton(type: .system)
    private let endButton = UIButton(type: .system)
    private let rootStack = UIStackView()
    private var rootBottomConstraint: Constraint?
    private var messages: [ChatMessage] = []
    private var isVoiceInputMode = false
    private var didOpenVoiceModeMenu = false
    private var actionTasks: [TaskKind: Task<Void, Never>] = [:]
    private var transientErrorBanner: UIView?
    private var transientErrorLabel: UILabel?
    private var transientErrorHideTask: Task<Void, Never>?
    private var lastDisplayedErrorText: String?

    convenience init() {
        self.init(environment: .live(), learningProfile: .default, autoConnect: true)
    }

    init(
        environment: AppEnvironment,
        learningProfile: LearningProfile,
        autoConnect: Bool,
        chatSubtitle: String? = nil,
        resumeContext: SessionResumeContext? = nil,
        resumeRecord: SessionRecord? = nil
    ) {
        self.viewModel = SessionViewModel(
            environment: environment,
            learningProfile: learningProfile,
            resumeContext: resumeContext,
            resumeRecord: resumeRecord
        )
        self.autoConnect = autoConnect
        self.chatSubtitle = chatSubtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        super.init(nibName: nil, bundle: nil)
    }

    init(viewModel: SessionViewModel, autoConnect: Bool = false, chatSubtitle: String? = nil) {
        self.viewModel = viewModel
        self.autoConnect = autoConnect
        self.chatSubtitle = chatSubtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let chatSubtitle, !chatSubtitle.isEmpty {
            title = "AI Chat-\(chatSubtitle)"
        } else {
            title = "AI Chat"
        }
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupUI()
        bindViewModel()
        render(viewModel.currentState)
        if autoConnect {
            launchTask(kind: .sessionControl) { [weak self] in
                await self?.viewModel.connect()
            }
        }
        AppLogger.debug("Chat SessionViewController loaded", category: .session)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || navigationController?.isBeingDismissed == true {
            cancelAllActionTasks()
            launchTask(kind: .sessionControl) { [weak self] in
                await self?.viewModel.leaveChat()
            }
        }
    }

    private func setupNavigationBar() {
        let titleLabel = UILabel()
        if let chatSubtitle, !chatSubtitle.isEmpty {
            titleLabel.text = "AI Chat-\(chatSubtitle)"
        } else {
            titleLabel.text = "AI Chat"
        }
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label

        let statusContainer = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 18, height: 18)))
        statusContainer.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 18, height: 18))
        }
        titleStatusDot.layer.cornerRadius = 5
        titleStatusDot.backgroundColor = .systemGray3
        statusContainer.addSubview(titleStatusDot)
        titleStatusDot.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 10, height: 10))
        }

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, statusContainer])
        titleStack.axis = .horizontal
        titleStack.alignment = .center
        titleStack.spacing = 7
        navigationItem.titleView = titleStack
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "text.page"),
            style: .plain,
            target: self,
            action: #selector(onSummary)
        )
    }

    private func setupUI() {
        profileLabel.font = .preferredFont(forTextStyle: .subheadline)
        profileLabel.textColor = .secondaryLabel
        profileLabel.numberOfLines = 0
        stateLabel.font = .preferredFont(forTextStyle: .headline)
        stateLabel.isHidden = true
        hintLabel.font = .preferredFont(forTextStyle: .footnote)
        hintLabel.textColor = .secondaryLabel
        hintLabel.numberOfLines = 0
        errorLabel.font = .preferredFont(forTextStyle: .footnote)
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        summaryView.isEditable = false
        summaryView.isScrollEnabled = true
        summaryView.layer.cornerRadius = 12
        summaryView.backgroundColor = .secondarySystemBackground
        summaryView.font = .preferredFont(forTextStyle: .footnote)
        summaryView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.reuseID)
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(onDismissKeyboardTap))
        dismissTap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(dismissTap)

        messageField.placeholder = "Message"
        messageField.borderStyle = .none
        messageField.returnKeyType = .send
        messageField.addTarget(self, action: #selector(onSendText), for: .editingDidEndOnExit)

        waveformView.isHidden = true

        configureIconButton(micButton, systemName: "mic.fill", tintColor: .systemBlue)
        micButton.addTarget(self, action: #selector(onMicTapped), for: .touchUpInside)
        let micLongPress = UILongPressGestureRecognizer(target: self, action: #selector(onMicLongPressed(_:)))
        micButton.addGestureRecognizer(micLongPress)
        configureIconButton(sendButton, systemName: "arrow.up.circle.fill", tintColor: .systemBlue)
        configureSecondary(reconnectButton, title: "Reconnect")
        configureSecondary(endButton, title: "End")
        sendButton.addTarget(self, action: #selector(onSendText), for: .touchUpInside)
        reconnectButton.addTarget(self, action: #selector(onReconnect), for: .touchUpInside)
        endButton.addTarget(self, action: #selector(onEnd), for: .touchUpInside)

        profileLabel.isHidden = true
        hintLabel.isHidden = true
        let topStack = UIStackView(arrangedSubviews: [reconnectButton])
        topStack.axis = .vertical
        topStack.spacing = 6

        let inputStack = UIStackView(arrangedSubviews: [micButton, messageField, waveformView, sendButton])
        inputStack.axis = .horizontal
        inputStack.spacing = 10
        inputStack.alignment = .center
        micButton.setContentHuggingPriority(.required, for: .horizontal)
        sendButton.setContentHuggingPriority(.required, for: .horizontal)
        messageField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        waveformView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        inputContainer.backgroundColor = .secondarySystemBackground
        inputContainer.layer.cornerRadius = 22
        inputContainer.addSubview(inputStack)
        inputStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8))
        }

        rootStack.axis = .vertical
        rootStack.spacing = 10
        rootStack.addArrangedSubview(topStack)
        rootStack.addArrangedSubview(tableView)
        rootStack.addArrangedSubview(inputContainer)
        view.addSubview(rootStack)
        rootStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(12)
            rootBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).inset(12).constraint
        }
        inputContainer.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
        }
        setupVoiceModeMenu()
        setupKeyboardObservers()
    }

    private func setupVoiceModeMenu() {
        voiceModeMenuView.isHidden = true
        voiceModeMenuView.alpha = 0
        voiceModeMenuView.backgroundColor = .secondarySystemBackground
        voiceModeMenuView.layer.cornerRadius = 14
        voiceModeMenuView.layer.shadowColor = UIColor.black.cgColor
        voiceModeMenuView.layer.shadowOpacity = 0.16
        voiceModeMenuView.layer.shadowRadius = 12
        voiceModeMenuView.layer.shadowOffset = CGSize(width: 0, height: 4)

        configureVoiceModeButton(autoVoiceModeButton, title: "Auto Voice", systemName: "waveform.circle.fill")
        configureVoiceModeButton(manualVoiceModeButton, title: "Manual Voice", systemName: "mic.fill")
        autoVoiceModeButton.addTarget(self, action: #selector(onSelectAutoVoiceMode), for: .touchUpInside)
        manualVoiceModeButton.addTarget(self, action: #selector(onSelectManualVoiceMode), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [autoVoiceModeButton, manualVoiceModeButton])
        stack.axis = .vertical
        stack.spacing = 2
        voiceModeMenuView.addSubview(stack)
        view.addSubview(voiceModeMenuView)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        voiceModeMenuView.snp.makeConstraints { make in
            make.leading.equalTo(inputContainer.snp.leading)
            make.bottom.equalTo(inputContainer.snp.top).offset(-8)
            make.width.equalTo(210)
        }
    }

    private func configureVoiceModeButton(_ button: UIButton, title: String, systemName: String) {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: systemName)
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 10, bottom: 9, trailing: 10)
        config.baseForegroundColor = .label
        button.configuration = config
        button.contentHorizontalAlignment = .leading
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
    }

    private func render(_ state: SessionViewState) {
        profileLabel.text = state.profileText
        stateLabel.text = "\(state.voiceStateText) · \(state.connectionText)"
        hintLabel.text = state.primaryHint
        errorLabel.text = nil
        errorLabel.isHidden = true
        presentTransientErrorIfNeeded(state.errorText)
        summaryView.text = state.runningSummaryText
        messageField.isEnabled = state.isTextInputEnabled
        sendButton.isEnabled = state.isTextInputEnabled
        micButton.isEnabled = state.isMicEnabled
        reconnectButton.isEnabled = state.isReconnectEnabled
        reconnectButton.isHidden = !state.isReconnectEnabled
        endButton.isEnabled = state.isEndEnabled
        micButton.accessibilityLabel = state.micButtonTitle
        [sendButton, micButton].forEach { $0.alpha = $0.isEnabled ? 1 : 0.45 }
        updateMicButtonAppearance(for: state)
        updateVoiceModeMenuSelection(for: state.voiceInputMode)
        if state.isMicrophoneActive, !isVoiceInputMode {
            setVoiceInputMode(true)
        } else if !state.isMicrophoneActive, isVoiceInputMode {
            setVoiceInputMode(false)
        }
        updateConnectionIndicator(for: state.sessionState)
        messages = state.messages
        tableView.reloadData()
        scrollToLatestMessage(animated: false)
    }

    private func updateMicButtonAppearance(for state: SessionViewState) {
        let systemName: String
        switch (state.voiceInputMode, state.isMicrophoneActive) {
        case (.automatic, true):
            systemName = "stop.circle.fill"
        case (.automatic, false):
            systemName = "waveform.circle.fill"
        case (.manual, true):
            systemName = "xmark.circle.fill"
        case (.manual, false):
            systemName = "mic.fill"
        }
        micButton.setImage(UIImage(systemName: systemName), for: .normal)
        micButton.tintColor = state.voiceInputMode == .automatic ? .systemGreen : .systemBlue
        micButton.accessibilityLabel = "\(state.voiceInputMode.displayName). \(state.micButtonTitle). Long press to switch voice mode."
    }

    private func updateVoiceModeMenuSelection(for mode: VoiceInputMode) {
        updateVoiceModeButton(autoVoiceModeButton, selected: mode == .automatic)
        updateVoiceModeButton(manualVoiceModeButton, selected: mode == .manual)
    }

    private func updateVoiceModeButton(_ button: UIButton, selected: Bool) {
        guard var config = button.configuration else { return }
        config.baseForegroundColor = selected ? .systemBlue : .label
        config.subtitle = selected ? "Current" : nil
        button.configuration = config
        button.backgroundColor = selected ? UIColor.systemBlue.withAlphaComponent(0.1) : .clear
        button.layer.cornerRadius = 10
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageCell.reuseID, for: indexPath) as? ChatMessageCell ?? ChatMessageCell(style: .default, reuseIdentifier: ChatMessageCell.reuseID)
        cell.configure(with: message)
        return cell
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

    private func configureIconButton(_ button: UIButton, systemName: String, tintColor: UIColor) {
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = tintColor
        button.backgroundColor = .clear
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        button.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 36, height: 36))
        }
    }

    private func updateConnectionIndicator(for sessionState: SessionState) {
        let color: UIColor
        let shouldBlink: Bool

        switch sessionState {
        case .connecting, .reconnecting:
            color = .systemOrange
            shouldBlink = true
        case .connected, .inSession, .listening, .tutorThinking, .tutorSpeaking:
            color = .systemGreen
            shouldBlink = false
        case .idle, .ended,
             .backendFailed, .liveKitFailed, .microphonePermissionFailed,
             .audioSessionFailed, .microphonePublishFailed, .textSendFailed,
             .storageFailed, .unknownFailed:
            color = .systemGray3
            shouldBlink = false
        }

        titleStatusDot.backgroundColor = color
        if shouldBlink {
            if titleStatusDot.layer.animation(forKey: "aitutor.connectionBlink") == nil {
                let animation = CABasicAnimation(keyPath: "opacity")
                animation.fromValue = 1
                animation.toValue = 0.25
                animation.duration = 0.55
                animation.autoreverses = true
                animation.repeatCount = .infinity
                titleStatusDot.layer.add(animation, forKey: "aitutor.connectionBlink")
            }
        } else {
            titleStatusDot.layer.removeAnimation(forKey: "aitutor.connectionBlink")
            titleStatusDot.alpha = 1
        }
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardNotification(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardNotification(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSceneWillEnterForegroundNotification),
            name: .appSceneWillEnterForeground,
            object: nil
        )
    }

    @objc private func handleKeyboardNotification(_ notification: Notification) {
        handleKeyboard(notification)
    }

    @objc private func handleSceneWillEnterForegroundNotification() {
        guard viewModel.currentState.isMicrophoneActive else { return }
        setVoiceInputMode(true)
    }

    private func handleKeyboard(_ notification: Notification) {
        let userInfo = notification.userInfo ?? [:]
        let rawFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
        let convertedFrame = view.convert(rawFrame, from: nil)
        let keyboardOverlap = max(0, view.bounds.maxY - convertedFrame.minY - view.safeAreaInsets.bottom)
        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? UInt(UIView.AnimationOptions.curveEaseInOut.rawValue)
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        rootBottomConstraint?.update(inset: 12 + keyboardOverlap)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.scrollToLatestMessage(animated: true)
        }
    }

    private func scrollToLatestMessage(animated: Bool) {
        guard !messages.isEmpty else { return }
        tableView.scrollToRow(at: IndexPath(row: messages.count - 1, section: 0), at: .bottom, animated: animated)
    }

    private func setVoiceInputMode(_ enabled: Bool) {
        isVoiceInputMode = enabled
        messageField.isHidden = enabled
        waveformView.isHidden = !enabled
        if enabled {
            view.endEditing(true)
            waveformView.startAnimating()
        } else {
            waveformView.stopAnimating()
        }
    }

    @objc private func onMicTapped() {
        if didOpenVoiceModeMenu {
            didOpenVoiceModeMenu = false
            return
        }
        if !voiceModeMenuView.isHidden {
            hideVoiceModeMenu(animated: true)
            return
        }
        hideVoiceModeMenu(animated: true)

        switch viewModel.currentState.voiceInputMode {
        case .automatic:
            launchTask(kind: .voiceControl) { [weak self] in
                await self?.viewModel.toggleAutomaticVoiceInput()
            }
        case .manual:
            if isVoiceInputMode {
                setVoiceInputMode(false)
                launchTask(kind: .voiceControl) { [weak self] in
                    await self?.viewModel.cancelVoiceInput()
                }
                return
            }

            launchTask(kind: .voiceControl) { [weak self] in
                guard let self else { return }
                await self.viewModel.startSession()
                if self.viewModel.currentState.isMicrophoneActive {
                    self.setVoiceInputMode(true)
                }
            }
        }
    }

    @objc private func onMicLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        didOpenVoiceModeMenu = true
        showVoiceModeMenu(animated: true)
    }

    @objc private func onSelectAutoVoiceMode() {
        didOpenVoiceModeMenu = false
        hideVoiceModeMenu(animated: true)
        launchTask(kind: .voiceControl) { [weak self] in
            await self?.viewModel.setVoiceInputMode(.automatic)
        }
    }

    @objc private func onSelectManualVoiceMode() {
        didOpenVoiceModeMenu = false
        hideVoiceModeMenu(animated: true)
        launchTask(kind: .voiceControl) { [weak self] in
            await self?.viewModel.setVoiceInputMode(.manual)
        }
    }

    private func showVoiceModeMenu(animated: Bool) {
        updateVoiceModeMenuSelection(for: viewModel.currentState.voiceInputMode)
        voiceModeMenuView.isHidden = false
        let animations = { self.voiceModeMenuView.alpha = 1 }
        if animated {
            UIView.animate(withDuration: 0.18, animations: animations)
        } else {
            animations()
        }
    }

    private func hideVoiceModeMenu(animated: Bool) {
        let animations = { self.voiceModeMenuView.alpha = 0 }
        let completion: (Bool) -> Void = { _ in self.voiceModeMenuView.isHidden = true }
        if animated {
            UIView.animate(withDuration: 0.18, animations: animations, completion: completion)
        } else {
            animations()
            completion(true)
        }
    }

    @objc private func onReconnect() {
        hideVoiceModeMenu(animated: true)
        launchTask(kind: .sessionControl) { [weak self] in
            await self?.viewModel.reconnect()
        }
    }
    @objc private func onEnd() {
        hideVoiceModeMenu(animated: true)
        launchTask(kind: .sessionControl) { [weak self] in
            await self?.viewModel.endSession()
        }
    }
    @objc private func onSummary() {
        hideVoiceModeMenu(animated: true)
        let controller = SessionSummaryViewController(state: viewModel.currentState)
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak controller] _ in
                controller?.dismiss(animated: true)
            }
        )
        let navigation = UINavigationController(rootViewController: controller)
        if let presentation = navigation.sheetPresentationController {
            presentation.detents = [.medium(), .large()]
            presentation.prefersGrabberVisible = true
            presentation.preferredCornerRadius = 18
        }
        present(navigation, animated: true)
    }
    @objc private func onDismissKeyboardTap() {
        hideVoiceModeMenu(animated: true)
        view.endEditing(true)
    }
    @objc private func onSendText() {
        hideVoiceModeMenu(animated: true)
        if isVoiceInputMode {
            setVoiceInputMode(false)
            if viewModel.currentState.voiceInputMode == .automatic {
                launchTask(kind: .voiceControl) { [weak self] in
                    await self?.viewModel.toggleAutomaticVoiceInput()
                }
            } else {
                launchTask(kind: .voiceControl) { [weak self] in
                    await self?.viewModel.finishVoiceInput()
                }
            }
            return
        }

        let text = messageField.text ?? ""
        messageField.text = ""
        launchTask(kind: .textSend) { [weak self] in
            await self?.viewModel.sendText(text)
        }
    }

    private func launchTask(kind: TaskKind, _ operation: @escaping @MainActor () async -> Void) {
        actionTasks[kind]?.cancel()
        let task = Task { @MainActor [weak self] in
            await operation()
            self?.actionTasks[kind] = nil
        }
        actionTasks[kind] = task
    }

    private func cancelAllActionTasks() {
        actionTasks.values.forEach { $0.cancel() }
        actionTasks.removeAll()
    }

    private func presentTransientErrorIfNeeded(_ errorText: String?) {
        guard let errorText = errorText?.trimmingCharacters(in: .whitespacesAndNewlines), !errorText.isEmpty else { return }
        guard errorText != lastDisplayedErrorText else { return }
        lastDisplayedErrorText = errorText
        showTransientErrorBanner(text: errorText)
    }

    private func showTransientErrorBanner(text: String) {
        let banner = transientErrorBanner ?? UIView()
        let label = transientErrorLabel ?? UILabel()
        transientErrorHideTask?.cancel()

        banner.backgroundColor = UIColor.systemRed.withAlphaComponent(0.95)
        banner.layer.cornerRadius = 12
        banner.clipsToBounds = true
        banner.alpha = 0

        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 2
        label.text = text

        if transientErrorBanner == nil {
            view.addSubview(banner)
            banner.addSubview(label)
            banner.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
                make.leading.trailing.equalToSuperview().inset(12)
            }
            label.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12))
            }
            transientErrorBanner = banner
            transientErrorLabel = label
        }

        transientErrorLabel?.text = text
        view.bringSubviewToFront(banner)

        UIView.animate(withDuration: 0.22) {
            banner.alpha = 1
        }

        transientErrorHideTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_800_000_000)
            guard let self, !Task.isCancelled else { return }
            UIView.animate(withDuration: 0.25) {
                self.transientErrorBanner?.alpha = 0
            }
        }
    }
}

private final class VoiceWaveformView: UIView {
    private let bars: [UIView] = (0..<18).map { _ in UIView() }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private func setup() {
        let stack = UIStackView(arrangedSubviews: bars)
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.spacing = 4
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(28)
        }
        bars.forEach { bar in
            bar.backgroundColor = .systemBlue
            bar.layer.cornerRadius = 2
            bar.snp.makeConstraints { make in
                make.width.equalTo(4)
                make.height.equalTo(8)
            }
        }
        snp.makeConstraints { make in
            make.height.equalTo(32)
        }
    }

    func startAnimating() {
        bars.forEach { bar in
            bar.layer.removeAllAnimations()
            bar.transform = .identity
        }
        for (index, bar) in bars.enumerated() {
            let height = CGFloat([8, 14, 22, 12, 26, 16, 10, 24, 18][index % 9])
            UIView.animate(
                withDuration: 0.45,
                delay: Double(index) * 0.035,
                options: [.autoreverse, .repeat, .allowUserInteraction, .curveEaseInOut]
            ) {
                bar.transform = CGAffineTransform(scaleX: 1, y: height / 8)
            }
        }
    }

    func stopAnimating() {
        bars.forEach { bar in
            bar.layer.removeAllAnimations()
            bar.transform = .identity
        }
    }
}

private final class ChatMessageCell: UITableViewCell {
    static let reuseID = "ChatMessageCell"

    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let statusLabel = UILabel()
    private let textStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground

        messageLabel.numberOfLines = 0
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true

        statusLabel.numberOfLines = 1
        statusLabel.font = .preferredFont(forTextStyle: .caption2)
        statusLabel.adjustsFontForContentSizeCategory = true

        textStack.axis = .vertical
        textStack.spacing = 4
        bubbleView.layer.cornerRadius = 16
        bubbleView.addSubview(textStack)
        textStack.addArrangedSubview(messageLabel)
        textStack.addArrangedSubview(statusLabel)
        contentView.addSubview(bubbleView)

        textStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 9, left: 12, bottom: 8, right: 12))
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(with message: ChatMessage) {
        messageLabel.text = message.text
        statusLabel.text = "\(message.inputType.rawValue) · \(message.status.rawValue)"

        switch message.speaker {
        case .learner:
            bubbleView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            statusLabel.textColor = UIColor.white.withAlphaComponent(0.72)
            messageLabel.textAlignment = .left
            statusLabel.textAlignment = .right
            bubbleView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(5)
                make.trailing.equalToSuperview().inset(12)
                make.leading.greaterThanOrEqualToSuperview().offset(74)
                make.width.lessThanOrEqualTo(contentView.snp.width).multipliedBy(0.76)
            }
        case .tutor:
            bubbleView.backgroundColor = .secondarySystemBackground
            messageLabel.textColor = .label
            statusLabel.textColor = .secondaryLabel
            messageLabel.textAlignment = .left
            statusLabel.textAlignment = .left
            bubbleView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(5)
                make.leading.equalToSuperview().offset(12)
                make.trailing.lessThanOrEqualToSuperview().inset(74)
                make.width.lessThanOrEqualTo(contentView.snp.width).multipliedBy(0.76)
            }
        case .system:
            bubbleView.backgroundColor = .clear
            messageLabel.textColor = .secondaryLabel
            statusLabel.textColor = .tertiaryLabel
            messageLabel.textAlignment = .center
            statusLabel.textAlignment = .center
            bubbleView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(5)
                make.centerX.equalToSuperview()
                make.leading.greaterThanOrEqualToSuperview().offset(32)
                make.trailing.lessThanOrEqualToSuperview().inset(32)
            }
        }
    }
}

@MainActor
private final class SessionSummaryViewController: UIViewController {
    private let state: SessionViewState

    init(state: SessionViewState) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Summary"
        view.backgroundColor = .systemBackground

        let content = makeSummaryContent()
        let scrollView = UIScrollView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14

        let titleLabel = makeLabel(textStyle: .title2, color: .label)
        titleLabel.text = content.title

        let metaLabel = makeLabel(textStyle: .subheadline, color: .secondaryLabel)
        metaLabel.text = content.meta

        let statusLabel = makeLabel(textStyle: .footnote, color: .systemBlue)
        statusLabel.text = content.status

        let bodyCard = UIView()
        bodyCard.backgroundColor = .secondarySystemBackground
        bodyCard.layer.cornerRadius = 18
        let bodyLabel = makeLabel(textStyle: .body, color: .label)
        bodyLabel.text = content.body
        bodyCard.addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }

        let footnoteLabel = makeLabel(textStyle: .footnote, color: .secondaryLabel)
        footnoteLabel.text = content.footnote

        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        [titleLabel, metaLabel, statusLabel, bodyCard, footnoteLabel].forEach(stack.addArrangedSubview)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        stack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(18)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-36)
        }
    }

    private func makeLabel(textStyle: UIFont.TextStyle, color: UIColor) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: textStyle)
        label.textColor = color
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    private struct SummaryContent {
        let title: String
        let meta: String
        let status: String
        let body: String
        let footnote: String
    }

    private func makeSummaryContent() -> SummaryContent {
        if shouldPreferLiveSummary, state.latestSummaryRecord != nil {
            return makeLiveSummaryContent()
        }

        if let record = state.latestSummaryRecord {
            let profile = record.learningProfile?.summaryLine ?? record.tutorSubject
            let meta = "\(profile)\n\(formatDuration(record.durationSeconds)) · \(AppDateFormatter.shortDateTime(record.endedAt))"
            let status = makeStatusText(for: record)
            let body = preferredSummaryBody(for: record)
            let footnote = record.aiSummaryStatus == .generating
                ? "Final AI summary is still generating. The local summary is already saved."
                : "Saved locally. Raw audio is not stored."
            return SummaryContent(
                title: "Practice Summary",
                meta: meta,
                status: status,
                body: body,
                footnote: footnote
            )
        }

        return makeLiveSummaryContent()
    }

    private var shouldPreferLiveSummary: Bool {
        switch state.sessionState {
        case .idle, .ended:
            return false
        default:
            return true
        }
    }

    private func makeLiveSummaryContent() -> SummaryContent {
        let runningSummary = state.runningSummaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = isPlaceholderSummary(runningSummary)
            ? "A summary will appear here after the session has transcript text."
            : runningSummary
        return SummaryContent(
            title: "Live Summary",
            meta: state.profileText,
            status: "Draft",
            body: body,
            footnote: "Only transcript text is used for summaries. Raw audio is not stored."
        )
    }

    private func preferredSummaryBody(for record: SessionRecord) -> String {
        switch record.aiSummaryStatus {
        case .completed:
            return record.aiSummary?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? record.aiSummary! : record.summary
        case .generating:
            return record.aiSummary?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? record.aiSummary! : record.summary
        default:
            return record.summary
        }
    }

    private func makeStatusText(for record: SessionRecord) -> String {
        switch record.aiSummaryStatus {
        case .completed:
            return "AI summary completed"
        case .generating:
            return "AI summary generating"
        case .unavailable:
            return "AI summary unavailable · local summary shown"
        case .failed:
            return "AI summary failed · local summary shown"
        case .localOnly, .none:
            return "Local summary"
        }
    }

    private func isPlaceholderSummary(_ text: String) -> Bool {
        text.isEmpty
            || text == "AI summary draft will appear during longer sessions. Only transcript text is sent; raw audio is never sent."
            || text == "Draft waiting for transcript. It will update after 4 final turns."
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = max(0, Int(duration))
        let minutes = seconds / 60
        let remainder = seconds % 60
        return minutes == 0 ? "\(remainder)s" : "\(minutes)m \(remainder)s"
    }
}

@MainActor
final class LearningProfileEditorViewController: UIViewController {
    private var profile: LearningProfile
    private let onSave: (LearningProfile) -> Void
    private var selectedMode: LearningMode
    private var selectedStyle: TutorStyle
    private var selectedDifficulty: LearningDifficulty
    private let modeButton = UIButton(type: .system)
    private let styleButton = UIButton(type: .system)
    private let difficultyButton = UIButton(type: .system)

    init(
        profile: LearningProfile,
        onSave: @escaping (LearningProfile) -> Void
    ) {
        self.profile = profile
        self.onSave = onSave
        self.selectedMode = profile.learningMode
        self.selectedStyle = profile.tutorStyle
        self.selectedDifficulty = profile.difficulty
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Customize"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) })
        setupUI()
    }

    private func setupUI() {
        configureSelectionButton(modeButton)
        configureSelectionButton(styleButton)
        configureSelectionButton(difficultyButton)
        rebuildMenus()

        let stack = UIStackView(arrangedSubviews: [
            label("Learning mode"), modeButton,
            label("Tutor style"), styleButton,
            label("Difficulty"), difficultyButton
        ])
        stack.axis = .vertical
        stack.spacing = 12
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(18)
        }
    }

    private func configureSelectionButton(_ button: UIButton) {
        var config = UIButton.Configuration.gray()
        config.titleAlignment = .leading
        config.image = UIImage(systemName: "chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        button.showsMenuAsPrimaryAction = true
    }

    private func rebuildMenus() {
        updateButtonTitle(modeButton, title: selectedMode.displayName)
        updateButtonTitle(styleButton, title: selectedStyle.displayName)
        updateButtonTitle(difficultyButton, title: selectedDifficulty.displayName)

        modeButton.menu = UIMenu(
            children: LearningMode.allCases.map { mode in
                UIAction(
                    title: mode.displayName,
                    state: mode == selectedMode ? .on : .off
                ) { [weak self] _ in
                    self?.selectedMode = mode
                    self?.applyChanges()
                    self?.rebuildMenus()
                }
            }
        )

        styleButton.menu = UIMenu(
            children: TutorStyle.allCases.map { style in
                UIAction(
                    title: style.displayName,
                    state: style == selectedStyle ? .on : .off
                ) { [weak self] _ in
                    self?.selectedStyle = style
                    self?.applyChanges()
                    self?.rebuildMenus()
                }
            }
        )

        difficultyButton.menu = UIMenu(
            children: LearningDifficulty.allCases.map { difficulty in
                UIAction(
                    title: difficulty.displayName,
                    state: difficulty == selectedDifficulty ? .on : .off
                ) { [weak self] _ in
                    self?.selectedDifficulty = difficulty
                    self?.applyChanges()
                    self?.rebuildMenus()
                }
            }
        )
    }

    private func updateButtonTitle(_ button: UIButton, title: String) {
        guard var config = button.configuration else { return }
        config.title = title
        button.configuration = config
    }

    private func label(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }

    private func applyChanges() {
        let updated = LearningProfile(
            learningMode: selectedMode,
            tutorStyle: selectedStyle,
            difficulty: selectedDifficulty,
            customGoal: nil
        ).normalized()
        profile = updated
        onSave(updated)
    }
}

@MainActor
final class HistoryViewController: UITableViewController {
    private let environment: AppEnvironment
    private var records: [SessionRecord] = []

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "History"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HistoryCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        records = environment.sessionStorage.loadRecentSessions()
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { records.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let record = records[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = record.learningProfile?.summaryLine ?? record.tutorSubject
        content.secondaryText = "\(AppDateFormatter.shortDateTime(record.endedAt)) · \(Int(record.durationSeconds))s · \(record.aiSummaryStatus?.rawValue ?? "local")"
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(SessionDetailViewController(record: records[indexPath.row], environment: environment), animated: true)
    }
}

@MainActor
final class SessionDetailViewController: UIViewController {
    private let record: SessionRecord
    private let environment: AppEnvironment

    init(record: SessionRecord, environment: AppEnvironment) {
        self.record = record
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Session Review"
        view.backgroundColor = .systemBackground
        let textView = UITextView()
        textView.isEditable = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.text = detailText()
        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(14)
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Continue", style: .plain, target: self, action: #selector(onContinue))
    }

    private func detailText() -> String {
        let profile = record.learningProfile?.summaryLine ?? record.tutorSubject
        let transcript = record.messages?.map(\.transcriptLine).joined(separator: "\n") ?? record.transcriptText ?? "No transcript saved."
        return """
        Profile: \(profile)
        Goal: \(record.learningProfile?.goalLine ?? "No custom goal")
        Duration: \(Int(record.durationSeconds))s

        Summary:
        \(record.summary)

        AI Summary:
        \(record.aiSummary ?? "Not available")

        Continue:
        The Continue button starts a new room with this learning profile plus a short previous-session context for the tutor.

        Transcript:
        \(transcript)
        """
    }

    @objc private func onContinue() {
        let profile = record.learningProfile ?? .default
        let resumeContext = SessionResumeContext.make(from: record)
        navigationController?.pushViewController(
            SessionViewController(
                environment: environment,
                learningProfile: profile,
                autoConnect: true,
                resumeContext: resumeContext,
                resumeRecord: record
            ),
            animated: true
        )
    }
}

@MainActor
final class DiagnosticsViewController: UIViewController {
    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Diagnostics"
        view.backgroundColor = .systemBackground
        let textView = UITextView()
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.text = diagnosticsText()
        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(14)
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Copy", style: .plain, target: self, action: #selector(onCopy))
    }

    private func diagnosticsText() -> String {
        let latest = environment.sessionStorage.loadRecentSessions().first
        let profile = environment.learningProfileStore.loadDefaultProfile()
        return """
        Backend URL: \(AppConfig.backendBaseURL.absoluteString)
        Tutor subject: english-speaking
        LiveKit URL: available after /session
        Room: \(latest?.roomName ?? "none")
        Participant identity: not stored after session end
        Connection state: see active Chat screen
        Microphone: see active Chat screen
        Audio route: see Xcode [test] logs during session
        Voice pipeline profile: configured in backend env
        Voice input mode: \(environment.appSettingsStore.voiceInputMode.displayName)
        Default learning profile: \(profile.summaryLine)
        Custom goal: \(profile.goalLine)
        Saved sessions: \(environment.sessionStorage.loadRecentSessions().count)

        Safe diagnostics only. No token, API key, API secret, or raw audio is shown here.
        """
    }

    @objc private func onCopy() {
        UIPasteboard.general.string = diagnosticsText()
    }
}

@MainActor
final class SettingsViewController: UITableViewController {
    private enum Item: Int, CaseIterable {
        case privacy
        case clearHistory
        case resetProfile

        var title: String {
            switch self {
            case .privacy: return "Privacy"
            case .clearHistory: return "Clear History"
            case .resetProfile: return "Reset Learning Profile"
            }
        }

        var subtitle: String {
            switch self {
            case .privacy:
                return "What is stored locally and what is not stored."
            case .clearHistory:
                return "Delete all local session records."
            case .resetProfile:
                return "Restore default learning mode, style, and goal."
            }
        }
    }

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsItemCell")
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Item.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsItemCell", for: indexPath)
        guard let item = Item(rawValue: indexPath.row) else { return cell }
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = item.subtitle
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.numberOfLines = 2
        cell.contentConfiguration = content
        cell.accessoryView = nil
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let item = Item(rawValue: indexPath.row) else { return }
        switch item {
        case .privacy:
            navigationController?.pushViewController(PrivacyViewController(), animated: true)
        case .clearHistory:
            onClearHistory()
        case .resetProfile:
            onResetProfile()
        }
    }

    private func onClearHistory() {
        let alert = UIAlertController(
            title: "Clear History",
            message: "This will remove all local session records on this device.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive, handler: { [weak self] _ in
            try? self?.environment.sessionStorage.clear()
        }))
        present(alert, animated: true)
    }

    private func onResetProfile() {
        let alert = UIAlertController(
            title: "Reset Learning Profile",
            message: "Restore default learning mode, tutor style, difficulty, and goal?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { [weak self] _ in
            self?.environment.learningProfileStore.resetDefaultProfile()
        }))
        present(alert, animated: true)
    }
}

@MainActor
private final class PrivacyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Privacy"
        view.backgroundColor = .systemBackground
        let textView = UITextView()
        textView.isEditable = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.text = """
        AITutor does not save raw audio.

        It stores local text transcript, summaries, and metadata for recent sessions on this device.

        You can remove all local records at any time from Settings > Clear History.
        """
        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(14)
        }
    }
}
