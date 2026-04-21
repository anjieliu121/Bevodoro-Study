//
//  MinigameMenuViewController.swift
//  Bevodoro Study
//
//  Created by Yim, Isabella H on 4/20/26.
//


import UIKit

class MinigameMenuViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    private struct Minigame {
        let title: String
        let storyboardName: String
        let storyboardID: String
    }
    
    private let minigames = [
        Minigame(title: "Card Guesser", storyboardName: "CardGuesser", storyboardID: "CardGuesserViewController"),
        Minigame(title: "Chaser", storyboardName: "Chaser", storyboardID: "ChaserViewController")
    ]

    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        table.backgroundColor = .clear
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    private func setupTableView() {
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        minigames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = minigames[indexPath.row].title
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let minigame = minigames[indexPath.row]
        let storyboard = UIStoryboard(name: minigame.storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: minigame.storyboardID)
        navigationController?.pushViewController(vc, animated: true)
    }
}
