//
//  PongViewController.swift
//  Bevodoro Study
//

import UIKit

class PongViewController: UIViewController {

    private let paddleWidth: CGFloat = 90
    private let paddleHeight: CGFloat = 14
    private let ballSize: CGFloat = 18
    private let initialBallSpeed: CGFloat = 280
    private let livesCount = 3
    private let paddleBottomMargin: CGFloat = 24

    private var ballVelocity = CGPoint.zero
    private var score = 0
    private var lives = 3
    private var gameActive = false
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0

    private let backgroundImageView = UIImageView()
    private let playAreaView = UIView()
    private let ballView = UIView()
    private let paddleView = UIView()
    private let scoreLabel = UILabel()
    private let livesLabel = UILabel()
    private let statusLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupPlayArea()
        setupGameViews()
        setupLabels()
        setupActionButton()
        resetUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "Pong"
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

    deinit {
        displayLink?.invalidate()
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

    private func setupGameViews() {
        ballView.backgroundColor = SettingsStyle.accent
        ballView.layer.cornerRadius = ballSize / 2
        ballView.isHidden = true
        playAreaView.addSubview(ballView)

        paddleView.backgroundColor = SettingsStyle.mainTitle
        paddleView.layer.cornerRadius = paddleHeight / 2
        paddleView.isHidden = true
        playAreaView.addSubview(paddleView)
    }

    private func setupLabels() {
        livesLabel.font = SettingsTypography.sourGummy(size: 22, weight: .semibold)
        livesLabel.textColor = SettingsStyle.mainTitle
        livesLabel.textAlignment = .left
        livesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(livesLabel)

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
            livesLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            livesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            scoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
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
        lives = livesCount
        gameActive = true
        updateLabels()
        statusLabel.text = "Don't let the ball drop!"
        actionButton.isHidden = true
        ballView.isHidden = false
        paddleView.isHidden = false
        view.layoutIfNeeded()
        resetBallAndPaddle()
        startDisplayLink()
    }

    private func stopGame() {
        displayLink?.invalidate()
        displayLink = nil
        gameActive = false
    }

    private func endGame() {
        stopGame()
        ballView.isHidden = true
        paddleView.isHidden = true
        if score > 0 {
            MinigameMenuViewController.awardCoins()
        }
        let coinText = score > 0 ? "1 coin" : "0 coins"
        statusLabel.text = "Game over! You hit the ball \(score) time\(score == 1 ? "" : "s") and earned \(coinText)."
        actionButton.setTitle("Play Again", for: .normal)
        actionButton.isHidden = false
    }

    private func resetUI() {
        score = 0
        lives = livesCount
        updateLabels()
        statusLabel.text = "Keep the ball in play!"
        actionButton.setTitle("Start", for: .normal)
        actionButton.isHidden = false
        ballView.isHidden = true
        paddleView.isHidden = true
    }

    private func resetBallAndPaddle() {
        let area = playAreaView.bounds
        let paddleY = area.height - paddleBottomMargin - paddleHeight
        paddleView.frame = CGRect(
            x: (area.width - paddleWidth) / 2,
            y: paddleY,
            width: paddleWidth,
            height: paddleHeight
        )
        ballView.frame = CGRect(
            x: area.width / 2 - ballSize / 2,
            y: paddleY - ballSize - 10,
            width: ballSize,
            height: ballSize
        )
        let angle = CGFloat.random(in: -CGFloat.pi / 4 ... CGFloat.pi / 4)
        ballVelocity = CGPoint(
            x: initialBallSpeed * sin(angle),
            y: -initialBallSpeed * cos(angle)
        )
    }

    private func startDisplayLink() {
        lastTimestamp = 0
        displayLink = CADisplayLink(target: self, selector: #selector(gameLoop))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func gameLoop(link: CADisplayLink) {
        guard gameActive else { return }
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        let dt = CGFloat(min(link.timestamp - lastTimestamp, 0.05))
        lastTimestamp = link.timestamp
        updateGame(dt: dt)
    }

    private func updateGame(dt: CGFloat) {
        let area = playAreaView.bounds
        var newX = ballView.frame.origin.x + ballVelocity.x * dt
        var newY = ballView.frame.origin.y + ballVelocity.y * dt

        if newX <= 0 {
            newX = 0
            ballVelocity.x = abs(ballVelocity.x)
        } else if newX + ballSize >= area.width {
            newX = area.width - ballSize
            ballVelocity.x = -abs(ballVelocity.x)
        }

        if newY <= 0 {
            newY = 0
            ballVelocity.y = abs(ballVelocity.y)
        }

        let ballRect = CGRect(x: newX, y: newY, width: ballSize, height: ballSize)
        if ballRect.intersects(paddleView.frame), ballVelocity.y > 0 {
            newY = paddleView.frame.minY - ballSize
            let hitOffset = (newX + ballSize / 2) - paddleView.frame.midX
            let normalized = max(-1, min(1, hitOffset / (paddleWidth / 2)))
            let speed = hypot(ballVelocity.x, ballVelocity.y) + 15
            let vx = normalized * speed * 0.8
            let vy = -sqrt(max(speed * speed - vx * vx, speed * speed * 0.36))
            ballVelocity = CGPoint(x: vx, y: vy)
            score += 1
            updateLabels()
            HapticsManager.shared.impactMedium()
        }

        if newY + ballSize >= area.height {
            lives -= 1
            updateLabels()
            HapticsManager.shared.impactMedium()
            if lives <= 0 {
                endGame()
            } else {
                resetBallAndPaddle()
            }
            return
        }

        ballView.frame.origin = CGPoint(x: newX, y: newY)
    }

    private func updateLabels() {
        scoreLabel.text = " Score: \(score) "
        livesLabel.text = "Lives: \(lives)"
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        movePaddle(touches: touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        movePaddle(touches: touches)
    }

    private func movePaddle(touches: Set<UITouch>) {
        guard gameActive, let touch = touches.first else { return }
        let x = touch.location(in: playAreaView).x - paddleWidth / 2
        paddleView.frame.origin.x = max(0, min(x, playAreaView.bounds.width - paddleWidth))
    }

    @objc private func actionButtonTapped() {
        startGame()
    }
}

