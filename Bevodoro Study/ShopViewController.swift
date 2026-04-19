//
//  ShopViewController.swift
//  Bevodoro Study
//
//  Created by Anjie on 2/25/26.
//

import UIKit
import FirebaseAuth

class ShopViewController: BaseViewController {

    @IBOutlet weak var shopSegContrl: UISegmentedControl!
    @IBOutlet weak var shopTableView: UITableView!
    @IBOutlet weak var coinLabel: UILabel!

    private let catalogRows = ItemCatalog.shopCategories
    private let thumbnailSide: CGFloat = 60

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        HapticsManager.shared.prepareForInteraction()
        refreshUserFromServer()
    }

    @IBAction func shopSegmentChanged(_ sender: UISegmentedControl) {
        HapticsManager.shared.selection()
        shopTableView.reloadData()
    }

    private func refreshUserFromServer() {
        guard let uid = Auth.auth().currentUser?.uid ?? UserManager.shared.currentUser?.userID else {
            updateCoinButtonTitle()
            shopTableView.reloadData()
            return
        }
        User.fetch(uid: uid) { [weak self] user in
            guard let self else { return }
            if let user {
                UserManager.shared.currentUser = user
            }
            DispatchQueue.main.async {
                self.updateCoinButtonTitle()
                self.shopTableView.reloadData()
            }
        }
    }

    private func updateCoinButtonTitle() {
        let count = UserManager.shared.currentUser?.num_coins ?? 0
        coinLabel.text = "\(count)"
    }

    private func categoryIndex() -> Int {
        let i = shopSegContrl.selectedSegmentIndex
        if i < 0 || i >= catalogRows.count {
            return 0
        }
        return i
    }

    private func userHasCatalogItem(item: CatalogItem, categoryIndex: Int, user: User) -> Bool {
        switch categoryIndex {
        case 0:
            return false
        case 1:
            return user.hats.contains(item.key)
        case 2:
            return user.backgrounds.contains(item.key)
        default:
            return false
        }
    }

    private func purchase(item: CatalogItem, categoryIndex: Int) {
        guard var user = UserManager.shared.currentUser else { return }
        guard user.num_coins >= item.cost else {
            HapticsManager.shared.warning()
            return
        }

        switch categoryIndex {
        case 0:
            user.subtractCoins(item.cost)
            user.food[item.key, default: 0] += 1

        case 1:
            guard !user.hats.contains(item.key) else {
                HapticsManager.shared.warning()
                return
            }
            user.subtractCoins(item.cost)
            user.hats.append(item.key)

        case 2:
            guard !user.backgrounds.contains(item.key) else {
                HapticsManager.shared.warning()
                return
            }
            user.subtractCoins(item.cost)
            user.backgrounds.append(item.key)

        default:
            return
        }

        UserManager.shared.currentUser = user
        HapticsManager.shared.success()
        user.saveToFirestore { err in
            if let err {
                print("save after purchase:", err.localizedDescription)
            }
        }
        updateCoinButtonTitle()
        shopTableView.reloadData()
    }
}

extension ShopViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        catalogRows[categoryIndex()].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ShopTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? ShopTableViewCell else {
            return UITableViewCell()
        }

        let cat = categoryIndex()
        let item = catalogRows[cat][indexPath.row]
        let user = UserManager.shared.currentUser
        let coins = user?.num_coins ?? 0

        // Food and medicine stack; hats and backgrounds are one-time unlocks.
        let oneTimeCategory = cat == 1 || cat == 2
        let alreadyHave = user.map { userHasCatalogItem(item: item, categoryIndex: cat, user: $0) } ?? false
        let lockedOneTimePurchase = oneTimeCategory && alreadyHave
        let canAfford = coins >= item.cost
        let canPurchase = !lockedOneTimePurchase && canAfford

        cell.configure(
            item: item,
            imageSide: thumbnailSide,
            canPurchase: canPurchase
        )

        cell.onBuyTapped = { [weak self] in
            guard let self else { return }
            self.purchase(item: item, categoryIndex: cat)
        }

        return cell
    }
}
