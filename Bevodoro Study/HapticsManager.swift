//
//  HapticsManager.swift
//  Bevodoro Study
//
//  Created by Codex on 4/19/26.
//

import UIKit

/// Centralized helper for app-wide haptic feedback.
final class HapticsManager {
    static let shared = HapticsManager()

    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let rigidImpactGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {}

    func selection() {
        selectionGenerator.selectionChanged()
    }

    func impactLight() {
        lightImpactGenerator.impactOccurred()
    }

    func impactMedium() {
        mediumImpactGenerator.impactOccurred()
    }

    func impactRigid() {
        rigidImpactGenerator.impactOccurred()
    }

    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    /// Call when entering a screen with frequent interactions.
    func prepareForInteraction() {
        selectionGenerator.prepare()
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        rigidImpactGenerator.prepare()
        notificationGenerator.prepare()
    }
}
