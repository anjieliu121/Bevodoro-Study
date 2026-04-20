//
//  UserManager.swift
//  Bevodoro Study
//
//  Created by Anjie on 3/11/26.
//

import Foundation

class UserManager {
    static let shared = UserManager()
    var currentUser: User?
    private init() {
    }

    // called when a study session completes: when study timer ends updates lastStudy
    func handleStudyCompleted(timeInSeconds: Int) {
        guard var user = currentUser else { return }
        // coins, moved update in TimerManager::transitionToBreak
        user.updateLastStudyNow()
        currentUser = user  // MUST save back
        user.saveToFirestore()
    }
}

