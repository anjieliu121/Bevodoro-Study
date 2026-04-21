//
//  SettingsStyleCells.swift
//  Bevodoro Study
//
//  Settings screen UI: grouped rows with icon wells, subtitles, and accents.
//

import UIKit

// MARK: - Palette (Bevo Doro settings spec)

enum SettingsStyle {

    private static func hex(_ rgb: UInt32, alpha: CGFloat = 1) -> UIColor {
        UIColor(
            red: CGFloat((rgb >> 16) & 0xff) / 255,
            green: CGFloat((rgb >> 8) & 0xff) / 255,
            blue: CGFloat(rgb & 0xff) / 255,
            alpha: alpha
        )
    }

    /// Main accent — sliders (active), % labels, pomodoro values, nav tint
    static let accent = hex(0xE98B4A)
    /// Icons in wells, slider thumb (visible on track)
    static let iconActive = hex(0xC76A2A)
    /// Icon circle background
    static let iconWell = hex(0xF4E2D6)
    /// Screen background behind cards
    static let background = hex(0xF7F3EF)
    /// Grouped row / card fill
    static let card = hex(0xFFFFFF)
    /// Row / section dividers
    static let divider = hex(0xE5E5E5)
    /// Large “Settings” title (navigation)
    static let mainTitle = hex(0x3B2A1F)
    /// Primary row labels
    static let content = hex(0x2F2F2F)
    /// Subtitles, section headers, chevron
    static let subtitle = hex(0x8A8A8A)
    /// Slider track (inactive / max side)
    static let sliderInactive = hex(0xDADADA)
    static let toggleOn = hex(0xE98B4A)
    static let toggleOff = hex(0xD1D1D1)
}

// MARK: - Typography (Sour Gummy everywhere on Settings)

enum SettingsTypography {

    /// Names exposed by `SourGummy-VariableFont.ttf` (see Main / Timer storyboards).
    private static let regularPS = "SourGummy-Black_Regular"
    private static let semiboldPS = "SourGummy-Black_SemiBold"

    private static func postScriptNames(for weight: UIFont.Weight) -> [String] {
        switch weight {
        case .semibold, .bold, .heavy, .black:
            return [semiboldPS, regularPS, "SourGummy"]
        case .medium:
            return [semiboldPS, regularPS, "SourGummy"]
        default:
            return [regularPS, semiboldPS, "SourGummy"]
        }
    }

    static func sourGummy(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        for ps in postScriptNames(for: weight) {
            if let f = UIFont(name: ps, size: size) {
                return f
            }
        }
        return .systemFont(ofSize: size, weight: weight)
    }
}

// MARK: - Volume row (background music / Bevo sound)

final class VolumeSliderCell: UITableViewCell {

    static let reuseIdentifier = "VolumeSliderCell"

    private let iconWell: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 22
        v.clipsToBounds = true
        return v
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = SettingsStyle.iconActive
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = SettingsTypography.sourGummy(size: 16, weight: .semibold)
        label.textColor = SettingsStyle.content
        label.numberOfLines = 1
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = SettingsTypography.sourGummy(size: 13, weight: .regular)
        label.textColor = SettingsStyle.subtitle
        label.numberOfLines = 2
        return label
    }()

    private let percentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = SettingsTypography.sourGummy(size: 15, weight: .semibold)
        label.textColor = SettingsStyle.accent
        label.textAlignment = .right
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    let slider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.isContinuous = true
        slider.minimumTrackTintColor = SettingsStyle.accent
        slider.maximumTrackTintColor = SettingsStyle.sliderInactive
        slider.thumbTintColor = .white
        return slider
    }()

    private let textColumn = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        selectionStyle = .none
        backgroundColor = SettingsStyle.card
        contentView.backgroundColor = SettingsStyle.card

        iconWell.backgroundColor = SettingsStyle.iconWell
        iconWell.addSubview(iconImageView)

        textColumn.axis = .vertical
        textColumn.alignment = .leading
        textColumn.spacing = 2
        textColumn.translatesAutoresizingMaskIntoConstraints = false
        textColumn.addArrangedSubview(titleLabel)
        textColumn.addArrangedSubview(subtitleLabel)

        contentView.addSubview(iconWell)
        contentView.addSubview(textColumn)
        contentView.addSubview(percentLabel)
        contentView.addSubview(slider)

        NSLayoutConstraint.activate([
            iconWell.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            iconWell.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            iconWell.widthAnchor.constraint(equalToConstant: 44),
            iconWell.heightAnchor.constraint(equalToConstant: 44),

            iconImageView.centerXAnchor.constraint(equalTo: iconWell.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconWell.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),

            textColumn.leadingAnchor.constraint(equalTo: iconWell.trailingAnchor, constant: 12),
            textColumn.centerYAnchor.constraint(equalTo: iconWell.centerYAnchor),
            textColumn.trailingAnchor.constraint(lessThanOrEqualTo: percentLabel.leadingAnchor, constant: -8),

            percentLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            percentLabel.centerYAnchor.constraint(equalTo: iconWell.centerYAnchor),

            slider.topAnchor.constraint(equalTo: iconWell.bottomAnchor, constant: 12),
            slider.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            slider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        percentLabel.text = nil
        slider.removeTarget(nil, action: nil, for: .allEvents)
        imageView?.image = nil
    }

    func configure(iconSystemName: String, title: String, subtitle: String, value: Float, percentText: String) {
        iconImageView.image = UIImage(systemName: iconSystemName)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        percentLabel.text = percentText
        slider.value = max(0, min(1, value))
    }
}

// MARK: - Pomodoro / Log out row

final class SettingsDetailCell: UITableViewCell {

    static let reuseIdentifier = "SettingsDetailCell"

    private let iconWell = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let detailLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = SettingsTypography.sourGummy(size: 14, weight: .semibold)
        l.textColor = SettingsStyle.accent
        l.textAlignment = .right
        l.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return l
    }()
    private let chevron = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        selectionStyle = .default
        backgroundColor = SettingsStyle.card
        contentView.backgroundColor = SettingsStyle.card

        iconWell.translatesAutoresizingMaskIntoConstraints = false
        iconWell.layer.cornerRadius = 22
        iconWell.clipsToBounds = true
        iconWell.backgroundColor = SettingsStyle.iconWell

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = SettingsStyle.iconActive
        iconWell.addSubview(iconImageView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = SettingsTypography.sourGummy(size: 16, weight: .semibold)
        titleLabel.textColor = SettingsStyle.content

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = SettingsTypography.sourGummy(size: 13, weight: .regular)
        subtitleLabel.textColor = SettingsStyle.subtitle
        subtitleLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.translatesAutoresizingMaskIntoConstraints = false

        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.image = UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate)
        chevron.tintColor = SettingsStyle.subtitle
        chevron.contentMode = .scaleAspectFit

        contentView.addSubview(iconWell)
        contentView.addSubview(textStack)
        contentView.addSubview(detailLabel)
        contentView.addSubview(chevron)

        NSLayoutConstraint.activate([
            iconWell.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            iconWell.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconWell.widthAnchor.constraint(equalToConstant: 44),
            iconWell.heightAnchor.constraint(equalToConstant: 44),

            iconImageView.centerXAnchor.constraint(equalTo: iconWell.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconWell.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            textStack.leadingAnchor.constraint(equalTo: iconWell.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: detailLabel.leadingAnchor, constant: -8),

            detailLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -6),

            chevron.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            chevron.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        detailLabel.text = nil
        iconImageView.image = nil
    }

    func configure(iconSystemName: String, title: String, subtitle: String, detail: String?) {
        iconImageView.image = UIImage(systemName: iconSystemName)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        detailLabel.text = detail
        detailLabel.isHidden = (detail == nil || detail?.isEmpty == true)
    }
}

// MARK: - Toggle row (notifications, demo)

final class SettingsToggleCell: UITableViewCell {

    static let reuseIdentifier = "SettingsToggleCell"

    private let iconWell = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    let toggle = UISwitch()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        selectionStyle = .none
        backgroundColor = SettingsStyle.card
        contentView.backgroundColor = SettingsStyle.card

        iconWell.translatesAutoresizingMaskIntoConstraints = false
        iconWell.layer.cornerRadius = 22
        iconWell.clipsToBounds = true
        iconWell.backgroundColor = SettingsStyle.iconWell

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = SettingsStyle.iconActive
        iconWell.addSubview(iconImageView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = SettingsTypography.sourGummy(size: 16, weight: .semibold)
        titleLabel.textColor = SettingsStyle.content

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = SettingsTypography.sourGummy(size: 13, weight: .regular)
        subtitleLabel.textColor = SettingsStyle.subtitle
        subtitleLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.translatesAutoresizingMaskIntoConstraints = false

        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.onTintColor = SettingsStyle.toggleOn
        toggle.tintColor = SettingsStyle.toggleOff

        contentView.addSubview(iconWell)
        contentView.addSubview(textStack)
        contentView.addSubview(toggle)

        NSLayoutConstraint.activate([
            iconWell.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            iconWell.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconWell.widthAnchor.constraint(equalToConstant: 44),
            iconWell.heightAnchor.constraint(equalToConstant: 44),

            iconImageView.centerXAnchor.constraint(equalTo: iconWell.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconWell.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            textStack.leadingAnchor.constraint(equalTo: iconWell.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -12),

            toggle.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            toggle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        iconImageView.image = nil
        toggle.removeTarget(nil, action: nil, for: .allEvents)
    }

    func configure(iconSystemName: String, title: String, subtitle: String, isOn: Bool) {
        iconImageView.image = UIImage(systemName: iconSystemName)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        toggle.isOn = isOn
        toggle.onTintColor = SettingsStyle.toggleOn
        toggle.tintColor = SettingsStyle.toggleOff
    }
}
