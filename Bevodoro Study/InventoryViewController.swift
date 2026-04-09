//
//  InventoryViewController.swift
//  Bevodoro Study
//
//  Created by Anjie on 3/11/26.
//

import UIKit
import FirebaseAuth

class InventoryViewController: BaseViewController {

    @IBOutlet weak var inventorySegControl: UISegmentedControl!
    @IBOutlet weak var inventoryTableView: UITableView!
    @IBOutlet weak var inventoryCoinLabel: UILabel!

    private let catalogRows = ItemCatalog.shopCategories
    private let thumbnailSide: CGFloat = 60

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshUserFromServer()
    }

    @IBAction func inventorySegmentChanged(_ sender: UISegmentedControl) {
        inventoryTableView.reloadData()
    }

    private func refreshUserFromServer() {
        guard let uid = Auth.auth().currentUser?.uid ?? UserManager.shared.currentUser?.userID else {
            updateCoinButtonTitle()
            inventoryTableView.reloadData()
            return
        }
        User.fetch(uid: uid) { [weak self] user in
            guard let self else { return }
            if let user {
                UserManager.shared.currentUser = user
            }
            DispatchQueue.main.async {
                self.updateCoinButtonTitle()
                self.inventoryTableView.reloadData()
            }
        }
    }

    private func updateCoinButtonTitle() {
        let count = UserManager.shared.currentUser?.num_coins ?? 0
        inventoryCoinLabel.text = "\(count)"
    }

    private func categoryIndex() -> Int {
        let i = inventorySegControl.selectedSegmentIndex
        if i < 0 || i >= catalogRows.count {
            return 0
        }
        return i
    }

    /// Catalog order; food uses stacked counts on the user model.
    private func ownedRows() -> [(CatalogItem, Int)] {
        guard let user = UserManager.shared.currentUser else { return [] }
        switch categoryIndex() {
        case 0:
            return ItemCatalog.foodItems.compactMap { item in
                let n = user.food[item.key, default: 0]
                return n > 0 ? (item, n) : nil
            }
        case 1:
            let owned = Set(user.hats)
            return ItemCatalog.hatItems.filter { owned.contains($0.key) }.map { ($0, 1) }
        case 2:
            let owned = Set(user.backgrounds)
            return ItemCatalog.backgroundItems.filter { owned.contains($0.key) }.map { ($0, 1) }
        default:
            return []
        }
    }
}

extension InventoryViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        ownedRows().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: InventoryTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? InventoryTableViewCell else {
            return UITableViewCell()
        }
        let row = ownedRows()[indexPath.row]
        let cat = categoryIndex()
        let showsQuantity = cat == 0
        let onUse: (() -> Void)?
        switch cat {
        case 1:
            onUse = { [weak self] in self?.equipHat(key: row.0.key) }
        case 2:
            onUse = { [weak self] in self?.equipBackground(key: row.0.key) }
        default:
            onUse = nil
        }
        let canUse: Bool
        switch cat {
        case 1:
            if let user = UserManager.shared.currentUser {
                let effectiveHat = user.equippedHat.flatMap { user.hats.contains($0) ? $0 : nil }
                canUse = row.0.key != effectiveHat
            } else {
                canUse = true
            }
        case 2:
            if let user = UserManager.shared.currentUser {
                let fallback = ItemCatalog.dayBackgroundKey
                let chosen = user.equippedBkg ?? fallback
                let effectiveEquipped = user.backgrounds.contains(chosen) ? chosen : fallback
                canUse = row.0.key != effectiveEquipped
            } else {
                canUse = true
            }
        default:
            canUse = true
        }
        cell.configure(
            item: row.0,
            quantity: row.1,
            imageSide: thumbnailSide,
            showsQuantity: showsQuantity,
            onUse: onUse,
            canUse: canUse
        )
        return cell
    }
}

extension InventoryViewController {
    private func equipHat(key: String) {
        guard var user = UserManager.shared.currentUser else { return }
        guard user.hats.contains(key) else { return }
        user.equippedHat = (user.equippedHat == key) ? nil : key
        UserManager.shared.currentUser = user
        refreshHatButtons()
        user.saveToFirestore { err in
            if let err {
                print("save equipped hat:", err.localizedDescription)
            }
        }
    }

    private func refreshHatButtons() {
        let rows = ownedRows()
        guard let user = UserManager.shared.currentUser else { return }
        let effectiveHat = user.equippedHat.flatMap { user.hats.contains($0) ? $0 : nil }
        for cell in inventoryTableView.visibleCells {
            guard let invCell = cell as? InventoryTableViewCell,
                  let indexPath = inventoryTableView.indexPath(for: cell),
                  indexPath.row < rows.count else { continue }
            let itemKey = rows[indexPath.row].0.key
            invCell.updateUseButton(canUse: itemKey != effectiveHat)
        }
    }

    private func equipBackground(key: String) {
        guard var user = UserManager.shared.currentUser else { return }
        guard user.backgrounds.contains(key) else { return }
        user.equippedBkg = key
        UserManager.shared.currentUser = user
        inventoryTableView.reloadData()
        user.saveToFirestore { err in
            if let err {
                print("save equipped background:", err.localizedDescription)
            }
        }
    }
}
