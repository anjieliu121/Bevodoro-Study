//
//  SceneDelegate.swift
//  Bevodoro Study
//
//  Created by Anjie on 2/22/26.
//

import UIKit
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var bevoSickCheckTimer: Timer?
    private static let bevoSickNotifDateKey = "lastBevoSickNotifDate"
    private static let bevoSickCheckInterval: TimeInterval = 60

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        MusicManager.shared.playMusic()
        startBevoSickTimer()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        MusicManager.shared.stopMusic()
        bevoSickCheckTimer?.invalidate()
        bevoSickCheckTimer = nil
    }

    private func startBevoSickTimer() {
        bevoSickCheckTimer?.invalidate()
        bevoSickCheckTimer = Timer.scheduledTimer(withTimeInterval: Self.bevoSickCheckInterval, repeats: true) { [weak self] _ in
            self?.checkAndNotifyBevoSick()
        }
    }

    private func checkAndNotifyBevoSick() {
        guard SettingViewController.isNotificationsEnabled else { return }
        guard let user = UserManager.shared.currentUser, user.isSick() else { return }

        // Only notify once per day.
        if let lastDate = UserDefaults.standard.object(forKey: Self.bevoSickNotifDateKey) as? Date,
           Calendar.current.isDateInToday(lastDate) { return }

        UserDefaults.standard.set(Date(), forKey: Self.bevoSickNotifDateKey)

        let content = UNMutableNotificationContent()
        content.title = "Bevo is feeling sick!"
        content.body = "It's been a while since you last studied! Help Bevo recover by giving him some medicine."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("SceneDelegate: failed to send Bevo sick notification: \(error)") }
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        MusicManager.shared.stopMusic()
    }

    func showLoginScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
        window?.rootViewController = loginVC
        window?.makeKeyAndVisible()
    }

    func showMainScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainNav = storyboard.instantiateViewController(withIdentifier: "MainNavigationController")
        guard let window else { return }
        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve) {
            window.rootViewController = mainNav
        }
    }
    
}
