//
//  ShopTableViewCell.swift
//  Bevodoro Study
//
//  Created by Anjie on 4/1/26.
//

import UIKit

final class ShopTableViewCell: UITableViewCell {

    static let reuseIdentifier = "ShopTableViewCell"

    @IBOutlet private weak var itemImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var coinImageView: UIImageView!
    @IBOutlet private weak var costLabel: UILabel!
    @IBOutlet private weak var buyButton: UIButton!

    var onBuyTapped: (() -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        itemImageView.image = nil
        onBuyTapped = nil
    }

    /// - Parameter canPurchase: When true, the buy button uses the purchasable style and accepts taps.
    func configure(item: CatalogItem, imageSide: CGFloat, canPurchase: Bool) {
        nameLabel.text = item.displayName
        costLabel.text = "\(item.cost)"
        itemImageView.image = ShopTableViewCell.catalogImage(for: item, side: imageSide)

        setBuyButton(canPurchase: canPurchase)
        coinImageView.isHidden = false
        costLabel.isHidden = false
    }

    private func setBuyButton(canPurchase: Bool) {
        buyButton.isEnabled = true
        buyButton.isUserInteractionEnabled = canPurchase
        if canPurchase {
            buyButton.accessibilityTraits.remove(.notEnabled)
        } else {
            buyButton.accessibilityTraits.insert(.notEnabled)
        }

        var config = buyButton.configuration ?? .filled()
        if canPurchase {
            config.background.backgroundColor = UIColor(named: "BurntOrange")
        } else {
            config.background.backgroundColor = .systemGray
        }
        buyButton.configuration = config
    }

    @IBAction func buyButtonTapped(_ sender: UIButton) {
        onBuyTapped?()
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
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
            ]
            let s = emoji as NSString
            let textSize = s.size(withAttributes: attrs)
            let origin = CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            )
            s.draw(at: origin, withAttributes: attrs)
        }
    }
}
