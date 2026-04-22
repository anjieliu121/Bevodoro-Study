//
//  UserManager.swift
//  Bevodoro Study
//
//  Created by Anjie on 3/11/26.
//

import Foundation
import FirebaseFirestore

class UserManager {
    static let shared = UserManager()
    var currentUser: User?
    private init() {
    }

    // called when a study session completes: when study timer ends updates lastStudy
    func handleStudyCompleted(timeInSeconds: Int) {
        guard var user = currentUser else { return }

        let (newStreak, _) = calculateStreak(oldLastStudy: user.lastStudy?.dateValue(), oldStreak: user.studyStreak)
        user.studyStreak = newStreak
        user.updateLastStudyNow()
        currentUser = user
        user.saveToFirestore()
    }

    // Returns the new streak and bonus coins earned.
    // Same day: no change, no bonus. Yesterday: streak+1, bonus=new streak. Older/nil: reset to 1, bonus=1.
    private func calculateStreak(oldLastStudy: Date?, oldStreak: Int) -> (newStreak: Int, bonusCoins: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let lastDate = oldLastStudy else {
            return (1, 1)
        }

        let lastDay = calendar.startOfDay(for: lastDate)
        let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

        switch daysDiff {
        case 0:
            return (oldStreak, 0)
        case 1:
            let newStreak = oldStreak + 1
            return (newStreak, newStreak)
        default:
            return (1, 1)
        }
    }
}

