//
//  TapBevoViewController.swift
//  Bevodoro Study
//

import UIKit

class TapBevoViewController: UIViewController {

    private let gameDuration: TimeInterval = 30
    private let bevoSizeMultiplier: CGFloat = 0.22
    private let bevoVisibleDuration: TimeInterval = 1.5

    private var timeRemaining: TimeInterval = 30
    private var score = 0
    private var gameActive = false
    private var countdownTimer: Timer?
    private var bevoMoveTimer: Timer?

    private let backgroundImageView = UIImageView()
    private let timerLabel = UILabel()
    private let scoreLabel = UILabel()
    private let statusLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let bevoImageView = UIImageView()
    private let playAreaView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupPlayArea()
        setupLabels()
        setupBevo()
        setupActionButton()
        resetUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "Tap the Bevo!"
        navigationController?.navigationBar.tintColor = SettingsStyle.accent
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        if isMovingFromParent {
            stopGame()
        }
    }

    private func setupBackground() {
        backgroundImageView.image = UIImage(named: "texture_ut_light")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(backgroundImageView, at: 0)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupPlayArea() {
        playAreaView.translatesAutoresizingMaskIntoConstraints = false
        playAreaView.backgroundColor = SettingsStyle.card.withAlphaComponent(0.6)
        playAreaView.layer.cornerRadius = 20
        playAreaView.clipsToBounds = true
        view.addSubview(playAreaView)
        NSLayoutConstraint.activate([
            playAreaView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            playAreaView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -135),
            playAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            playAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func setupLabels() {
        timerLabel.font = SettingsTypography.sourGummy(size: 22, weight: .semibold)
        timerLabel.textColor = SettingsStyle.mainTitle
        timerLabel.textAlignment = .center
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)

        scoreLabel.font = SettingsTypography.sourGummy(size: 22, weight: .semibold)
        scoreLabel.textColor = .white
        scoreLabel.textAlignment = .center
        scoreLabel.backgroundColor = SettingsStyle.accent
        scoreLabel.layer.cornerRadius = 10
        scoreLabel.layer.masksToBounds = true
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scoreLabel)

        statusLabel.font = SettingsTypography.sourGummy(size: 17, weight: .regular)
        statusLabel.textColor = SettingsStyle.subtitle
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            timerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            scoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func setupBevo() {
        bevoImageView.image = UIImage(named: "normalFullBody")
        bevoImageView.contentMode = .scaleAspectFit
        bevoImageView.isUserInteractionEnabled = true
        bevoImageView.isHidden = true
        playAreaView.addSubview(bevoImageView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(bevoTapped))
        bevoImageView.addGestureRecognizer(tap)
    }

    private func setupActionButton() {
        actionButton.titleLabel?.font = SettingsTypography.sourGummy(size: 18, weight: .semibold)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.backgroundColor = SettingsStyle.accent
        actionButton.layer.cornerRadius = 14
        actionButton.layer.shadowColor = UIColor.black.cgColor
        actionButton.layer.shadowOpacity = 0.15
        actionButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        actionButton.layer.shadowRadius = 6
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        view.addSubview(actionButton)
        NSLayoutConstraint.activate([
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 200),
            actionButton.heightAnchor.constraint(equalToConstant: 50),
            statusLabel.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -10)
        ])
    }

    private func startGame() {
        score = 0
        timeRemaining = gameDuration
        gameActive = true
        updateLabels()

        statusLabel.text = "Tap Bevo!"
        actionButton.isHidden = true
        bevoImageView.isHidden = false

        moveBevoToRandomPosition(animated: false)
        startCountdown()
        startBevoMoveTimer()
    }

    private func stopGame() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        bevoMoveTimer?.invalidate()
        bevoMoveTimer = nil
        gameActive = false
    }

    private func endGame() {
        stopGame()
        bevoImageView.isHidden = true

        if score > 0 {
            MinigameMenuViewController.awardCoins()
        }

        let coinText = score > 0 ? "1 coin" : "0 coins"
        statusLabel.text = "Time's up! You tapped Bevo \(score) time\(score == 1 ? "" : "s") and earned \(coinText)."
        actionButton.setTitle("Play Again", for: .normal)
        actionButton.isHidden = false
    }

    private func resetUI() {
        timeRemaining = gameDuration
        score = 0
        updateLabels()
        statusLabel.text = "Tap Bevo as many times as you can!"
        actionButton.setTitle("Start", for: .normal)
        actionButton.isHidden = false
        bevoImageView.isHidden = true
    }

    private func startCountdown() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.timeRemaining -= 1
            self.updateLabels()
            if self.timeRemaining <= 0 {
                self.endGame()
            }
        }
    }

    private func startBevoMoveTimer() {
        bevoMoveTimer = Timer.scheduledTimer(withTimeInterval: bevoVisibleDuration, repeats: true) { [weak self] _ in
            guard let self, self.gameActive else { return }
            self.moveBevoToRandomPosition(animated: true)
        }
    }

    private func moveBevoToRandomPosition(animated: Bool) {
        playAreaView.layoutIfNeeded()
        let area = playAreaView.bounds
        let bevoSize = area.width * bevoSizeMultiplier

        let maxX = area.width - bevoSize
        let maxY = area.height - bevoSize
        guard maxX > 0, maxY > 0 else { return }

        let newX = CGFloat.random(in: 0...maxX)
        let newY = CGFloat.random(in: 0...maxY)
        let newFrame = CGRect(x: newX, y: newY, width: bevoSize, height: bevoSize)

        if animated {
            UIView.animate(withDuration: 0.2) {
                self.bevoImageView.frame = newFrame
            }
        } else {
            bevoImageView.frame = newFrame
        }
    }

    private func updateLabels() {
        timerLabel.text = "\(Int(timeRemaining))s"
        scoreLabel.text = "Score: \(score)"
    }

    @objc private func bevoTapped() {
        guard gameActive else { return }
        score += 1
        updateLabels()
        HapticsManager.shared.impactMedium()

        UIView.animate(withDuration: 0.08, animations: {
            self.bevoImageView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }, completion: { _ in
            UIView.animate(withDuration: 0.08) {
                self.bevoImageView.transform = .identity
            }
            self.moveBevoToRandomPosition(animated: true)
        })
    }

    @objc private func actionButtonTapped() {
        startGame()
    }
}

