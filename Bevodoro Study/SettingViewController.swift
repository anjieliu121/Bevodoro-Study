//
//  SettingViewController.swift
//  Bevodoro Study
//
//  Created by 阿清 on 2/28/26.
//

import UIKit

class SettingViewController: UIViewController {

    enum SettingRow: Int, CaseIterable {
        case backgroundMusic = 0
        case bevosSound = 1
        case pomodoroTimer = 2

        var title: String {
            switch self {
            case .backgroundMusic: return "Background Music"
            case .bevosSound: return "Bevo's Sound"
            case .pomodoroTimer: return "Pomodoro Timer"
            }
        }

        var iconName: String {
            switch self {
            case .backgroundMusic: return "music.note"
            case .bevosSound: return "speaker.wave.2.fill"
            case .pomodoroTimer: return "clock"
            }
        }
    }

    static let pomodoroDurations = [15, 25, 30, 45, 60] // minutes

    @IBOutlet weak var tableView: UITableView!

    /// Resolves table view from outlet or from view hierarchy (avoids crash if outlet not connected).
    private var settingsTableView: UITableView {
        if let tv = tableView { return tv }
        if let tv = view.subviews.first(where: { $0 is UITableView }) as? UITableView { return tv }
        fatalError("SettingViewController: no UITableView found. Connect the tableView outlet in the storyboard.")
    }

    private var backgroundMusicOn = false
    private var bevosSoundOn = false
    private var selectedPomodoroMinutes = 25

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

        let backButton = UIButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        headerView.addSubview(backButton)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Settings"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        headerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])

        settingsTableView.tableHeaderView = headerView
    }

    @objc private func backTapped() {
        dismiss(animated: true)
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
            toggle.isOn = backgroundMusicOn
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
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        settingsTableView.deselectRow(at: indexPath, animated: true)
        if SettingRow(rawValue: indexPath.row) == .pomodoroTimer {
            showPomodoroPicker()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        51
    }

    @objc private func backgroundMusicChanged(_ sender: UISwitch) {
        backgroundMusicOn = sender.isOn
    }

    @objc private func bevosSoundChanged(_ sender: UISwitch) {
        bevosSoundOn = sender.isOn
    }
}

// MARK: - Pomodoro Picker (Apple built-in picker wheel, bottom sheet)
final class PomodoroPickerViewController: UIViewController {

    var selectedMinutes: Int = 25
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
        let row = picker.selectedRow(inComponent: 0)
        let minutes = SettingViewController.pomodoroDurations[row]
        onSelect?(minutes)
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
}
