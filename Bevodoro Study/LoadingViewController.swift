//
//  LoadingViewController.swift
//  Bevodoro Study
//

import UIKit
import ImageIO

class LoadingViewController: UIViewController {

    private static let displayDuration: TimeInterval = 2.5

    override func viewDidLoad() {
        super.viewDidLoad()
        let bg = UIImageView(image: UIImage(named: "bkgday"))
        bg.contentMode = .scaleAspectFill
        bg.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bg)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: view.topAnchor),
            bg.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        setupLoading()
        scheduleTransition()
    }

    private func setupLoading() {
        guard let asset = NSDataAsset(name: "bevoWalk"),
              let source = CGImageSourceCreateWithData(asset.data as CFData, nil) else { return }

        let frameCount = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var totalDuration: Double = 0

        for i in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage))
            let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any]
            let gifProps = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = gifProps?[kCGImagePropertyGIFUnclampedDelayTime] as? Double
                     ?? gifProps?[kCGImagePropertyGIFDelayTime] as? Double
                     ?? 0.1
            totalDuration += delay
        }

        // Bevo walking
        let imageView = UIImageView()
        imageView.animationImages = frames
        imageView.animationDuration = totalDuration
        imageView.animationRepeatCount = 0
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.startAnimating()
        view.addSubview(imageView)

        // Temporary label until I figure something out with the clouds.
        let loadingLabel = UILabel()
        loadingLabel.text = "Loading..."
        loadingLabel.font = UIFont(name: "SourGummy-Black_SemiBold", size: 28) ?? UIFont.systemFont(ofSize: 28, weight: .semibold)
        loadingLabel.textColor = .white
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingLabel)

        NSLayoutConstraint.activate([
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),

            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 80),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])
    }

    private func scheduleTransition() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.displayDuration) { [weak self] in
            self?.goToMain()
        }
    }

    private func goToMain() {
        guard let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate else { return }
        sceneDelegate.showMainScreen()
    }
}
