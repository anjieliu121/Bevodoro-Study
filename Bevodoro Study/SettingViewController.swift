//
//  SettingViewController.swift
//  Bevodoro Study
//
//  Created by 阿清 on 2/28/26. Modified by Isabella 3-30-26
//

import UIKit
import UserNotifications

class SettingViewController: BaseViewController {

    enum SettingRow: Int, CaseIterable {
        case backgroundMusic = 0
        case bevosSound = 1
        case pomodoroTimer = 2
        case notifications = 3

        var title: String {
            switch self {
            case .backgroundMusic: return "Background Music"
            case .bevosSound: return "Bevo's Sound"
            case .pomodoroTimer: return "Pomodoro Timer"
            case .notifications: return "Notifications"
            }
        }

        var iconName: String {
            switch self {
            case .backgroundMusic: return "music.note"
            case .bevosSound: return "speaker.wave.2.fill"
            case .pomodoroTimer: return "clock"
            case .notifications: return "bell.fill"
            }
        }
    }

    static let pomodoroDurations = [1, 5, 10, 15, 20, 25, 30, 45, 60] // minutes

    /// UserDefaults key for Bevo's moo sound on/off. Use this when playing the moo sound.
    private static let bevosSoundKey = "bevosSoundEnabled"

    /// Whether Bevo's moo sound is enabled. Check this before playing the moo (e.g. on timer complete).
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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationHeader()
        setupTableView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let header = settingsTableView.tableHeaderView {
            var frame = header.frame
            frame.size.width = view.bounds.width
            header.frame = frame
            settingsTableView.tableHeaderView = header
        }
    }

    private func setupNavigationHeader() {
        let headerHeight: CGFloat = 56
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: headerHeight))
        headerView.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Settings"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        headerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])

        settingsTableView.tableHeaderView = headerView
    }

    private func setupTableView() {
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.backgroundColor = .systemBackground
        settingsTableView.separatorInset = UIEdgeInsets(top: 0, left: 56, bottom: 0, right: 0)
        settingsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
    }

    private func showPomodoroPicker() {
        let pickerVC = PomodoroPickerViewController()
        pickerVC.selectedMinutes = selectedPomodoroMinutes
        pickerVC.onSelect = { [weak self] minutes in
            self?.selectedPomodoroMinutes = minutes
            self?.settingsTableView.reloadData()
        }
        if let sheet = pickerVC.sheetPresentationController {
            let pickerSheetHeight: CGFloat = 280
            let detent = UISheetPresentationController.Detent.custom(resolver: { _ in pickerSheetHeight })
            sheet.detents = [detent]
            sheet.prefersGrabberVisible = true
        }
        present(pickerVC, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension SettingViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        SettingRow.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        cell.backgroundColor = .systemBackground
        cell.selectionStyle = .default

        guard let row = SettingRow(rawValue: indexPath.row) else { return cell }

        cell.textLabel?.text = row.title
        cell.textLabel?.font = .systemFont(ofSize: 17)
        cell.imageView?.image = UIImage(systemName: row.iconName)
        cell.imageView?.tintColor = .label

        switch row {
        case .backgroundMusic:
            cell.accessoryType = .none
            let toggle = UISwitch()
            toggle.isOn = MusicManager.shared.isMusicEnabled
            toggle.addTarget(self, action: #selector(backgroundMusicChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none
        case .bevosSound:
            cell.accessoryType = .none
            let toggle = UISwitch()
            toggle.isOn = bevosSoundOn
            toggle.addTarget(self, action: #selector(bevosSoundChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none
        case .pomodoroTimer:
            cell.accessoryView = nil
            cell.accessoryType = .disclosureIndicator
        case .notifications:
            cell.accessoryType = .none
            let toggle = UISwitch()
            toggle.isOn = notificationsOn
            toggle.addTarget(self, action: #selector(toggleNotif(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        settingsTableView.deselectRow(at: indexPath, animated: true)
        guard let row = SettingRow(rawValue: indexPath.row) else { return }
        if row == .pomodoroTimer {
            showPomodoroPicker()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        51
    }

    @objc private func backgroundMusicChanged(_ sender: UISwitch) {
        MusicManager.shared.toggleMusic(enabled: sender.isOn)
    }

    @objc private func bevosSoundChanged(_ sender: UISwitch) {
        bevosSoundOn = sender.isOn
        // Setting is persisted via isBevosSoundEnabled; any moo playback should check SettingViewController.isBevosSoundEnabled
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
}

// MARK: - Pomodoro Picker (Apple built-in picker wheel, bottom sheet)
final class PomodoroPickerViewController: UIViewController {

    // selected minutes should be whatever the user already has
    var selectedMinutes: Int = defaultTimerStudyMins
    var onSelect: ((Int) -> Void)?

    private let picker = UIPickerView()
    private let doneButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.delegate = self
        picker.dataSource = self
        if let index = SettingViewController.pomodoroDurations.firstIndex(of: selectedMinutes) {
            picker.selectRow(index, inComponent: 0, animated: false)
        }
        view.addSubview(picker)

        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
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
        UserManager.shared.currentUser?.settings.timerStudyMins = selectedMinutes
        UserManager.shared.currentUser?.saveToFirestore()
        onSelect?(selectedMinutes)
        dismiss(animated: true)
    }
}

extension PomodoroPickerViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        SettingViewController.pomodoroDurations.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        "\(SettingViewController.pomodoroDurations[row]) min"
    }

    func pickerView(_ pickerView: UIPickerView,
                    didSelectRow row: Int,
                    inComponent component: Int) {
        selectedMinutes = SettingViewController.pomodoroDurations[row]
    }
}
