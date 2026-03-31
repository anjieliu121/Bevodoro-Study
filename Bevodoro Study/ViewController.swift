//
//  ViewController.swift
//  Bevodoro Study
//
//  Created by Anjie on 2/22/26.
//

import UIKit
import AVFoundation

class ViewController: BaseViewController {
    
    /// Target width when there is room; actual width is clamped so the bar stays inside the safe area.
    private let preferredMenuWidth: CGFloat = 400
    private let menuLeadingInset: CGFloat = 12
    private let menuToHamburgerGap: CGFloat = 8
    private var menuWidthConstraint: NSLayoutConstraint?
    private var menuStackView: UIStackView?
    private var isMenuOpen = false
    private var bevoImageView: UIImageView?
    private var audioPlayer: AVAudioPlayer?

    private var hamburgerButton: UIButton?
    private var menuContainerView: UIView?
    /// `hamburger.trailing = safeArea.trailing + constant` (default -12).
    private var hamburgerTrailingConstraint: NSLayoutConstraint?
    private var isPhotoModeActive = false
    private var photoModeOverlay: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground()
        setupBevo()
        setupHamburgerMenu()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isMenuOpen {
            refreshOpenMenuGeometry()
        }
    }

    /// Max width so the menu’s leading edge stays at or past the safe-area inset.
    private func maximumMenuWidthForCurrentLayout() -> CGFloat {
        view.layoutIfNeeded()
        guard let hamburger = hamburgerButton else { return preferredMenuWidth }
        let safeLeft = view.safeAreaLayoutGuide.layoutFrame.minX
        let menuTrailingX = hamburger.frame.minX - menuToHamburgerGap
        let maxWidth = menuTrailingX - safeLeft - menuLeadingInset
        return max(0, floor(maxWidth))
    }

    private func widthToUseWhenMenuOpen() -> CGFloat {
        min(preferredMenuWidth, maximumMenuWidthForCurrentLayout())
    }

    /// Fits five icons inside the current open width by adjusting spacing and icon size on narrow screens.
    private func applyMenuStackLayout(forOpenWidth w: CGFloat) {
        guard let stack = menuStackView else { return }
        let pad: CGFloat = 12
        let minGap: CGFloat = 4
        let count = CGFloat(stack.arrangedSubviews.count)
        guard count > 0 else { return }
        let gaps = count - 1

        let inner = max(0, w - 2 * pad)
        // Solve for icon side S and gap G: count*S + gaps*G = inner, with S<=44, G>=minGap
        var side = gaps > 0 ? (inner - gaps * minGap) / count : inner / count
        side = min(44, max(30, floor(side)))
        var gap: CGFloat = 0
        if gaps > 0 {
            gap = (inner - count * side) / gaps
            gap = max(minGap, min(24, gap))
            let spare = inner - gaps * gap
            side = min(44, max(30, floor(spare / count)))
        }
        stack.spacing = gap

        for case let button as UIButton in stack.arrangedSubviews {
            for c in button.constraints where c.firstAttribute == .width && c.secondItem == nil {
                c.constant = side
            }
            for c in button.constraints where c.firstAttribute == .height && c.secondItem == nil {
                c.constant = side
            }
            button.layer.cornerRadius = side / 2
        }
    }

    private func refreshOpenMenuGeometry() {
        guard let menuWidthConstraint = menuWidthConstraint, isMenuOpen else { return }
        let w = widthToUseWhenMenuOpen()
        menuWidthConstraint.constant = w
        applyMenuStackLayout(forOpenWidth: w)
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
        self.hamburgerButton = hamburgerButton

        let trailing = hamburgerButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -12)
        hamburgerTrailingConstraint = trailing

        NSLayoutConstraint.activate([
            hamburgerButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 4),
            trailing,
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
        self.menuContainerView = menuView
        
        let height: CGFloat = 56
        // Start with width 0 so it can expand from the hamburger button
        menuWidthConstraint = menuView.widthAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            menuView.centerYAnchor.constraint(equalTo: hamburgerButton.centerYAnchor),
            menuView.heightAnchor.constraint(equalToConstant: height),
            menuWidthConstraint!,
            menuView.trailingAnchor.constraint(equalTo: hamburgerButton.leadingAnchor, constant: -8)
        ])
        
        // Stack of icon buttons (timer, shop, inventory, settings, photo mode)
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(stackView)
        stackView.alpha = 0
        self.menuStackView = stackView
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -12),
            stackView.topAnchor.constraint(equalTo: menuView.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: menuView.bottomAnchor, constant: -10)
        ])
        
        func makeIconButton(systemName: String, accessibilityLabel: String) -> UIButton {
            let button = UIButton(type: .system)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setImage(UIImage(systemName: systemName), for: .normal)
            button.tintColor = .white
            button.backgroundColor = UIColor.white.withAlphaComponent(0.15)
            button.layer.cornerRadius = 22 // updated when menu opens if width is tight
            button.widthAnchor.constraint(equalToConstant: 44).isActive = true
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.accessibilityLabel = accessibilityLabel
            return button
        }
        
        let timerButton = makeIconButton(systemName: "timer", accessibilityLabel: "Timer")
        let shopButton = makeIconButton(systemName: "bag.fill", accessibilityLabel: "Shop")
        let inventoryButton = makeIconButton(systemName: "tray.fill", accessibilityLabel: "Inventory")
        let settingsButton = makeIconButton(systemName: "gearshape.fill", accessibilityLabel: "Settings")
        let photoButton = makeIconButton(systemName: "camera.fill", accessibilityLabel: "Photo mode")
        
        timerButton.addTarget(self, action: #selector(openTimer), for: .touchUpInside)
        shopButton.addTarget(self, action: #selector(openShop), for: .touchUpInside)
        inventoryButton.addTarget(self, action: #selector(openInventory), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        photoButton.addTarget(self, action: #selector(enterPhotoModeFromMenu), for: .touchUpInside)
        
        stackView.addArrangedSubview(timerButton)
        stackView.addArrangedSubview(shopButton)
        stackView.addArrangedSubview(inventoryButton)
        stackView.addArrangedSubview(settingsButton)
        stackView.addArrangedSubview(photoButton)
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
        guard SettingViewController.isBevosSoundEnabled else { return }
        
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
    
    @objc private func openTimer() {
        let storyboard = UIStoryboard(name: "Timer", bundle: nil)
        guard let vc = storyboard.instantiateViewController(
            identifier: "TimerViewController"
        ) as? TimerViewController else { return }
        vc.delegate = self
        closeMenuAndPresent(vc)
    }
    
    @objc private func openShop() {
        let storyboard = UIStoryboard(name: "ShopInventory", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "ShopViewController")
        closeMenuAndPresent(vc)
    }
    
    @objc private func openInventory() {
        let storyboard = UIStoryboard(name: "ShopInventory", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "InventoryViewController")
        closeMenuAndPresent(vc)
    }
    
    @objc private func openSettings() {
        let storyboard = UIStoryboard(name: "Setting", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "SettingViewController")
        closeMenuAndPresent(vc)
    }
    
    /// Hides the hamburger and icon strip for a clean screenshot; tap anywhere to restore.
    private func enterPhotoMode() {
        guard !isPhotoModeActive else { return }
        if isMenuOpen {
            isMenuOpen = false
            menuWidthConstraint?.constant = 0
            menuStackView?.alpha = 0
            view.layoutIfNeeded()
        }
        isPhotoModeActive = true
        hamburgerTrailingConstraint?.constant = 100
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.88,
            initialSpringVelocity: 0.6,
            options: [.curveEaseInOut],
            animations: { self.view.layoutIfNeeded() },
            completion: { _ in self.installPhotoModeTapOverlay() }
        )
    }

    @objc private func enterPhotoModeFromMenu() {
        enterPhotoMode()
    }

    private func installPhotoModeTapOverlay() {
        guard photoModeOverlay == nil else { return }
        let overlay = UIView()
        overlay.backgroundColor = .clear
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.accessibilityLabel = "Show menu"
        let tap = UITapGestureRecognizer(target: self, action: #selector(handlePhotoModeOverlayTap))
        overlay.addGestureRecognizer(tap)
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        photoModeOverlay = overlay
    }

    @objc private func handlePhotoModeOverlayTap() {
        guard isPhotoModeActive else { return }
        photoModeOverlay?.removeFromSuperview()
        photoModeOverlay = nil
        hamburgerTrailingConstraint?.constant = -12
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.88,
            initialSpringVelocity: 0.6,
            options: [.curveEaseInOut],
            animations: { self.view.layoutIfNeeded() },
            completion: { _ in self.isPhotoModeActive = false }
        )
    }

    @objc private func toggleMenu() {
        guard !isPhotoModeActive else { return }
        guard let menuWidthConstraint = menuWidthConstraint else { return }
        
        isMenuOpen.toggle()
        if isMenuOpen {
            refreshOpenMenuGeometry()
        } else {
            menuWidthConstraint.constant = 0
        }

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
