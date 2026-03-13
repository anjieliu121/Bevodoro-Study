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

    let iconLabel = UILabel()
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
        let card = UIView()
        card.tag = 100
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        iconLabel.font = UIFont.systemFont(ofSize: 48)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconLabel)

        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(nameLabel)

        quantityLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        quantityLabel.textColor = .darkGray
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(quantityLabel)

        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.layer.cornerRadius = 14
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        card.addSubview(actionButton)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),

            iconLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),

            quantityLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            quantityLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),

            actionButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            actionButton.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 60),
            actionButton.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    @objc private func actionTapped() {
        onAction?()
    }

    func configure(with item: InventoryItem) {
        iconLabel.text = item.icon
        nameLabel.text = item.displayName

        let card = contentView.viewWithTag(100)

        if item.isConsumable {
            quantityLabel.text = "x \(item.quantity)"
            quantityLabel.isHidden = false
            actionButton.setTitle("Use", for: .normal)
            actionButton.backgroundColor = UIColor(red: 0.886, green: 0.412, blue: 0.227, alpha: 1.0)
            card?.backgroundColor = .white
        } else if item.isEquipped {
            quantityLabel.isHidden = true
            actionButton.setTitle("On", for: .normal)
            actionButton.backgroundColor = UIColor.systemGreen
            card?.backgroundColor = UIColor(red: 0.85, green: 1.0, blue: 0.85, alpha: 1.0)
        } else {
            quantityLabel.isHidden = true
            actionButton.setTitle("Use", for: .normal)
            actionButton.backgroundColor = UIColor(red: 0.886, green: 0.412, blue: 0.227, alpha: 1.0)
            card?.backgroundColor = .white
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

    func updateCoinDisplay() {
        let coins = UserManager.shared.currentUser?.num_coins ?? 0
        inventoryCoinButton.setTitle("\u{1FA99}\(coins)", for: .normal)
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
