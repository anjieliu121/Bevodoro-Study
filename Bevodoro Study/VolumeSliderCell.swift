import UIKit

final class VolumeSliderCell: UITableViewCell {

    static let reuseIdentifier = "VolumeSliderCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private let percentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17)
        label.textColor = .secondaryLabel
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
        return slider
    }()

    private let topRow = UIStackView()
    private let mainStack = UIStackView()

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

        topRow.axis = .horizontal
        topRow.alignment = .firstBaseline
        topRow.distribution = .fill
        topRow.spacing = 10
        topRow.translatesAutoresizingMaskIntoConstraints = false
        topRow.addArrangedSubview(titleLabel)
        topRow.addArrangedSubview(percentLabel)

        mainStack.axis = .vertical
        mainStack.alignment = .fill
        mainStack.distribution = .fill
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(topRow)
        mainStack.addArrangedSubview(slider)

        contentView.addSubview(mainStack)

        // Keep the system `imageView` on the left; align our content with `textLabel`’s typical start.
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 56),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        percentLabel.text = nil
        slider.removeTarget(nil, action: nil, for: .allEvents)
    }

    func configure(iconSystemName: String, title: String, value: Float, percentText: String) {
        imageView?.image = UIImage(systemName: iconSystemName)
        imageView?.tintColor = .label
        titleLabel.text = title
        percentLabel.text = percentText
        slider.value = max(0, min(1, value))
    }
}

