//
//  InventoryViewController.swift
//  Bevodoro Study
//
//  Created by Anjie on 3/11/26.
//

import UIKit

struct InventoryItem {
    let key: String
    let displayName: String
    let icon: String
    var quantity: Int
    var isEquipped: Bool
    var isConsumable: Bool
}

class InventoryItemCell: UITableViewCell {

    private let cardView = UIView()
    let iconLabel = UILabel()
    let iconImageView = UIImageView()
    let nameLabel = UILabel()
    let quantityLabel = UILabel()
    let actionButton = UIButton(type: .system)

    var onAction: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        iconLabel.font = UIFont.systemFont(ofSize: 48)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(iconLabel)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.clipsToBounds = true
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.isHidden = true
        cardView.addSubview(iconImageView)

        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nameLabel)

        quantityLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        quantityLabel.textColor = .darkGray
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(quantityLabel)

        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.layer.cornerRadius = 14
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        cardView.addSubview(actionButton)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),

            iconLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 52),
            iconLabel.heightAnchor.constraint(equalToConstant: 52),

            iconImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 52),
            iconImageView.heightAnchor.constraint(equalToConstant: 52),

            nameLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),

            quantityLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            quantityLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),

            actionButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            actionButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 60),
            actionButton.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    @objc private func actionTapped() {
        onAction?()
    }

    func configure(with item: InventoryItem) {
        if let image = UIImage(named: item.icon) {
            iconImageView.image = image
            iconImageView.isHidden = false
            iconLabel.text = nil
        } else {
            iconImageView.image = nil
            iconImageView.isHidden = true
            iconLabel.text = item.icon
        }
        nameLabel.text = item.displayName

        if item.isConsumable {
            quantityLabel.text = "x \(item.quantity)"
            quantityLabel.isHidden = false
            actionButton.setTitle("Use", for: .normal)
            actionButton.backgroundColor = UIColor(red: 0.886, green: 0.412, blue: 0.227, alpha: 1.0)
            cardView.backgroundColor = .white
        } else if item.isEquipped {
            quantityLabel.isHidden = true
            actionButton.setTitle("On", for: .normal)
            actionButton.backgroundColor = UIColor.systemGreen
            cardView.backgroundColor = UIColor(red: 0.85, green: 1.0, blue: 0.85, alpha: 1.0)
        } else {
            quantityLabel.isHidden = true
            actionButton.setTitle("Use", for: .normal)
            actionButton.backgroundColor = UIColor(red: 0.886, green: 0.412, blue: 0.227, alpha: 1.0)
            cardView.backgroundColor = .white
        }
    }
}

class InventoryViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var inventorySegControl: UISegmentedControl!
    @IBOutlet weak var inventoryTableView: UITableView!
    @IBOutlet weak var inventoryCoinButton: UIButton!

    var inventoryData: [[InventoryItem]] = [[], [], [], []]

    override func viewDidLoad() {
        super.viewDidLoad()
        inventoryTableView.delegate = self
        inventoryTableView.dataSource = self
        inventoryTableView.register(InventoryItemCell.self, forCellReuseIdentifier: "InventoryItemCell")
        inventoryTableView.separatorStyle = .none
        inventoryTableView.backgroundColor = .clear
        inventorySegControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rebuildInventoryData()
        updateCoinDisplay()
        inventoryTableView.reloadData()
    }

    private func rebuildInventoryData() {
        guard let user = UserManager.shared.currentUser else {
            inventoryData = [[], [], [], []]
            return
        }

        let foodKeys = Set(ItemCatalog.foodItems.map { $0.key })
        let medicineKeys = Set(ItemCatalog.medicineItems.map { $0.key })

        // Food (index 0): consumable items from user.food that are in the food catalog
        let foodItems: [InventoryItem] = user.food.compactMap { key, qty in
            guard foodKeys.contains(key), qty > 0 else { return nil }
            return InventoryItem(
                key: key,
                displayName: ItemCatalog.displayName(forKey: key),
                icon: ItemCatalog.icon(forKey: key),
                quantity: qty,
                isEquipped: false,
                isConsumable: true
            )
        }.sorted { $0.displayName < $1.displayName }

        // Medicine (index 1): consumable items from user.food that are in the medicine catalog
        let medicineItems: [InventoryItem] = user.food.compactMap { key, qty in
            guard medicineKeys.contains(key), qty > 0 else { return nil }
            return InventoryItem(
                key: key,
                displayName: ItemCatalog.displayName(forKey: key),
                icon: ItemCatalog.icon(forKey: key),
                quantity: qty,
                isEquipped: false,
                isConsumable: true
            )
        }.sorted { $0.displayName < $1.displayName }

        // Clothes (index 2): hats with equipped state
        let hatItems: [InventoryItem] = user.hats.map { key in
            InventoryItem(
                key: key,
                displayName: ItemCatalog.displayName(forKey: key),
                icon: ItemCatalog.icon(forKey: key),
                quantity: 1,
                isEquipped: user.equippedHat == key,
                isConsumable: false
            )
        }

        // Backgrounds (index 3): backgrounds with equipped state
        let bgItems: [InventoryItem] = user.backgrounds.map { key in
            InventoryItem(
                key: key,
                displayName: ItemCatalog.displayName(forKey: key),
                icon: ItemCatalog.icon(forKey: key),
                quantity: 1,
                isEquipped: user.equippedBkg == key,
                isConsumable: false
            )
        }

        inventoryData = [foodItems, medicineItems, hatItems, bgItems]
    }

    @objc func segmentChanged() {
        inventoryTableView.reloadData()
    }

    private func coinButtonAttributedText(_ value: Int) -> NSAttributedString {
        let text = NSMutableAttributedString(string: " \(value)")
        if let image = UIImage(named: "Coin") {
            let attachment = NSTextAttachment()
            attachment.image = image
            attachment.bounds = CGRect(x: 0, y: -2, width: 16, height: 16)
            text.insert(NSAttributedString(attachment: attachment), at: 0)
        } else {
            text.insert(NSAttributedString(string: "Coin "), at: 0)
        }
        return text
    }

    func updateCoinDisplay() {
        let coins = UserManager.shared.currentUser?.num_coins ?? 0
        inventoryCoinButton.setImage(nil, for: .normal)
        inventoryCoinButton.setAttributedTitle(coinButtonAttributedText(coins), for: .normal)
        inventoryCoinButton.setTitleColor(.black, for: .normal)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inventoryData[inventorySegControl.selectedSegmentIndex].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InventoryItemCell", for: indexPath) as! InventoryItemCell
        let item = inventoryData[inventorySegControl.selectedSegmentIndex][indexPath.row]
        cell.configure(with: item)
        cell.onAction = { [weak self] in
            self?.useItem(at: indexPath)
        }
        return cell
    }

    // MARK: - Use / Equip Logic

    func useItem(at indexPath: IndexPath) {
        guard var user = UserManager.shared.currentUser else { return }
        let segIndex = inventorySegControl.selectedSegmentIndex
        let item = inventoryData[segIndex][indexPath.row]

        switch segIndex {
        case 0, 1:
            // Consumable: decrement quantity, remove if zero
            let currentQty = user.food[item.key] ?? 0
            if currentQty <= 1 {
                user.food.removeValue(forKey: item.key)
            } else {
                user.food[item.key] = currentQty - 1
            }

        case 2:
            // Equip hat (toggle off if already equipped)
            if user.equippedHat == item.key {
                user.equippedHat = nil
            } else {
                user.equippedHat = item.key
            }

        case 3:
            // Equip background (toggle off if already equipped)
            if user.equippedBkg == item.key {
                user.equippedBkg = nil
            } else {
                user.equippedBkg = item.key
            }

        default:
            break
        }

        UserManager.shared.currentUser = user
        user.saveToFirestore()

        rebuildInventoryData()
        inventoryTableView.reloadData()
    }
}
