//
//  MinigameMenuViewController.swift
//  Bevodoro Study
//
//  Created by Yim, Isabella H on 4/20/26.
//
// (A)I tried my best

let coinsEarnedPerMinigame = 1

import UIKit

class MinigameMenuViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    private struct Minigame {
        let title: String
        let storyboardName: String
        let storyboardID: String
        let systemIconName: String
        let desc: String
    }
    let backupIconName = "gamecontroller.fill"
    
    private let minigames = [
        Minigame(title: "Card Guesser", storyboardName: "CardGuesser", storyboardID: "CardGuesserViewController", systemIconName: "suit.spade.fill", desc: "Guess what card Bevo is thinking of"),
        Minigame(title: "Chaser", storyboardName: "Chaser", storyboardID: "ChaserViewController", systemIconName: "forward.fill", desc: "Guide bevo to eat apples")
    ]

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        table.backgroundColor = .clear
        table.sectionHeaderTopPadding = 8
        return table
    }()
    
    private let backgroundImageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.image = UIImage(named: "texture_ut_light")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        view.insertSubview(backgroundImageView, at: 0)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = "Minigames"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = SettingsStyle.accent
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        let navTitleFont = SettingsTypography.sourGummy(size: 17, weight: .semibold)
        let navLargeFont = SettingsTypography.sourGummy(size: 34, weight: .semibold)
        appearance.titleTextAttributes = [
            .foregroundColor: SettingsStyle.mainTitle,
            .font: navTitleFont
        ]
        appearance.largeTitleTextAttributes = [
            .font: navLargeFont,
            .foregroundColor: SettingsStyle.mainTitle
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }
    private func setupTableView() {
        view.addSubview(tableView)

        // Match Settings table styling
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = SettingsStyle.divider
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 0)

        // Register the Settings-style cell (why? idk)
        tableView.register(
            SettingsDetailCell.self,
            forCellReuseIdentifier: SettingsDetailCell.reuseIdentifier
        )

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
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        72
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let game = minigames[indexPath.row]

        let cell = tableView.dequeueReusableCell(
            withIdentifier: SettingsDetailCell.reuseIdentifier,
            for: indexPath
        ) as! SettingsDetailCell  // use settings styling

        cell.configure(
            iconSystemName: game.systemIconName,
            title: game.title,
            subtitle: game.desc,
            detail: nil
        )

        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let minigame = minigames[indexPath.row]
        let storyboard = UIStoryboard(name: minigame.storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: minigame.storyboardID)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    static func awardCoins() -> Int {
        UserManager.shared.currentUser?.addCoins(coinsEarnedPerMinigame)
        UserManager.shared.currentUser?.saveToFirestore()
        return coinsEarnedPerMinigame
    }
}


