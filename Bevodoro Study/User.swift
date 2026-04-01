//
//  User.swift
//  Bevodoro Study
//
// Created by Anjie on 3/11/26.
// Inspired by Isabella.
//

import Foundation
import FirebaseFirestore

struct UserSettings: Codable {
    var bkgMusic: Bool
    var timerStudyMins: Int
    var timerBreakMins: Int
    var haptic: Bool
    var breakReminder: Bool
    var notifications: Bool

    init(
        bkgMusic: Bool = true,
        timerStudyMins: Int = 25,
        timerBreakMins: Int = 5,
        haptic: Bool = true,
        breakReminder: Bool = true,
        notifications: Bool = true
    ) {
        self.bkgMusic = bkgMusic
        self.timerStudyMins = timerStudyMins
        self.timerBreakMins = timerBreakMins
        self.haptic = haptic
        self.breakReminder = breakReminder
        self.notifications = notifications
    }
}

struct User: Codable {
    var userID: String
    var user: String
    var num_coins: Int
    var food: [String: Int]
    /// Keys of medicine items owned at most once (see `ItemCatalog.medicineItems`).
    var medicine: [String]?
    var hats: [String]
    var backgrounds: [String]
    var equippedHat: String?
    var equippedBkg: String?
    var lastLogin: Timestamp
    var settings: UserSettings

    init(
        userID: String,
        user: String,
        num_coins: Int = 0,
        food: [String: Int] = [:],
        medicine: [String]? = nil,
        hats: [String] = [],
        backgrounds: [String] = [ItemCatalog.dayBackgroundKey],
        equippedHat: String? = nil,
        equippedBkg: String? = nil,
        lastLogin: Timestamp = Timestamp(date: Date()),
        settings: UserSettings = UserSettings()
    ) {
        self.userID = userID
        self.user = user
        self.num_coins = num_coins
        self.food = food
        self.medicine = medicine
        self.hats = hats
        self.backgrounds = backgrounds
        self.equippedHat = equippedHat
        self.equippedBkg = equippedBkg
        self.lastLogin = lastLogin
        self.settings = settings
    }

    func saveToFirestore(completion: ((Error?) -> Void)? = nil) {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(userID)

        do {
            let data = try Firestore.Encoder().encode(self)
            docRef.setData(data, merge: true, completion: completion)
        } catch {
            completion?(error)
        }
    }

    mutating func addCoins(_ amount: Int) {
        precondition(amount >= 0, "addCoins expects a non-negative amount")
        num_coins += amount
    }

    mutating func subtractCoins(_ amount: Int) {
        precondition(amount >= 0, "subtractCoins expects a non-negative amount")
        num_coins -= amount
    }

    static func fetch(uid: String, completion: @escaping (User?) -> Void) {
        let docRef = Firestore.firestore().collection("users").document(uid)

        docRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user data:", error.localizedDescription)
                completion(nil)
                return
            }

            guard let data = snapshot?.data() else {
                completion(nil)
                return
            }

            do {
                var user = try Firestore.Decoder().decode(User.self, from: data)
                if !user.backgrounds.contains(ItemCatalog.dayBackgroundKey) {
                    user.backgrounds.append(ItemCatalog.dayBackgroundKey)
                    user.saveToFirestore { err in
                        if let err {
                            print("Error saving starter background:", err.localizedDescription)
                        }
                    }
                }
                completion(user)
            } catch {
                print("Error decoding user:", error.localizedDescription)
                completion(nil)
            }
        }
    }
}
