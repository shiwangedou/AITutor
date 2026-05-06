import UIKit

final class SessionViewController: UIViewController {
    private let stateLabel = UILabel()
    private let logView = UITextView()
    private let connectButton = UIButton(type: .system)
    private let startButton = UIButton(type: .system)
    private let endButton = UIButton(type: .system)

    private let audioManager = AudioSessionManager()
    private let liveKitService: LiveKitControlling = LiveKitService()
    private let backendClient = BackendClient(baseURL: URL(string: "http://127.0.0.1:8000")!)

    private var state: SessionState = .idle {
        didSet { stateLabel.text = "State: \(state.rawValue)" }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AI Tutor"
        view.backgroundColor = .systemBackground
        setupUI()
        state = .idle
    }

    private func setupUI() {
        stateLabel.font = .preferredFont(forTextStyle: .headline)

        logView.isEditable = false
        logView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)

        connectButton.setTitle("Connect", for: .normal)
        startButton.setTitle("Start Session", for: .normal)
        endButton.setTitle("End Session", for: .normal)

        connectButton.addTarget(self, action: #selector(onConnect), for: .touchUpInside)
        startButton.addTarget(self, action: #selector(onStart), for: .touchUpInside)
        endButton.addTarget(self, action: #selector(onEnd), for: .touchUpInside)

        let buttons = UIStackView(arrangedSubviews: [connectButton, startButton, endButton])
        buttons.axis = .horizontal
        buttons.spacing = 12
        buttons.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [stateLabel, buttons, logView])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            logView.heightAnchor.constraint(greaterThanOrEqualToConstant: 240)
        ])
    }

    @objc private func onConnect() {
        Task { await connectFlow() }
    }

    @objc private func onStart() {
        Task { await startFlow() }
    }

    @objc private func onEnd() {
        Task { await endFlow() }
    }

    private func connectFlow() async {
        state = .connecting
        appendLog("Requesting session config from backend...")

        do {
            let config = try await backendClient.createSession(displayName: "Learner")
            appendLog("Room: \(config.roomName)")
            try await liveKitService.connect(using: config)
            state = .connected
            appendLog("Connected to LiveKit.")
        } catch {
            state = .failed
            appendLog("Connect failed: \(error.localizedDescription)")
        }
    }

    private func startFlow() async {
        do {
            try audioManager.configureForVoiceChat()
            try await liveKitService.startMicrophone()
            state = .inSession
            appendLog("Voice session started.")
        } catch {
            state = .failed
            appendLog("Start failed: \(error.localizedDescription)")
        }
    }

    private func endFlow() async {
        await liveKitService.disconnect()
        audioManager.deactivate()
        state = .ended
        appendLog("Session ended.")
    }

    private func appendLog(_ message: String) {
        let line = "[\(timestamp())] \(message)\n"
        logView.text += line
        let range = NSRange(location: max(logView.text.count - 1, 0), length: 0)
        logView.scrollRangeToVisible(range)
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}
