//
//  TimerGradientView.swift
//  Bevodoro Study
//
//  Created by Yim, Isabella H on 3/5/26.
//
// note: this file is mostly ai generated

import UIKit

class TimerGradientView: UIView {
    // change to light orange and burn orange, from figma
    var startColor: UIColor = UIColor(named: "LightOrangeYellow") ?? .white
    var endColor: UIColor = UIColor(named: "ToastyOrange") ?? .systemOrange

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradient()
    }

    private func updateGradient() {
        guard let gradientLayer = self.layer as? CAGradientLayer else { return }

        gradientLayer.colors = [
            startColor.cgColor,
            endColor.cgColor
        ]
        
        // linear top to bottom color
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)  // top center
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)  // bottom center
    }
}
