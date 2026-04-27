//
//  MinigameMenuViewController.swift
//  Bevodoro Study
//
//  Created by Yim, Isabella H on 4/20/26.
//
// (A)I tried my best

let coinsEarnedPerMinigame = 1

import UIKit

class MinigameMenuViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

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
        Minigame(title: "Three Match", storyboardName: "ThreeMatch", storyboardID: "ThreeMatchViewController", systemIconName: "square.grid.3x3.fill", desc: "Swap tiles and match rows of three"),
        Minigame(title: "Tap the Bevo", storyboardName: "TapBevo", storyboardID: "TapBevoViewController", systemIconName: "hand.tap.fill", desc: "Tap Bevo as fast as you can!"),
        Minigame(title: "Pong", storyboardName: "Pong", storyboardID: "PongViewController", systemIconName: "circle.fill", desc: "Keep the ball in play!")
    ]

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12

        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.delegate = self
        collection.dataSource = self
        collection.backgroundColor = .clear
        collection.alwaysBounceVertical = true
        collection.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        collection.register(MinigameTileCell.self, forCellWithReuseIdentifier: MinigameTileCell.reuseIdentifier)
        return collection
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
        
        setupCollectionView()
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
    private func setupCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        minigames.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let game = minigames[indexPath.item]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MinigameTileCell.reuseIdentifier,
            for: indexPath
        ) as! MinigameTileCell

        cell.configure(iconSystemName: game.systemIconName, title: game.title, subtitle: game.desc)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let minigame = minigames[indexPath.item]
        let storyboard = UIStoryboard(name: minigame.storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: minigame.storyboardID)
        navigationController?.pushViewController(vc, animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let insets = collectionView.contentInset.left + collectionView.contentInset.right
        let tileWidth = floor(collectionView.bounds.width - insets)
        return CGSize(width: tileWidth, height: 110)
    }

    static func awardCoins() -> Int {
        UserManager.shared.currentUser?.addCoins(coinsEarnedPerMinigame)
        UserManager.shared.currentUser?.saveToFirestore()
        return coinsEarnedPerMinigame
    }
}

private final class MinigameTileCell: UICollectionViewCell {
    static let reuseIdentifier = "MinigameTileCell"

    private let iconWell = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        contentView.backgroundColor = SettingsStyle.card
        contentView.layer.cornerRadius = 16
        contentView.layer.borderColor = SettingsStyle.divider.cgColor
        contentView.layer.borderWidth = 1
        contentView.layer.masksToBounds = true

        iconWell.translatesAutoresizingMaskIntoConstraints = false
        iconWell.backgroundColor = SettingsStyle.iconWell
        iconWell.layer.masksToBounds = true

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = SettingsStyle.iconActive

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = SettingsTypography.sourGummy(size: 18, weight: .semibold)
        titleLabel.textColor = SettingsStyle.content
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = SettingsTypography.sourGummy(size: 13, weight: .regular)
        subtitleLabel.textColor = SettingsStyle.subtitle
        subtitleLabel.textAlignment = .left
        subtitleLabel.numberOfLines = 2

        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.distribution = .fill
        textStack.spacing = 4
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        contentView.addSubview(iconWell)
        iconWell.addSubview(iconImageView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            iconWell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconWell.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconWell.widthAnchor.constraint(equalToConstant: 64),
            iconWell.heightAnchor.constraint(equalToConstant: 64),

            iconImageView.centerXAnchor.constraint(equalTo: iconWell.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconWell.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalTo: iconWell.widthAnchor, multiplier: 0.48),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),

            textStack.leadingAnchor.constraint(equalTo: iconWell.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    override var isHighlighted: Bool {
        didSet {
            contentView.alpha = isHighlighted ? 0.8 : 1.0
        }
    }

    func configure(iconSystemName: String, title: String, subtitle: String) {
        iconImageView.image = UIImage(systemName: iconSystemName)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        layoutIfNeeded()
        iconWell.layer.cornerRadius = iconWell.bounds.width / 2
    }
}


