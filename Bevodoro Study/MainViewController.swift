//
//  MainViewController.swift
//  Bevodoro Study
//
//  Created by Anjie on 2/22/26.
//

import UIKit
import AVFoundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class MainViewController: BaseViewController {
    
    /// Target width when there is room; actual width is clamped so the bar stays inside the safe area.
    private let preferredMenuWidth: CGFloat = 400
    private let menuLeadingInset: CGFloat = 12
    private let menuToHamburgerGap: CGFloat = 8
    private var menuWidthConstraint: NSLayoutConstraint?
    private var menuStackView: UIStackView?
    private var isMenuOpen = false
    private var bevoImageView: UIImageView?
    private var bevoHatImageView: UIImageView?
    private var foodTroughImageView: UIImageView?
    /// Foods loaded from Firestore (`users/{uid}` → `food` or `foods` map). Quantity shows on each cell.
    private var troughFoods: [FoodItem] = []
    private var troughFoodCollectionView: UICollectionView?
    /// Paging pan: only begins when touch starts on empty space (`indexPathForItem(at:)` is nil).
    private var troughGapPanGesture: UIPanGestureRecognizer?

    /// While dragging food out of the trough, this is the floating copy; cell image is hidden until reload.
    private var troughFoodDragProxy: UIImageView?
    private var troughFoodDragHomeFrameInView: CGRect = .zero
    private var troughFoodDragIndexPath: IndexPath?

    private var audioPlayer: AVAudioPlayer?
    private var chewingAudioPlayer: AVAudioPlayer?
    /// Switches Bevo to EatFullBody then back; cancelled if fed again before the pose ends.
    private var bevoEatRevertWorkItem: DispatchWorkItem?

    private var hamburgerButton: UIButton?
    private var menuContainerView: UIView?
    /// `hamburger.trailing = safeArea.trailing + constant` (default -12).
    private var hamburgerTrailingConstraint: NSLayoutConstraint?
    private var isPhotoModeActive = false
    private var photoModeOverlay: UIView?
    /// Full-screen image behind Bevo (not the `BaseViewController` chrome).
    private var bevoSceneBackgroundImageView: UIImageView?
    /// Foods per page (3 → first page full, second page has 2 items).
    private static let troughItemsPerPage = 3
    private static let troughInterFoodSpacing: CGFloat = 14
    /// How long Bevo stays on the EatFullBody asset after being fed.
    private static let bevoEatFullBodyDuration: TimeInterval = 1.5

    
    private static var lastBevoSickAlertShownAt: Date? = nil
    private static let sickAlertCooldown: TimeInterval = 5 * 60  // 5 minutes. rate limit the sick alert so it isnt annoying.
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackground()
        setupFoodTrough()
        setupBevo()
        setupHamburgerMenu()
        bringTroughFoodCollectionToFront()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Load / refresh from Firestore (first appear + return from Shop / Inventory).
        loadTroughFoodFromFirestore()
        applyBevoSceneBackgroundFromUser()
        applyBevoHatFromUser()
        showBevoSickAlertIfNeeded()
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
        let backgroundImageView = UIImageView(image: UIImage(named: "bkgday"))
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        bevoSceneBackgroundImageView = backgroundImageView

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func applyBevoSceneBackgroundFromUser() {
        guard let bgView = bevoSceneBackgroundImageView else { return }
        let fallback = ItemCatalog.dayBackgroundKey
        guard let user = UserManager.shared.currentUser else {
            bgView.image = UIImage(named: ItemCatalog.backgroundAssetName(forKey: fallback))
            return
        }
        let chosen = user.equippedBkg ?? fallback
        let key = user.backgrounds.contains(chosen) ? chosen : fallback
        let asset = ItemCatalog.backgroundAssetName(forKey: key)
        bgView.image = UIImage(named: asset) ?? UIImage(named: "bkgday")
    }

    private func applyBevoHatFromUser() {
        guard let hatView = bevoHatImageView else { return }
        guard let user = UserManager.shared.currentUser else {
            hatView.image = nil
            hatView.isHidden = true
            return
        }
        guard let key = user.equippedHat, user.hats.contains(key) else {
            hatView.image = nil
            hatView.isHidden = true
            return
        }
        let asset = ItemCatalog.icon(forKey: key)
        hatView.image = UIImage(named: asset)
        hatView.isHidden = (hatView.image == nil)
    }

    private func setupFoodTrough() {
        let imageView = UIImageView(image: UIImage(named: "FoodTrough"))
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        foodTroughImageView = imageView
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            imageView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -4),
            imageView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: -10),
            imageView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: 10),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.28)
        ])

        setupTroughFoodCollectionView(pinnedTo: imageView)
    }
    
    // MARK: - Food trough (2 pages: 3 + 2 foods)

    private func makeTroughFoodCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let perPage = Self.troughItemsPerPage
        let spacing = Self.troughInterFoodSpacing

        let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { [weak self] sectionIndex, _ in
            guard let self else {
                let s = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: s)
                let g = NSCollectionLayoutGroup.horizontal(layoutSize: s, subitem: item, count: 1)
                return NSCollectionLayoutSection(group: g)
            }
            let itemCount = self.troughNumberOfItems(inSection: sectionIndex)
            guard itemCount > 0 else {
                let s = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: s)
                let g = NSCollectionLayoutGroup.horizontal(layoutSize: s, subitem: item, count: 1)
                return NSCollectionLayoutSection(group: g)
            }

            // Always reserve `perPage` slots (e.g. 3 columns). Last page may show only 2 foods — the extra
            // column stays empty. That gives a large non-cell area on the right so gap-swipe (and swipe-back)
            // still gets `indexPathForItem(at:) == nil`. If we only used 2 wide cells, the row would fill and
            // swipes back would usually start on the left food → paging pan would never begin.
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / CGFloat(perPage)),
                heightDimension: .fractionalHeight(0.92)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitem: item,
                count: perPage
            )
            group.interItemSpacing = .fixed(spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
            return section
        }

        var config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider, configuration: config)
    }

    private func troughNumberOfItems(inSection section: Int) -> Int {
        let start = section * Self.troughItemsPerPage
        guard start < troughFoods.count else { return 0 }
        return min(Self.troughItemsPerPage, troughFoods.count - start)
    }

    private var troughPageCount: Int {
        guard !troughFoods.isEmpty else { return 0 }
        return (troughFoods.count + Self.troughItemsPerPage - 1) / Self.troughItemsPerPage
    }

    private func troughGlobalIndex(section: Int, item: Int) -> Int {
        section * Self.troughItemsPerPage + item
    }

    /// Nearest page from scroll offset (handles non-integer offsets after animation).
    private func troughCurrentPageIndex(_ cv: UICollectionView, pageWidth w: CGFloat) -> Int {
        guard w > 0, troughPageCount > 0 else { return 0 }
        let x = cv.contentOffset.x
        let p = Int((x + w * 0.5) / w)
        return max(0, min(troughPageCount - 1, p))
    }

    private func setupTroughFoodCollectionView(pinnedTo trough: UIImageView) {
        let layout = makeTroughFoodCompositionalLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.isScrollEnabled = false
        // Avoid the scroll view’s built-in pan competing with our gap-only paging pan.
        cv.panGestureRecognizer.isEnabled = false
        cv.dataSource = self
        cv.register(FoodCell.self, forCellWithReuseIdentifier: FoodCell.reuseIdentifier)

        view.addSubview(cv)
        troughFoodCollectionView = cv

        NSLayoutConstraint.activate([
            cv.centerXAnchor.constraint(equalTo: trough.centerXAnchor),
            cv.centerYAnchor.constraint(equalTo: trough.centerYAnchor, constant: -6),
            cv.widthAnchor.constraint(equalTo: trough.widthAnchor, multiplier: 0.88),
            cv.heightAnchor.constraint(equalTo: trough.heightAnchor, multiplier: 0.38)
        ])

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleTroughGapPan(_:)))
        pan.delegate = self
        pan.cancelsTouchesInView = false
        cv.addGestureRecognizer(pan)
        troughGapPanGesture = pan

        cv.reloadData()
    }

    @objc private func handleTroughGapPan(_ gesture: UIPanGestureRecognizer) {
        guard let cv = troughFoodCollectionView else { return }
        let w = cv.bounds.width
        guard w > 0, troughPageCount > 1 else { return }

        switch gesture.state {
        case .ended, .cancelled, .failed:
            let translation = gesture.translation(in: cv)
            let threshold: CGFloat = 48
            var page = troughCurrentPageIndex(cv, pageWidth: w)
            if translation.x < -threshold { page += 1 }
            else if translation.x > threshold { page -= 1 }
            page = max(0, min(troughPageCount - 1, page))
            cv.setContentOffset(CGPoint(x: CGFloat(page) * w, y: 0), animated: true)
        default:
            break
        }
    }

    private func bringTroughFoodCollectionToFront() {
        if let cv = troughFoodCollectionView {
            view.bringSubviewToFront(cv)
        }
    }

    // MARK: - Firestore food trough

    /// Loads `food` or `foods` map from `users/{uid}` and fills `troughFoods`.
    private func loadTroughFoodFromFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else {
            troughFoods = []
            troughFoodCollectionView?.reloadData()
            return
        }

        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error = error {
                    print("Food trough: load error — \(error.localizedDescription)")
                    self.troughFoods = []
                    self.troughFoodCollectionView?.reloadData()
                    return
                }
                let map = FoodItem.parseFoodMap(from: snapshot?.data())
                self.troughFoods = FoodItem.troughItems(fromFoodMap: map)
                self.troughFoodCollectionView?.reloadData()
            }
        }
    }

    /// After Bevo eats, update local list and merge into Firestore (keeps other `food` keys from Shop, etc.).
    private func applyEatFromTrough(atGlobalIndex globalIndex: Int) {
        guard troughFoods.indices.contains(globalIndex) else { return }
        let name = troughFoods[globalIndex].imageName
        if troughFoods[globalIndex].quantity <= 1 {
            troughFoods.remove(at: globalIndex)
            mergePushFoodMap(updating: name, newQuantity: 0)
        } else {
            troughFoods[globalIndex].quantity -= 1
            mergePushFoodMap(updating: name, newQuantity: troughFoods[globalIndex].quantity)
        }
    }

    private func mergePushFoodMap(updating foodKey: String, newQuantity: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let doc = Firestore.firestore().collection("users").document(uid)
        doc.getDocument { snapshot, _ in
            var food = FoodItem.parseFoodMap(from: snapshot?.data())
            if newQuantity <= 0 {
                food.removeValue(forKey: foodKey)
            } else {
                food[foodKey] = newQuantity
            }
            doc.setData(["food": food], merge: true) { error in
                if let error = error {
                    print("Food trough: save error — \(error.localizedDescription)")
                }
            }
        }
    }

    /// Keeps menu / hamburger usable while a food is dragged.
    private func bringMenuChromeAboveDraggingFood() {
        if let menu = menuContainerView { view.bringSubviewToFront(menu) }
        if let ham = hamburgerButton { view.bringSubviewToFront(ham) }
    }

    // MARK: - Drag food from trough

    private func attachTroughFoodDragPan(to cell: FoodCell, indexPath: IndexPath) {
        cell.foodImageView.gestureRecognizers?.forEach { cell.foodImageView.removeGestureRecognizer($0) }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleTroughFoodPan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.cancelsTouchesInView = false
        objc_setAssociatedObject(
            pan,
            &TroughFoodPanAssociated.indexKey,
            TroughFoodPanIndexBox(indexPath),
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        cell.foodImageView.addGestureRecognizer(pan)
    }

    @objc private func handleTroughFoodPan(_ gesture: UIPanGestureRecognizer) {
        guard let box = objc_getAssociatedObject(gesture, &TroughFoodPanAssociated.indexKey) as? TroughFoodPanIndexBox else { return }
        let indexPath = box.indexPath
        guard let foodIV = gesture.view as? UIImageView,
              let cv = troughFoodCollectionView else { return }

        switch gesture.state {
        case .began:
            guard troughFoodDragProxy == nil else { return }
            view.layoutIfNeeded()
            let home = foodIV.convert(foodIV.bounds, to: view)
            guard home.width > 0, home.height > 0 else { return }

            let proxy = UIImageView(image: foodIV.image)
            proxy.contentMode = .scaleAspectFit
            proxy.frame = home
            proxy.isUserInteractionEnabled = false
            view.addSubview(proxy)
            view.bringSubviewToFront(proxy)
            bringMenuChromeAboveDraggingFood()

            troughFoodDragProxy = proxy
            troughFoodDragHomeFrameInView = home
            troughFoodDragIndexPath = indexPath
            foodIV.isHidden = true
            if let foodCell = foodIV.superview?.superview as? FoodCell {
                foodCell.setQuantityBadgeHidden(true)
            }

        case .changed:
            guard let proxy = troughFoodDragProxy else { return }
            let t = gesture.translation(in: view)
            gesture.setTranslation(.zero, in: view)
            proxy.center = CGPoint(x: proxy.center.x + t.x, y: proxy.center.y + t.y)

        case .ended, .cancelled, .failed:
            guard let proxy = troughFoodDragProxy else { return }
            let dropFrame = proxy.frame
            let fedToBevo = isFoodFrameTouchingOrNearBevo(dropFrame)

            if fedToBevo {
                showBevoEatingFullBodyTemporarily()

                let sparkleCenter = CGPoint(x: dropFrame.midX, y: dropFrame.midY)
                let sparkleSide = max(36, min(dropFrame.width, dropFrame.height) * 0.85)
                let sparkle = UIImageView(image: UIImage(systemName: "sparkles"))
                sparkle.translatesAutoresizingMaskIntoConstraints = true
                sparkle.bounds = CGRect(x: 0, y: 0, width: sparkleSide, height: sparkleSide)
                sparkle.center = sparkleCenter
                sparkle.contentMode = .scaleAspectFit
                sparkle.tintColor = UIColor.white.withAlphaComponent(0.92)
                sparkle.alpha = 0
                self.view.addSubview(sparkle)
                self.view.bringSubviewToFront(sparkle)
                self.bringMenuChromeAboveDraggingFood()

                UIView.animate(withDuration: 0.12, animations: {
                    proxy.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.28, animations: {
                        proxy.transform = CGAffineTransform(scaleX: 0.05, y: 0.05)
                        proxy.alpha = 0
                        sparkle.alpha = 1
                        sparkle.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    }, completion: { _ in
                        UIView.animate(withDuration: 0.18, animations: {
                            sparkle.alpha = 0
                            sparkle.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
                        }, completion: { _ in
                            sparkle.removeFromSuperview()
                            proxy.removeFromSuperview()
                            let global = self.troughGlobalIndex(section: indexPath.section, item: indexPath.item)
                            self.clearTroughFoodDragState()
                            self.applyEatFromTrough(atGlobalIndex: global)
                            cv.reloadData()
                        })
                    })
                })
            } else {
                UIView.animate(
                    withDuration: 0.38,
                    delay: 0,
                    usingSpringWithDamping: 0.78,
                    initialSpringVelocity: 0.65,
                    options: [.curveEaseInOut],
                    animations: {
                        proxy.frame = self.troughFoodDragHomeFrameInView
                    },
                    completion: { _ in
                        proxy.removeFromSuperview()
                        self.clearTroughFoodDragState()
                        cv.reloadItems(at: [indexPath])
                    }
                )
            }

        default:
            break
        }
    }

    private func clearTroughFoodDragState() {
        troughFoodDragProxy = nil
        troughFoodDragHomeFrameInView = .zero
        troughFoodDragIndexPath = nil
    }

    private func isFoodFrameTouchingOrNearBevo(_ foodFrame: CGRect) -> Bool {
        guard let bevo = bevoImageView else { return false }
        let feedPadding = max(16, min(view.bounds.width, view.bounds.height) * 0.04)
        let expandedBevoFrame = bevo.frame.insetBy(dx: -feedPadding, dy: -feedPadding)
        return expandedBevoFrame.intersects(foodFrame)
    }

    /// Same `UIImageView` and constraints as normal pose — only the asset changes, so size stays identical.
    private func showBevoEatingFullBodyTemporarily() {
        guard let bevo = bevoImageView else { return }
        guard let eatImage = UIImage(named: "EatFullBody"),
              let normalImage = UIImage(named: "normalFullBody") else { return }

        bevoEatRevertWorkItem?.cancel()
        bevo.image = eatImage
        playBevoChewingSound()

        let work = DispatchWorkItem { [weak self] in
            guard let self, let bevo = self.bevoImageView else { return }
            bevo.image = normalImage
            self.bevoEatRevertWorkItem = nil
        }
        bevoEatRevertWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.bevoEatFullBodyDuration, execute: work)
    }
    
    private func setupBevo() {
        let imageView = UIImageView(image: UIImage(named: "normalFullBody"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)
        bevoImageView = imageView
        
        var constraints: [NSLayoutConstraint] = [
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.6)
        ]
        
        if let trough = foodTroughImageView {
            constraints.append(imageView.bottomAnchor.constraint(equalTo: trough.topAnchor, constant: 10))
            constraints.append(imageView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 24))
        } else {
            constraints.append(imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 80))
        }
        
        NSLayoutConstraint.activate(constraints)

        let hatView = UIImageView()
        hatView.contentMode = .scaleAspectFit
        hatView.translatesAutoresizingMaskIntoConstraints = false
        hatView.isUserInteractionEnabled = false
        imageView.addSubview(hatView)
        NSLayoutConstraint.activate([
            hatView.topAnchor.constraint(equalTo: imageView.topAnchor),
            hatView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            hatView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            hatView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        ])
        bevoHatImageView = hatView

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
        let inventoryButton = makeIconButton(systemName: "tray.fill", accessibilityLabel: "Inventory")  //shippingbox.fill
        let shopButton = makeIconButton(systemName: "bag.fill", accessibilityLabel: "Shop") // cart.fill
        let settingsButton = makeIconButton(systemName: "gearshape.fill", accessibilityLabel: "Settings")
        let photoButton = makeIconButton(systemName: "camera.fill", accessibilityLabel: "Photo mode")
        
        timerButton.addTarget(self, action: #selector(openTimer), for: .touchUpInside)
        shopButton.addTarget(self, action: #selector(openShop), for: .touchUpInside)
        inventoryButton.addTarget(self, action: #selector(openInventory), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        photoButton.addTarget(self, action: #selector(enterPhotoModeFromMenu), for: .touchUpInside)
        
        stackView.addArrangedSubview(timerButton)
        stackView.addArrangedSubview(inventoryButton)
        stackView.addArrangedSubview(shopButton)
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

    /// Plays `Audio/chewing.mp3` while Bevo shows the eat-full-body pose (same toggle as moo).
    private func playBevoChewingSound() {
        guard SettingViewController.isBevosSoundEnabled else { return }
        if let player = chewingAudioPlayer, player.isPlaying {
            player.stop()
        }
        let url = Bundle.main.url(forResource: "chewing", withExtension: "mp3", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: "chewing", withExtension: "mp3")
        guard let url else {
            #if DEBUG
            print("MainViewController: chewing.mp3 not found — add Bevodoro Study/Audio/chewing.mp3 to the app bundle.")
            #endif
            return
        }
        do {
            chewingAudioPlayer = try AVAudioPlayer(contentsOf: url)
            chewingAudioPlayer?.prepareToPlay()
            chewingAudioPlayer?.play()
        } catch {
        }
    }
    
    private func closeMenuAndPresent(_ viewController: UIViewController) {
        guard let menuWidthConstraint = menuWidthConstraint else { return }
        let backImage = UIImage(systemName: "chevron.backward")
        let backItem = UIBarButtonItem(
            image: backImage,
            style: .plain,
            target: viewController,
            action: #selector(UIViewController.dismissModalBack)
        )
        backItem.accessibilityLabel = "Back"
        viewController.navigationItem.leftBarButtonItem = backItem
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
            animations: {
                self.view.layoutIfNeeded()
                self.applyTroughHiddenForPhotoMode()
            },
            completion: { _ in self.installPhotoModeTapOverlay() }
        )
    }

    // MARK: - Photo mode: hide / show food trough

    /// How far down (pt) to translate the trough + foods so they sit off-screen below.
    private func troughSlideDownDistanceForPhotoMode() -> CGFloat {
        guard let trough = foodTroughImageView else { return 400 }
        view.layoutIfNeeded()
        let troughFrame = trough.convert(trough.bounds, to: view)
        // Move until the top of the trough passes the bottom of the screen (+ small margin).
        let margin: CGFloat = 32
        return max(view.bounds.maxY - troughFrame.minY + margin, 280)
    }

    /// Sinks trough art + collection toward the bottom and fades out (photo mode).
    private func applyTroughHiddenForPhotoMode() {
        let ty = troughSlideDownDistanceForPhotoMode()
        let t = CGAffineTransform(translationX: 0, y: ty)
        foodTroughImageView?.transform = t
        foodTroughImageView?.alpha = 0
        troughFoodCollectionView?.transform = t
        troughFoodCollectionView?.alpha = 0
    }

    /// Brings trough + foods back to normal layout (after leaving photo mode).
    private func applyTroughVisibleAfterPhotoMode() {
        foodTroughImageView?.transform = .identity
        foodTroughImageView?.alpha = 1
        troughFoodCollectionView?.transform = .identity
        troughFoodCollectionView?.alpha = 1
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
            animations: {
                self.view.layoutIfNeeded()
                self.applyTroughVisibleAfterPhotoMode()
            },
            completion: { _ in
                self.isPhotoModeActive = false
                self.bringTroughFoodCollectionToFront()
            }
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
    
    func showBevoSickAlertIfNeeded() {
        // make sure the user is valid and bevo is sick
        guard let user = UserManager.shared.currentUser else { return }
        guard user.isSick() else { return }
        guard user.lastStudy != nil else { return } // nil for new users
        
        // Don't be annoying. rate-limit the alert to every sickAlertCooldown seconds.
        if let lastShown = MainViewController.lastBevoSickAlertShownAt {
            let elapsed = Date().timeIntervalSince(lastShown)
            guard elapsed >= MainViewController.sickAlertCooldown else {
                return
            }
        }
        
        // construct the alert
        let lastStudyDate = user.lastStudy!.dateValue()
        let sickAfterDate = lastStudyDate.addingTimeInterval(bevoSickThresholdSeconds)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        let normalMessage = "It’s been a while since you last studied. Study more to buy medicine to treat Bevo!"
        let debugMessage = """
        \(normalMessage)
        
        Debug Mode info:
        Last study date: \(formatter.string(from: lastStudyDate))
        Sick if after: \(formatter.string(from: sickAfterDate))
        """
        
        let alert = UIAlertController(
            title: "Bevo is Sick!",
            message: SettingViewController.isDemoModeEnabled ? debugMessage : normalMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        // update rate-limit cooldown, when it was last shown
        MainViewController.lastBevoSickAlertShownAt = Date()
    }
}

// MARK: - UICollectionViewDataSource

extension MainViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        troughPageCount
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        troughNumberOfItems(inSection: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FoodCell.reuseIdentifier,
            for: indexPath
        ) as? FoodCell else {
            return UICollectionViewCell()
        }
        let global = troughGlobalIndex(section: indexPath.section, item: indexPath.item)
        cell.configure(with: troughFoods[global])
        attachTroughFoodDragPan(to: cell, indexPath: indexPath)
        return cell
    }
}

// MARK: - objc: store IndexPath on each food pan recognizer

private enum TroughFoodPanAssociated {
    static var indexKey: UInt8 = 0
}

private final class TroughFoodPanIndexBox: NSObject {
    let indexPath: IndexPath
    init(_ indexPath: IndexPath) { self.indexPath = indexPath }
}

// MARK: - Gap-only paging (touch start location)

extension MainViewController: UIGestureRecognizerDelegate {

    /// Touch start decides if this is a **page swipe** vs **food drag**:
    /// - Not on any item → allow paging (true gaps between cells, empty column, insets).
    /// - On a cell but **outside** `foodImageView` (cell padding) → allow paging so the trough is easy to swipe.
    /// - **Inside** `foodImageView` → do not page; the food’s own pan handles drag.
    ///
    /// Note: `indexPathForItem(at:)` alone is not enough — it returns a path for the whole **cell** frame,
    /// including transparent padding around the art, which blocked paging after drag was added.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === troughGapPanGesture,
              let cv = troughFoodCollectionView else { return true }
        let point = gestureRecognizer.location(in: cv)
        guard let indexPath = cv.indexPathForItem(at: point),
              let cell = cv.cellForItem(at: indexPath) as? FoodCell else {
            return true
        }
        let pointInFood = cell.foodImageView.convert(point, from: cv)
        let beganOnFoodImage = cell.foodImageView.bounds.contains(pointInFood)
        return !beganOnFoodImage
    }
}

extension UIViewController {
    @objc func dismissModalBack() {
        dismiss(animated: true)
    }
}

