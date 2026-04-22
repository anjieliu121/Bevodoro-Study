//
//  SettingViewController.swift
//  Bevodoro Study
//
//  Created by 阿清 on 2/28/26. Modified by Isabella 3-30-26 and 4-4-26
//

import UIKit
import UserNotifications
import FirebaseAuth

class SettingViewController: BaseViewController {

    enum SettingRow: Int, CaseIterable {
        case backgroundMusic
        case bevosSound
        case pomodoroStudyTimer
        case pomodoroBreakTimer
        case pomodoroLongBreakTimer
        case pomodoroCycleLength
        case notifications
        case logout
        case demoMode

        var title: String {
            switch self {
            case .backgroundMusic: return "Background Music"
            case .bevosSound: return "Bevo's Sound"
            case .pomodoroStudyTimer: return "Pomodoro Study Timer"
            case .pomodoroBreakTimer: return "Pomodoro Break Timer"
            case .pomodoroLongBreakTimer: return "Pomodoro Long Break Timer"
            case .pomodoroCycleLength: return "Pomodoro Cycle Length"
            case .notifications: return "Notifications"
            case .logout: return "Log Out"
            case .demoMode: return "Demo Mode"
            }
        }

        var iconName: String {
            switch self {
            case .backgroundMusic: return "music.note"
            case .bevosSound: return "speaker.wave.2.fill"
            case .pomodoroStudyTimer: return "clock"
            case .pomodoroBreakTimer: return "clock"
            case .pomodoroLongBreakTimer: return "clock"
            case .pomodoroCycleLength: return "arrow.clockwise"
            case .notifications: return "bell.fill"
            case .logout: return "rectangle.portrait.and.arrow.right"
            case .demoMode: return "testtube.2"
            }
        }
    }
    
    /// UserDefaults key for Bevo's sound effects (moo, eating) on/off.
    private static let bevosSoundKey = "bevosSoundEnabled"
    private static let bevosSoundVolumeKey = "bevosSoundVolume"

    /// Whether Bevo's sound effects are enabled (moo tap, chewing when fed). Check before playing any Bevo SFX.
    static var isBevosSoundEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: bevosSoundKey) == nil {
                return true // default: sound on
            }
            return UserDefaults.standard.bool(forKey: bevosSoundKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: bevosSoundKey)
        }
    }

    /// Bevo SFX volume (0 = mute). Persisted in UserDefaults.
    static var bevosSoundVolume: Float {
        get {
            if let v = UserDefaults.standard.object(forKey: bevosSoundVolumeKey) as? Float {
                return max(0, min(1, v))
            }
            if let n = UserDefaults.standard.object(forKey: bevosSoundVolumeKey) as? NSNumber {
                return max(0, min(1, n.floatValue))
            }
            // Backward compat: if the old toggle was off, start muted.
            if UserDefaults.standard.object(forKey: bevosSoundKey) != nil, isBevosSoundEnabled == false {
                return 0
            }
            return 1
        }
        set {
            UserDefaults.standard.set(max(0, min(1, newValue)), forKey: bevosSoundVolumeKey)
            // Keep old toggle consistent so older code paths still "work".
            isBevosSoundEnabled = newValue > 0
        }
    }
    
    /// UserDefaults key for Demo Mode on/off.
    private static let demoModeKey = "demoModeEnabled"

    /// Whether Demo Mode is enabled. Use this throughout the app.
    static var isDemoModeEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: demoModeKey) == nil {
                return false // default: demo mode OFF
            }
            return UserDefaults.standard.bool(forKey: demoModeKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: demoModeKey)
        }
    }

    /// UserDefaults key for app notifications being enabled.
    private static let notificationsKey = "notificationsEnabled"

    /// Whether notifications are enabled in-app. Check this before scheduling any local notifications.
    static var isNotificationsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: notificationsKey) == nil {
                return true // default: notifications on
            }
            return UserDefaults.standard.bool(forKey: notificationsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: notificationsKey)
        }
    }

    @IBOutlet weak var tableView: UITableView!

    /// Resolves table view from outlet or from view hierarchy (avoids crash if outlet not connected).
    private var settingsTableView: UITableView {
        if let tv = tableView { return tv }
        if let tv = view.subviews.first(where: { $0 is UITableView }) as? UITableView { return tv }
        fatalError("SettingViewController: no UITableView found. Connect the tableView outlet in the storyboard.")
    }

    private var bevosSoundOn: Bool {
        get { Self.isBevosSoundEnabled }
        set { Self.isBevosSoundEnabled = newValue }
    }

    private var notificationsOn: Bool {
        get { Self.isNotificationsEnabled }
        set { Self.isNotificationsEnabled = newValue }
    }

    private var selectedPomodoroMinutes = UserManager.shared.currentUser?.settings.timerStudyMins ?? defaultTimerStudyMins

    private enum SettingsSection: Int, CaseIterable {
        case audio
        case pomodoro
        case general

        var title: String {
            switch self {
            case .audio: return "Audio"
            case .pomodoro: return "Pomodoro"
            case .general: return "General"
            }
        }

        var rows: [SettingRow] {
            switch self {
            case .audio: return [.backgroundMusic, .bevosSound]
            case .pomodoro: return [
                .pomodoroStudyTimer, .pomodoroBreakTimer, .pomodoroLongBreakTimer, .pomodoroCycleLength
            ]
            case .general: return [.notifications, .logout, .demoMode]
            }
        }
    }

    private let glowHost = UIView()
    private let backgroundImageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.subviews.compactMap { $0 as? UIImageView }.first?.isHidden = true
        view.backgroundColor = .clear

        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.image = UIImage(named: "texture_ut_light")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        view.insertSubview(backgroundImageView, at: 0)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        glowHost.translatesAutoresizingMaskIntoConstraints = false
        glowHost.isUserInteractionEnabled = false
        glowHost.backgroundColor = .clear
        view.insertSubview(glowHost, belowSubview: settingsTableView)

        NSLayoutConstraint.activate([
            glowHost.topAnchor.constraint(equalTo: view.topAnchor),
            glowHost.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glowHost.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            glowHost.heightAnchor.constraint(equalToConstant: 200)
        ])

        let glow = CAGradientLayer()
        glow.colors = [
            SettingsStyle.accent.withAlphaComponent(0.22).cgColor,
            UIColor.clear.cgColor
        ]
        glow.locations = [0, 1]
        glow.startPoint = CGPoint(x: 0.5, y: 0)
        glow.endPoint = CGPoint(x: 0.5, y: 1)
        glowHost.layer.addSublayer(glow)
        glow.name = "settingsTopGlow"

        setupTableView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        glowHost.layer.sublayers?.compactMap { $0 as? CAGradientLayer }.first?.frame = glowHost.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "Settings"

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        let navTitleFont = SettingsTypography.sourGummy(size: 17, weight: .semibold)
        let navLargeFont = SettingsTypography.sourGummy(size: 34, weight: .semibold)
        appearance.titleTextAttributes = [
            .foregroundColor: SettingsStyle.mainTitle,
            .font: navTitleFont
        ]
        appearance.largeTitleTextAttributes = [
            .font: navLargeFont,
            .foregroundColor: SettingsStyle.mainTitle
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = SettingsStyle.accent

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward.circle"),
            style: .plain,
            target: self,
            action: #selector(UIViewController.dismissModalBack)
        )
        navigationItem.leftBarButtonItem?.accessibilityLabel = "Back"

        settingsTableView.reloadData()
    }

    private func setupTableView() {
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.backgroundColor = .clear
        settingsTableView.separatorStyle = .singleLine
        settingsTableView.separatorColor = SettingsStyle.divider
        settingsTableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 0)
        settingsTableView.sectionHeaderTopPadding = 8
        settingsTableView.register(VolumeSliderCell.self, forCellReuseIdentifier: VolumeSliderCell.reuseIdentifier)
        settingsTableView.register(SettingsDetailCell.self, forCellReuseIdentifier: SettingsDetailCell.reuseIdentifier)
        settingsTableView.register(SettingsToggleCell.self, forCellReuseIdentifier: SettingsToggleCell.reuseIdentifier)
    }

    private func settingRow(at indexPath: IndexPath) -> SettingRow {
        SettingsSection(rawValue: indexPath.section)!.rows[indexPath.row]
    }

    private func indexPath(for row: SettingRow) -> IndexPath? {
        for sec in SettingsSection.allCases {
            if let r = sec.rows.firstIndex(of: row) {
                return IndexPath(row: r, section: sec.rawValue)
            }
        }
        return nil
    }

    private func subtitle(for row: SettingRow) -> String {
        switch row {
        case .backgroundMusic: return "Adjust background music volume"
        case .bevosSound: return "Adjust Bevo's voice volume"
        case .pomodoroStudyTimer: return "Set study duration"
        case .pomodoroBreakTimer: return "Set short break duration"
        case .pomodoroLongBreakTimer: return "Set long break duration"
        case .pomodoroCycleLength: return "Set cycles per session"
        case .notifications: return "Receive reminders and updates"
        case .logout: return "Sign out of your account"
        case .demoMode: return "Explore Bevodoro features"
        }
    }

    private func pomodoroDetailText(for row: SettingRow) -> String? {
        switch row {
        case .pomodoroStudyTimer:
            let m = UserManager.shared.currentUser?.settings.timerStudyMins ?? defaultTimerStudyMins
            return "\(m) min"
        case .pomodoroBreakTimer:
            let m = UserManager.shared.currentUser?.settings.timerBreakMins ?? defaultTimerBreakMins
            return "\(m) min"
        case .pomodoroLongBreakTimer:
            let m = UserManager.shared.currentUser?.settings.timerLongBreakMins ?? defaultTimerLongBreakMins
            return "\(m) min"
        case .pomodoroCycleLength:
            let c = UserManager.shared.currentUser?.settings.timerCycleLength ?? defaultTimerCycleLength
            return "\(c) cycles"
        default:
            return nil
        }
    }

    private func showPomodoroStudyPicker() {
        let pickerVC = PomodoroPickerViewController()
        pickerVC.values = pomodoroDurations
        pickerVC.unitLabel = "min"
        pickerVC.selectedValue = UserManager.shared.currentUser?.settings.timerStudyMins ?? defaultTimerStudyMins
        
        pickerVC.onSelect = { [weak self] minutes in
            guard let self else { return }
            
            // Automatically exit demo mode
            SettingViewController.isDemoModeEnabled = false

            // save the new timer study minute duration to firestore
            self.selectedPomodoroMinutes = minutes
            UserManager.shared.currentUser?.settings.timerStudyMins = minutes
            UserManager.shared.currentUser?.saveToFirestore()
            self.settingsTableView.reloadData()
        }

        if let sheet = pickerVC.sheetPresentationController {
            let pickerSheetHeight: CGFloat = 280
            let detent = UISheetPresentationController.Detent.custom { _ in pickerSheetHeight }
            sheet.detents = [detent]
            sheet.prefersGrabberVisible = true
        }

        present(pickerVC, animated: true)
    }
    
    private func showPomodoroBreakPicker() {
        let pickerVC = PomodoroPickerViewController()
        pickerVC.values = pomodoroDurations
        pickerVC.unitLabel = "min"
        pickerVC.selectedValue = UserManager.shared.currentUser?.settings.timerBreakMins ?? defaultTimerBreakMins

        pickerVC.onSelect = { [weak self] minutes in
            guard let self else { return }
            
            // Automatically exit demo mode
            SettingViewController.isDemoModeEnabled = false

            // save the new timer break minute duration to firestore
            UserManager.shared.currentUser?.settings.timerBreakMins = minutes
            UserManager.shared.currentUser?.saveToFirestore()
            self.settingsTableView.reloadData()
        }

        if let sheet = pickerVC.sheetPresentationController {
            let pickerSheetHeight: CGFloat = 280
            let detent = UISheetPresentationController.Detent.custom { _ in pickerSheetHeight }
            sheet.detents = [detent]
            sheet.prefersGrabberVisible = true
        }

        present(pickerVC, animated: true)
    }
    
    private func showPomodoroLongBreakPicker() {
        let pickerVC = PomodoroPickerViewController()
        pickerVC.values = pomodoroDurations
        pickerVC.unitLabel = "min"
        pickerVC.selectedValue = UserManager.shared.currentUser?.settings.timerLongBreakMins ?? defaultTimerLongBreakMins

        pickerVC.onSelect = { [weak self] minutes in
            guard let self else { return }
            
            // Automatically exit demo mode
            SettingViewController.isDemoModeEnabled = false

            // save the new timer break minute duration to firestore
            UserManager.shared.currentUser?.settings.timerLongBreakMins = minutes
            UserManager.shared.currentUser?.saveToFirestore()
            self.settingsTableView.reloadData()
        }

        if let sheet = pickerVC.sheetPresentationController {
            let pickerSheetHeight: CGFloat = 280
            let detent = UISheetPresentationController.Detent.custom { _ in pickerSheetHeight }
            sheet.detents = [detent]
            sheet.prefersGrabberVisible = true
        }

        present(pickerVC, animated: true)
    }
    
    private func showPomodoroCycleLengthPicker() {
        let pickerVC = PomodoroPickerViewController()
        pickerVC.values = pomodoroCycleLengths
        pickerVC.unitLabel = "cycles"
        pickerVC.selectedValue = UserManager.shared.currentUser?.settings.timerCycleLength ?? defaultTimerCycleLength

        pickerVC.onSelect = { [weak self] cycles in
            guard let self else { return }
            
            // Automatically exit demo mode
            SettingViewController.isDemoModeEnabled = false

            // save the new timer break minute duration to firestore
            UserManager.shared.currentUser?.settings.timerCycleLength = cycles
            UserManager.shared.currentUser?.saveToFirestore()
            self.settingsTableView.reloadData()
        }

        if let sheet = pickerVC.sheetPresentationController {
            let pickerSheetHeight: CGFloat = 280
            let detent = UISheetPresentationController.Detent.custom { _ in pickerSheetHeight }
            sheet.detents = [detent]
            sheet.prefersGrabberVisible = true
        }

        present(pickerVC, animated: true)
    }
    
    private func showLogoutConfirmation() {
        let alert = UIAlertController(
            title: "Log Out",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
            self.handleLogout()
        })

        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension SettingViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        SettingsSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        SettingsSection(rawValue: section)?.rows.count ?? 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sec = SettingsSection(rawValue: section) else { return nil }
        let container = UIView()
        container.backgroundColor = .clear
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = sec.title
        label.font = SettingsTypography.sourGummy(size: 12, weight: .semibold)
        label.textColor = SettingsStyle.mainTitle
        label.accessibilityTraits.insert(.header)
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 22),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2)
        ])
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        30
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == SettingsSection.general.rawValue { return 28 }
        return 10
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = settingRow(at: indexPath)

        switch row {
        case .backgroundMusic, .bevosSound:
            guard let cell = settingsTableView.dequeueReusableCell(
                withIdentifier: VolumeSliderCell.reuseIdentifier,
                for: indexPath
            ) as? VolumeSliderCell else {
                return UITableViewCell()
            }
            let v = row == .backgroundMusic ? MusicManager.shared.musicVolume : Self.bevosSoundVolume
            cell.configure(
                iconSystemName: row.iconName,
                title: row.title,
                subtitle: subtitle(for: row),
                value: v,
                percentText: volumeText(v)
            )
            cell.slider.tag = row.rawValue
            cell.slider.addTarget(self, action: #selector(volumeSliderChanged(_:)), for: .valueChanged)
            return cell

        case .pomodoroStudyTimer, .pomodoroBreakTimer, .pomodoroLongBreakTimer, .pomodoroCycleLength, .logout:
            guard let cell = settingsTableView.dequeueReusableCell(
                withIdentifier: SettingsDetailCell.reuseIdentifier,
                for: indexPath
            ) as? SettingsDetailCell else {
                return UITableViewCell()
            }
            cell.configure(
                iconSystemName: row.iconName,
                title: row.title,
                subtitle: subtitle(for: row),
                detail: pomodoroDetailText(for: row)
            )
            return cell

        case .notifications, .demoMode:
            guard let cell = settingsTableView.dequeueReusableCell(
                withIdentifier: SettingsToggleCell.reuseIdentifier,
                for: indexPath
            ) as? SettingsToggleCell else {
                return UITableViewCell()
            }
            let on = row == .notifications ? notificationsOn : Self.isDemoModeEnabled
            cell.configure(iconSystemName: row.iconName, title: row.title, subtitle: subtitle(for: row), isOn: on)
            if row == .notifications {
                cell.toggle.addTarget(self, action: #selector(toggleNotif(_:)), for: .valueChanged)
            } else {
                cell.toggle.addTarget(self, action: #selector(demoModeChanged(_:)), for: .valueChanged)
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        settingsTableView.deselectRow(at: indexPath, animated: true)
        let row = settingRow(at: indexPath)

        switch row {
        case .pomodoroStudyTimer:
            showPomodoroStudyPicker()
        case .pomodoroBreakTimer:
            showPomodoroBreakPicker()
        case .pomodoroLongBreakTimer:
            showPomodoroLongBreakPicker()
        case .pomodoroCycleLength:
            showPomodoroCycleLengthPicker()
        case .logout:
            handleLogout()
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = settingRow(at: indexPath)
        switch row {
        case .backgroundMusic, .bevosSound:
            return 104
        default:
            return 72
        }
    }

    private func volumeText(_ v: Float) -> String {
        "\(Int(round(max(0, min(1, v)) * 100)))%"
    }

    @objc private func volumeSliderChanged(_ sender: UISlider) {
        guard let row = SettingRow(rawValue: sender.tag) else { return }
        switch row {
        case .backgroundMusic:
            MusicManager.shared.setMusicVolume(sender.value)
        case .bevosSound:
            Self.bevosSoundVolume = sender.value
        default:
            break
        }

        if let indexPath = indexPath(for: row),
           let cell = settingsTableView.cellForRow(at: indexPath) as? VolumeSliderCell {
            let v = sender.value
            cell.configure(
                iconSystemName: row.iconName,
                title: row.title,
                subtitle: subtitle(for: row),
                value: v,
                percentText: volumeText(v)
            )
        }
    }
    
    @objc private func demoModeChanged(_ sender: UISwitch) {
        Self.isDemoModeEnabled = sender.isOn
        
        // CHANGES: shown in the alert
        // shorten timer and rate to demonstrate working timers
        // change the timer values: moved to TimerManager.swift
        // change the earning rate: moved to TimerViewController.swift
        
        if sender.isOn {
            showDemoModeAlert()
        }
    }
    
    private func showDemoModeAlert() {
        let message = """
        Features:
        Added \(demoCoinBonusAmount) coins to current balance
        Shorter study time: \(demoModeStudySeconds) seconds
        Shorter break time: \(demoModeBreakSeconds) seconds
        Shorter long break time: \(demoModeLongBreakSeconds) seconds
        Shorter cycle: \(demoModeCycleLength) sessions
        Higher earning rate: \(demoModeCoinsPerMinute) coins per minute
        Lower Sick threshold: \(demoBevoSickThresholdSeconds) seconds
        
        ... and additional information in displays
        """
        UserManager.shared.currentUser?.addCoins(demoCoinBonusAmount)
        UserManager.shared.currentUser?.saveToFirestore()

        let alert = UIAlertController(
            title: "Demo Mode Enabled",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func toggleNotif(_ sender: UISwitch) {
        if sender.isOn {
            reqNotifPermission(toggle: sender)
        } else {
            notificationsOn = false
        }
    }

    private func reqNotifPermission(toggle: UISwitch) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                        DispatchQueue.main.async {
                            self?.notificationsOn = granted
                            toggle.setOn(granted, animated: true)
                            if !granted { self?.showNotifDeniedAlert() }
                        }
                    }
                case .denied:
                    self?.notificationsOn = false
                    toggle.setOn(false, animated: true)
                    self?.showNotifDeniedAlert()
                case .authorized, .provisional, .ephemeral:
                    self?.notificationsOn = toggle.isOn
                @unknown default:
                    self?.notificationsOn = toggle.isOn
                }
            }
        }
    }

    private func showNotifDeniedAlert() {
        let alert = UIAlertController(
            title: "Notifications Disabled",
            message: "To receive notifications, please enable them in Settings > Notifications > Bevodoro Study.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func handleLogout() {
        let alert = UIAlertController(
            title: "Log Out",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
            self.performLogout()
        })
        present(alert, animated: true)
    }

    private func performLogout() {
        do {
            try Auth.auth().signOut()
            UserManager.shared.currentUser = nil

            // Navigate back to the root (login/home) screen
            if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
                sceneDelegate.showLoginScreen()
            }
        } catch {
            let alert = UIAlertController(
                title: "Error",
                message: "Failed to log out. Please try again.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}

// MARK: - Pomodoro Picker (Apple built-in picker wheel, bottom sheet)
final class PomodoroPickerViewController: UIViewController {

    var values: [Int] = []              // e.g. [5, 10, 15] OR [1, 2, 3]
    var unitLabel: String = ""          // "min" or "cycles"
    var selectedValue: Int = 0          // initial value should be what the user already has
    var onSelect: ((Int) -> Void)?

    private let picker = UIPickerView()
    private let doneButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.delegate = self
        picker.dataSource = self
        
        if let index = values.firstIndex(of: selectedValue) {
            picker.selectRow(index, inComponent: 0, animated: false)
        }
        
        view.addSubview(picker)

        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = SettingsTypography.sourGummy(size: 17, weight: .semibold)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            doneButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            doneButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            picker.topAnchor.constraint(equalTo: doneButton.bottomAnchor, constant: 8),
            picker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            picker.heightAnchor.constraint(equalToConstant: 180)
        ])
    }

    @objc private func doneTapped() {
        onSelect?(selectedValue)
        dismiss(animated: true)
    }
}

extension PomodoroPickerViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        values.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let text = "\(values[row]) \(unitLabel)"
        let font = SettingsTypography.sourGummy(size: 21, weight: .regular)
        return NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: UIColor.label
        ])
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedValue = values[row]
    }
}

