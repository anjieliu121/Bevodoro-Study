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

    func configure(item: CatalogItem, quantity: Int, imageSide: CGFloat) {
        nameLabel.text = item.displayName
        amountLabel.text = "×\(quantity)"
        itemImageView.image = Self.catalogImage(for: item, side: imageSide)
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
}
