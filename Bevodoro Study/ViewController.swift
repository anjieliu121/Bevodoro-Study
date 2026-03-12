//
//  ViewController.swift
//  Bevodoro Study
//
//  Created by Anjie on 2/22/26.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    private let menuWidth: CGFloat = 260
    private var menuWidthConstraint: NSLayoutConstraint?
    private var menuStackView: UIStackView?
    private var isMenuOpen = false
    private var bevoImageView: UIImageView?
    private var audioPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground()
        setupBevo()
        setupHamburgerMenu()
    }
    
    private func setupBackground() {
        let backgroundImageView = UIImageView(image: UIImage(named: "bkgDday"))
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupBevo() {
        let imageView = UIImageView(image: UIImage(named: "normalFullBody"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)
        bevoImageView = imageView
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 80),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.6)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBevoTap))
        imageView.addGestureRecognizer(tapGesture)
    }
    
    private func setupHamburgerMenu() {
        let safeArea = view.safeAreaLayoutGuide
        
        // Hamburger button
        let hamburgerButton = UIButton(type: .system)
        hamburgerButton.translatesAutoresizingMaskIntoConstraints = false
        hamburgerButton.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        hamburgerButton.tintColor = .white
        hamburgerButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        hamburgerButton.layer.cornerRadius = 18
        hamburgerButton.addTarget(self, action: #selector(toggleMenu), for: .touchUpInside)
        view.addSubview(hamburgerButton)
        
        NSLayoutConstraint.activate([
            hamburgerButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 4),
            hamburgerButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -12),
            hamburgerButton.widthAnchor.constraint(equalToConstant: 36),
            hamburgerButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // Menu container view
        let menuView = UIView()
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        menuView.layer.cornerRadius = 20
        menuView.clipsToBounds = true
        view.addSubview(menuView)
        
        let height: CGFloat = 56
        // Start with width 0 so it can expand from the hamburger button
        menuWidthConstraint = menuView.widthAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            menuView.centerYAnchor.constraint(equalTo: hamburgerButton.centerYAnchor),
            menuView.heightAnchor.constraint(equalToConstant: height),
            menuWidthConstraint!,
            menuView.trailingAnchor.constraint(equalTo: hamburgerButton.leadingAnchor, constant: -8)
        ])
        
        // Stack of icon buttons (timer, shop, settings)
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(stackView)
        stackView.alpha = 0
        self.menuStackView = stackView
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -24),
            stackView.topAnchor.constraint(equalTo: menuView.topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: menuView.bottomAnchor, constant: -12)
        ])
        
        func makeIconButton(systemName: String, accessibilityLabel: String) -> UIButton {
            let button = UIButton(type: .system)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setImage(UIImage(systemName: systemName), for: .normal)
            button.tintColor = .white
            button.backgroundColor = UIColor.white.withAlphaComponent(0.15)
            button.layer.cornerRadius = 22
            button.widthAnchor.constraint(equalToConstant: 44).isActive = true
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.accessibilityLabel = accessibilityLabel
            return button
        }
        
        let timerButton = makeIconButton(systemName: "timer", accessibilityLabel: "Timer")
        let shopButton = makeIconButton(systemName: "bag.fill", accessibilityLabel: "Shop")
        let settingsButton = makeIconButton(systemName: "gearshape.fill", accessibilityLabel: "Settings")
        
        timerButton.addTarget(self, action: #selector(openTimer), for: .touchUpInside)
        shopButton.addTarget(self, action: #selector(openShop), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        
        stackView.addArrangedSubview(timerButton)
        stackView.addArrangedSubview(shopButton)
        stackView.addArrangedSubview(settingsButton)
    }

    @objc private func handleBevoTap() {
        guard let imageView = bevoImageView else { return }
        
        // Simple bounce animation
        UIView.animate(withDuration: 0.1,
                       animations: {
            imageView.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1) {
                imageView.transform = .identity
            }
        })
        
        playBevoMooSound()
    }
    
    private func playBevoMooSound() {
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        
        guard let url = Bundle.main.url(forResource: "bevoMoo", withExtension: "mp3") else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            // If the sound fails to load, we just skip playing it.
        }
    }
    
    private func closeMenuAndPresent(_ viewController: UIViewController) {
        guard let menuWidthConstraint = menuWidthConstraint else { return }
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: viewController,
            action: #selector(UIViewController.dismissModalBack)
        )
        let nav = UINavigationController(rootViewController: viewController)
        nav.modalPresentationStyle = .fullScreen
        guard isMenuOpen else {
            present(nav, animated: true)
            return
        }
        isMenuOpen = false
        menuWidthConstraint.constant = 0
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
            self.menuStackView?.alpha = 0
        }) { _ in
            self.present(nav, animated: true)
        }
    }
    
    private func viewController(fromStoryboardId id: String) -> UIViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(identifier: id)
    }
    
    @objc private func openTimer() {
        guard let vc = viewController(fromStoryboardId: "TimerViewController") as? TimerViewController else { return }
        vc.delegate = self
        closeMenuAndPresent(vc)
    }
    
    @objc private func openShop() {
        guard let vc = viewController(fromStoryboardId: "ShopViewController") else { return }
        closeMenuAndPresent(vc)
    }
    
    @objc private func openSettings() {
        guard let vc = viewController(fromStoryboardId: "SettingViewController") else { return }
        closeMenuAndPresent(vc)
    }
    
    @objc private func toggleMenu() {
        guard let menuWidthConstraint = menuWidthConstraint else { return }
        
        isMenuOpen.toggle()
        menuWidthConstraint.constant = isMenuOpen ? menuWidth : 0
        
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.7,
                       options: [.curveEaseInOut],
                       animations: {
            self.view.layoutIfNeeded()
            // Fade in/out the icons as the menu opens/closes
            self.menuStackView?.alpha = self.isMenuOpen ? 1 : 0
        }, completion: nil)
    }
}

extension UIViewController {
    @objc func dismissModalBack() {
        dismiss(animated: true)
    }
}
