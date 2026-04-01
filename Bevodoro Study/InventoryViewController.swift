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
    @IBOutlet weak var inventoryCoinButton: UIButton!

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
        inventoryCoinButton.setTitle("\(count)", for: .normal)
    }

    private func categoryIndex() -> Int {
        let i = inventorySegControl.selectedSegmentIndex
        if i < 0 || i >= catalogRows.count {
            return 0
        }
        return i
    }

    /// Catalog order; food uses stacked counts from `User.food`.
    private func ownedRows() -> [(CatalogItem, Int)] {
        guard let user = UserManager.shared.currentUser else { return [] }
        switch categoryIndex() {
        case 0:
            return ItemCatalog.foodItems.compactMap { item in
                let n = user.food[item.key, default: 0]
                return n > 0 ? (item, n) : nil
            }
        case 1:
            let owned = Set(user.medicine ?? [])
            return ItemCatalog.medicineItems.filter { owned.contains($0.key) }.map { ($0, 1) }
        case 2:
            let owned = Set(user.hats)
            return ItemCatalog.hatItems.filter { owned.contains($0.key) }.map { ($0, 1) }
        case 3:
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
        cell.configure(item: row.0, quantity: row.1, imageSide: thumbnailSide)
        return cell
    }
}
