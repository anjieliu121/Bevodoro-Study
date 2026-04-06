//
//  FoodCell.swift
//  Bevodoro Study
//
//  Trough cell: food image + quantity badge on the bottom-right of the image.
//  Register in code: collectionView.register(FoodCell.self, forCellWithReuseIdentifier: FoodCell.reuseIdentifier)
//  Storyboard: set cell class to FoodCell, reuse id "FoodCell", add image view + label with same outlet names if you use IB.
//

import UIKit

final class FoodCell: UICollectionViewCell {

    static let reuseIdentifier = "FoodCell"

    /// Draggable artwork (same target as before for pan-to-feed).
    let foodImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true
        iv.clipsToBounds = true
        return iv
    }()

    /// High-contrast count badge on the food (easy to see at a glance).
    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let base = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title3)
        if let roundedBold = base.withDesign(.rounded)?.withSymbolicTraits(.traitBold) {
            label.font = UIFont(descriptor: roundedBold, size: 17)
        } else {
            label.font = .boldSystemFont(ofSize: 17)
        }
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor(named: "BurntOrange") ?? .systemOrange
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.layer.borderWidth = 2.5
        label.layer.borderColor = UIColor.white.cgColor
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear

        guard foodImageView.superview == nil else { return }
        contentView.addSubview(foodImageView)
        contentView.addSubview(quantityLabel)

        NSLayoutConstraint.activate([
            foodImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            foodImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            foodImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            foodImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            quantityLabel.trailingAnchor.constraint(equalTo: foodImageView.trailingAnchor, constant: -3),
            quantityLabel.bottomAnchor.constraint(equalTo: foodImageView.bottomAnchor, constant: -3),
            quantityLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 28),
            quantityLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 32)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        foodImageView.gestureRecognizers?.forEach { foodImageView.removeGestureRecognizer($0) }
        foodImageView.isHidden = false
        foodImageView.image = nil
        foodImageView.accessibilityLabel = nil
        quantityLabel.isHidden = false
        quantityLabel.text = nil
    }

    func configure(with item: FoodItem) {
        foodImageView.image = UIImage(named: item.imageName)
        foodImageView.accessibilityLabel = "\(item.imageName), quantity \(item.quantity)"
        // "×" makes it read as a count, extra spaces = wider pill for big numbers.
        quantityLabel.text = "  ×\(item.quantity)  "
        quantityLabel.isHidden = item.quantity <= 0
    }

    /// While the user drags the food image, hide the badge so only the floating copy is visible.
    func setQuantityBadgeHidden(_ hidden: Bool) {
        quantityLabel.isHidden = hidden
    }
}
