//
//  ShopViewController.swift
//  Bevodoro Study
//
//  Created by Anjie on 2/25/26.
//

import UIKit

// isabella wuz here # 3

struct ShopItem {
    let name: String
    let icon: String
    let cost: Int
    var owned: Bool
}

class ShopItemCell: UITableViewCell {

    let iconLabel = UILabel()
    let nameLabel = UILabel()
    let costLabel = UILabel()
    let buyButton = UIButton(type: .system)

    var onBuy: (() -> Void)?

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

        costLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        costLabel.textColor = .systemOrange
        costLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(costLabel)

        buyButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        buyButton.setTitleColor(.white, for: .normal)
        buyButton.backgroundColor = UIColor(red: 0.886, green: 0.412, blue: 0.227, alpha: 1.0)
        buyButton.layer.cornerRadius = 14
        buyButton.translatesAutoresizingMaskIntoConstraints = false
        buyButton.addTarget(self, action: #selector(buyTapped), for: .touchUpInside)
        card.addSubview(buyButton)

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

            costLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            costLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),

            buyButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            buyButton.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            buyButton.widthAnchor.constraint(equalToConstant: 60),
            buyButton.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    @objc private func buyTapped() {
        onBuy?()
    }

    func configure(with item: ShopItem) {
        iconLabel.text = item.icon
        nameLabel.text = item.name
        costLabel.text = "🪙\(item.cost)"
        if item.owned {
            buyButton.setTitle("owned", for: .normal)
            buyButton.backgroundColor = .systemGray4
            buyButton.isEnabled = false
        } else {
            buyButton.setTitle("Buy", for: .normal)
            buyButton.backgroundColor = UIColor(red: 0.886, green: 0.412, blue: 0.227, alpha: 1.0)
            buyButton.isEnabled = true
        }
    }
}

class ShopViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var shopSegContrl: UISegmentedControl!
    @IBOutlet weak var shopTableView: UITableView!
    @IBOutlet weak var coinButton: UIButton!

    var coins = 20

    var shopData: [[ShopItem]] = [
        // Food
        [
            ShopItem(name: "Apple", icon: "🍎", cost: 10, owned: false),
            ShopItem(name: "Banana", icon: "🍌", cost: 15, owned: false),
            ShopItem(name: "Cookie", icon: "🍪", cost: 20, owned: false),
        ],
        // Medicine
        [
            ShopItem(name: "Pill", icon: "💊", cost: 60, owned: false),
            ShopItem(name: "Syringe", icon: "💉", cost: 80, owned: false),
            ShopItem(name: "Herb", icon: "🌿", cost: 40, owned: false),
        ],
        // Clothes
        [
            ShopItem(name: "Cowboy hat", icon: "🤠", cost: 60, owned: false),
            ShopItem(name: "Sunglasses", icon: "🕶️", cost: 45, owned: false),
            ShopItem(name: "Scarf", icon: "🧣", cost: 35, owned: false),
        ],
        // Backgrounds
        [
            ShopItem(name: "Night", icon: "🌙", cost: 100, owned: false),
            ShopItem(name: "Day", icon: "☀️", cost: 100, owned: false),
            ShopItem(name: "Ocean", icon: "🌊", cost: 120, owned: false),
        ],
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        shopTableView.delegate = self
        shopTableView.dataSource = self
        shopTableView.register(ShopItemCell.self, forCellReuseIdentifier: "ShopItemCell")
        shopTableView.separatorStyle = .none
        shopTableView.backgroundColor = .clear
        shopSegContrl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        updateCoinDisplay()
    }

    @objc func segmentChanged() {
        shopTableView.reloadData()
    }

    func updateCoinDisplay() {
        coinButton.setTitle("🪙\(coins)", for: .normal)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shopData[shopSegContrl.selectedSegmentIndex].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ShopItemCell", for: indexPath) as! ShopItemCell
        let item = shopData[shopSegContrl.selectedSegmentIndex][indexPath.row]
        cell.configure(with: item)
        cell.onBuy = { [weak self] in
            self?.buyItem(at: indexPath)
        }
        return cell
    }

    // MARK: - Buy Logic

    func buyItem(at indexPath: IndexPath) {
        let segIndex = shopSegContrl.selectedSegmentIndex
        let item = shopData[segIndex][indexPath.row]

        if item.owned { return }

        if coins < item.cost {
            let alert = UIAlertController(
                title: "Error",
                message: "You don't have enough coins to buy this item",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Okay", style: .default))
            present(alert, animated: true)
            return
        }

        coins -= item.cost
        shopData[segIndex][indexPath.row].owned = true
        updateCoinDisplay()
        shopTableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
