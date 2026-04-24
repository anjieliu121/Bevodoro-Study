//
//  User.swift
//  Bevodoro Study
//
// Created by Anjie on 3/11/26.
// Inspired by Isabella.
//

import Foundation
import FirebaseFirestore

let secondsPerDays = 1.0 * 60 * 60 * 24
let secondsPerMinute = 60.0
let bevoSickThresholdDays = 2.0  // after how many days since last login that bevo will be considered sick
let bevoSickThresholdSeconds = bevoSickThresholdDays * secondsPerDays
let demoBevoSickThresholdSeconds = 30.0

struct UserSettings: Codable {
    var bkgMusic: Bool
    var timerStudyMins: Int
    var timerBreakMins: Int
    var timerLongBreakMins: Int
    var timerCycleLength: Int
    var haptic: Bool
    var breakReminder: Bool
    var notifications: Bool

    init(
        bkgMusic: Bool = true,
        timerStudyMins: Int = 25,
        timerBreakMins: Int = 5,
        timerLongBreakMins: Int = 15,
        timerCycleLength: Int = 4,
        haptic: Bool = true,
        breakReminder: Bool = true,
        notifications: Bool = true
    ) {
        self.bkgMusic = bkgMusic
        self.timerStudyMins = timerStudyMins
        self.timerBreakMins = timerBreakMins
        self.timerLongBreakMins = timerLongBreakMins
        self.timerCycleLength = timerCycleLength
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
    /// Per-key counts like `food` (see `ItemCatalog.medicineItems`). Decodes legacy Firestore arrays of keys.
    var medicine: [String: Int]
    var hats: [String]
    var backgrounds: [String]
    var equippedHat: String?
    var equippedBkg: String?
    var lastLogin: Timestamp
    var lastStudy: Timestamp?  // may be null
    var numCompletedStudySessions: Int
    var studyStreak: Int
    var lastStreakBonusDate: Timestamp?
    var settings: UserSettings

    init(
        userID: String,
        user: String,
        num_coins: Int = 0,
        food: [String: Int] = [:],
        medicine: [String: Int] = [:],
        hats: [String] = [],
        backgrounds: [String] = [ItemCatalog.dayBackgroundKey],
        equippedHat: String? = nil,
        equippedBkg: String? = nil,
        lastLogin: Timestamp = Timestamp(date: Date()),
        lastStudy: Timestamp? = nil,
        numCompletedStudySessions: Int = 0,
        studyStreak: Int = 0,
        lastStreakBonusDate: Timestamp? = nil,
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
        self.lastStudy = lastStudy
        self.numCompletedStudySessions = numCompletedStudySessions
        self.studyStreak = studyStreak
        self.lastStreakBonusDate = lastStreakBonusDate
        self.settings = settings
    }

    enum CodingKeys: String, CodingKey {
        case userID, user, num_coins, food, medicine, hats, backgrounds
        case equippedHat, equippedBkg, lastLogin, lastStudy, settings
        case numCompletedStudySessions, studyStreak, lastStreakBonusDate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userID = try c.decode(String.self, forKey: .userID)
        user = try c.decode(String.self, forKey: .user)
        num_coins = try c.decode(Int.self, forKey: .num_coins)
        food = try c.decodeIfPresent([String: Int].self, forKey: .food) ?? [:]
        medicine = Self.decodeMedicineCounts(from: c)
        hats = try c.decodeIfPresent([String].self, forKey: .hats) ?? []
        backgrounds = try c.decodeIfPresent([String].self, forKey: .backgrounds) ?? []
        equippedHat = try c.decodeIfPresent(String.self, forKey: .equippedHat)
        equippedBkg = try c.decodeIfPresent(String.self, forKey: .equippedBkg)
        lastLogin = try c.decode(Timestamp.self, forKey: .lastLogin)
        lastStudy = try c.decodeIfPresent(Timestamp.self, forKey: .lastStudy)
        numCompletedStudySessions = try c.decodeIfPresent(Int.self, forKey: .numCompletedStudySessions) ?? 0
        studyStreak = try c.decodeIfPresent(Int.self, forKey: .studyStreak) ?? 0
        lastStreakBonusDate = try c.decodeIfPresent(Timestamp.self, forKey: .lastStreakBonusDate)
        settings = try c.decodeIfPresent(UserSettings.self, forKey: .settings) ?? UserSettings()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(userID, forKey: .userID)
        try c.encode(user, forKey: .user)
        try c.encode(num_coins, forKey: .num_coins)
        try c.encode(food, forKey: .food)
        try c.encode(medicine, forKey: .medicine)
        try c.encode(hats, forKey: .hats)
        try c.encode(backgrounds, forKey: .backgrounds)
        try c.encodeIfPresent(equippedHat, forKey: .equippedHat)
        try c.encodeIfPresent(equippedBkg, forKey: .equippedBkg)
        try c.encode(lastLogin, forKey: .lastLogin)
        try c.encodeIfPresent(lastStudy, forKey: .lastStudy)
        try c.encode(numCompletedStudySessions, forKey: .numCompletedStudySessions)
        try c.encode(studyStreak, forKey: .studyStreak)
        try c.encodeIfPresent(lastStreakBonusDate, forKey: .lastStreakBonusDate)
        try c.encode(settings, forKey: .settings)
    }

    private static func decodeMedicineCounts(from c: KeyedDecodingContainer<CodingKeys>) -> [String: Int] {
        if let dict = try? c.decode([String: Int].self, forKey: .medicine) {
            return dict
        }
        if let arr = try? c.decode([String].self, forKey: .medicine) {
            var out: [String: Int] = [:]
            for key in arr {
                out[key, default: 0] += 1
            }
            return out
        }
        return [:]
    }

    func saveToFirestore(completion: ((Error?) -> Void)? = nil) {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(userID)

        do {
            // `setData(..., merge: true)` merges nested map keys; it does **not** delete missing keys under `food`,
            // so eaten items would otherwise stay on the server. Replace `food` in a separate `updateData`.
            var encoded = try Firestore.Encoder().encode(self)
            encoded.removeValue(forKey: "food")
            let batch = db.batch()
            batch.setData(encoded, forDocument: docRef, merge: true)
            batch.updateData([
                "food": food,
                "foods": FieldValue.delete()
            ], forDocument: docRef)
            batch.commit(completion: completion)
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
                // warning comes from threshold call in isSick(). see note there for the fix.
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
    
    // updates the last login timestamp to the current time
    mutating func updateLastStudyNow() {
        lastStudy = Timestamp(date: Date())
    }
    
    // True if more than threshold time has passed since last login
    func isSick() -> Bool {
        guard lastStudy != nil else { return false }  // nil for new users
        let lastStudyDate = lastStudy!.dateValue()
        let now = Date()
        // TODO calling SettingViewController here creates a dependency on a VC. move the setting to a new class, modify that class's var in SettingViewController, then set classs User to use the seting in the new class.
        let threshold = SettingViewController.isDemoModeEnabled ? demoBevoSickThresholdSeconds : bevoSickThresholdSeconds
        let cooldown = SettingViewController.isDemoModeEnabled ? demoBevoSickAlertCooldownSeconds : bevoSickAlertCooldownSeconds

        print("""
        DEBUG: isSick check
        lastStudy: \(lastStudyDate)
        now:       \(now)
        delta:     \(now.timeIntervalSince(lastStudyDate))
        threshold: \(threshold), but limited every \(cooldown) seconds
        """)

        guard lastStudyDate <= now else {
            print("error: isSick error lastStudy cutoff is in the future!")
            return false
        }
        return now.timeIntervalSince(lastStudyDate) >= threshold
    }
}
