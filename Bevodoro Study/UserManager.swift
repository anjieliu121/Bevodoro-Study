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
    
    func addCoins(timeInSeconds: Int) -> Int {
        let coinsPerSecond: Double = coinsPerMinute / 60.0   // divide by 60 to get
        let earned: Int = Int(Double(timeInSeconds) * coinsPerSecond)  // round down
        // NOTE: this also means that any study time less than 1 minute will earn NO coins
        guard var user = UserManager.shared.currentUser else {
            print("error adding coins: user was null")
            return 0
        }
        print("user starts with \(user.num_coins) coins")  // TODO change to label
        user.addCoins(earned)
        UserManager.shared.currentUser = user  // save back to shared user, user is a copy
        user.saveToFirestore()  // save to firestore
        print("user earned \(earned) coins, now has \(user.num_coins) coins")  // TODO change to label
        return earned
    }
}

