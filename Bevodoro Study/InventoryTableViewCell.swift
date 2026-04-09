//
//  InventoryTableViewCell.swift
//  Bevodoro Study
//
//  Created by Anjie on 4/1/26.
//

import UIKit

final class InventoryTableViewCell: UITableViewCell {

    static let reuseIdentifier = "InventoryTableViewCell"

    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var useButton: UIButton!

    private var onUseTapped: (() -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        itemImageView.image = nil
        onUseTapped = nil
    }

    /// - Parameter canUse: When false (e.g. background already equipped), matches shop’s grey disabled buy button.
    func configure(
        item: CatalogItem,
        quantity: Int,
        imageSide: CGFloat,
        showsQuantity: Bool,
        onUse: (() -> Void)? = nil,
        canUse: Bool = true
    ) {
        onUseTapped = onUse
        useButton.isHidden = onUse == nil
        if onUse != nil {
            setUseButton(canUse: canUse)
        }
        nameLabel.text = item.displayName
        if showsQuantity {
            amountLabel.isHidden = false
            amountLabel.text = "×\(quantity)"
        } else {
            amountLabel.isHidden = true
            amountLabel.text = nil
        }
        itemImageView.image = Self.catalogImage(for: item, side: imageSide)
    }

    func updateUseButton(canUse: Bool) {
        setUseButton(canUse: canUse)
    }

    private func setUseButton(canUse: Bool) {
        useButton.isEnabled = true
        useButton.isUserInteractionEnabled = true
        if canUse {
            useButton.accessibilityTraits.remove(.notEnabled)
        } else {
            useButton.accessibilityTraits.insert(.notEnabled)
        }
        var config = useButton.configuration ?? .filled()
        if canUse {
            config.background.backgroundColor = UIColor(named: "BurntOrange")
        } else {
            config.background.backgroundColor = .systemGray
        }
        useButton.configuration = config
    }

    private static func catalogImage(for item: CatalogItem, side: CGFloat) -> UIImage? {
        if let named = UIImage(named: item.icon) {
            return named
        }
        return emojiImage(item.icon, side: side)
    }

    private static func emojiImage(_ emoji: String, side: CGFloat) -> UIImage? {
        let size = CGSize(width: side, height: side)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let font = UIFont.systemFont(ofSize: side * 0.52)
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            let s = emoji as NSString
            let textSize = s.size(withAttributes: attrs)
            let origin = CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            )
            s.draw(at: origin, withAttributes: attrs)
        }
    }
    @IBAction func useButtonPressed(_ sender: Any) {
        onUseTapped?()
    }
}
