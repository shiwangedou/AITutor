import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .systemBackground

        let navigationController = UINavigationController(rootViewController: SessionViewController())
        navigationController.view.backgroundColor = .systemBackground
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        AppLogger.debug("Scene entered background. Background audio mode should keep an active LiveKit voice session alive.", category: .app)
        NotificationCenter.default.post(name: .appSceneDidEnterBackground, object: nil)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        AppLogger.debug("Scene will enter foreground. Verify LiveKit connection and audio route after returning.", category: .app)
        NotificationCenter.default.post(name: .appSceneWillEnterForeground, object: nil)
    }
}

extension Notification.Name {
    static let appSceneDidEnterBackground = Notification.Name("AITutor.appSceneDidEnterBackground")
    static let appSceneWillEnterForeground = Notification.Name("AITutor.appSceneWillEnterForeground")
}
