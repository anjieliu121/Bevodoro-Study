// User.swift
// CS 371L
// created by isabella on 3-8-26

import Firebase
import FirebaseAuth
import FirebaseFirestore // for timestamp

// EG: IMPORANT FIX FOR BETA; CURRENTLY HAVE DATABASE AS PUBLIC. WILL NEED PROPER AUTHETICATION SOON

// User class
class User {
    class UserSettings {
        var bkgMusic: Bool
        var timerStudyMins: Int
        var timerBreakMins: Int
        var haptic: Bool
        var breakReminder: Bool
        var notifications: Bool

        // create defaults
        init() {
            self.bkgMusic = true
            self.timerStudyMins = 25
            self.timerBreakMins = 5
            self.haptic = true
            self.breakReminder = true
            self.notifications = true
        }
        
        // for debugging only, use other init, then change fields as necessary
        init(
            bkgMusic: Bool,
            timerStudyMins: Int,
            timerBreakMins: Int,
            haptic: Bool,
            breakReminder: Bool,
            notifications: Bool
        ) {
            self.bkgMusic = bkgMusic
            self.timerStudyMins = timerStudyMins
            self.timerBreakMins = timerBreakMins
            self.haptic = haptic
            self.breakReminder = breakReminder
            self.notifications = notifications
        }
        
        // for debugging
        func getPrettyString() -> String {
            return """
            \tusernameSettings:
            \tbkgMusic: \(bkgMusic)
            \ttimerStudyMins: \(timerStudyMins)
            \ttimerBreakMins: \(timerBreakMins)
            \thaptic: \(haptic)
            \tbreakReminder: \(breakReminder)
            \tnotifications: \(notifications)
            """
        }
        
        func toDictionary() -> [String: Any] {
            return [
                "bkgMusic": self.bkgMusic,
                "timerStudyMins": self.timerStudyMins,
                "timerBreakMins": self.timerBreakMins,
                "haptic": self.haptic,
                "breakReminder": self.breakReminder,
                "notifications": self.notifications
            ]
        }
    }
    
    var userUID: String                    // Firestore username document ID, get from Auth
    var username: String                   // usernamename string, can change
    var num_coins: Int                     // coin balance
    var food: [String: Int]                // dictionary of food items
    var hats: [String]                     // owned hats
    var backgrounds: [String]              // owned backgrounds
    var equippedHat: String?               // currently equipped hat
    var equippedBkg: String?               // currently equipped background
    var settings: UserSettings             // settings object
    var lastLogin: Timestamp               // last login timestamp, for sick bevo
    
    // for NEW USERS: default settings, no inventory
    init (userUID: String, username: String) {
        self.userUID = userUID
        self.username = username
        num_coins = 0
        food = [:]
        hats = []
        backgrounds = []
        equippedHat = nil // BUG FIX: Can we set actual defaults?
        equippedBkg = nil // note that since this is nil, we have to catch and display default "day" bkg later on
        settings = UserSettings()
        lastLogin = Timestamp(date: Date())
    }
    
    // for existsing users, called by the other init
    private init(
        userUID: String,
        username: String,
        num_coins: Int,
        food: [String : Int],
        hats: [String],
        backgrounds: [String],
        equippedHat: String?,
        equippedBkg: String?,
        settings: UserSettings,
        lastLogin: Timestamp
    ) {
        self.userUID = userUID
        self.username = username
        self.num_coins = num_coins
        self.food = food
        self.hats = hats
        self.backgrounds = backgrounds
        self.equippedHat = equippedHat
        self.equippedBkg = equippedBkg
        self.settings = settings
        self.lastLogin = lastLogin
    }
    
    // for RETURNING users: loads data in, returns nil if error
    // convenience means helper, because firestore is async but normal init can't be async
//    convenience init?(uid: String, username: String, completion: @escaping (User?) -> Void) {
//        // try to get the document in firestore from the uid
//        let docRef = Firestore.firestore().collection("users").document(uid)
//
//        docRef.getDocument { snapshot, error in
//            if let error = error {
//                print("Error fetching user data:", error)
//                completion(nil)
//                return
//            }
//
//            // doc didn't exist
//            guard let data = snapshot?.data() else {
//                completion(nil)
//                return
//            }
//
//            // if data is missing, use defaults
//            let storedUsername = data["username"] as? String ?? ""
//            let num_coins = data["num_coins"] as? Int ?? 0
//            let food = data["food"] as? [String: Int] ?? [:]
//            let hats = data["hats"] as? [String] ?? []
//            let backgrounds = data["backgrounds"] as? [String] ?? []
//            let equippedHat = data["equippedHat"] as? String
//            let equippedBkg = data["equippedBkg"] as? String
//            let lastLogin = data["lastLogin"] as? Timestamp ?? Timestamp(date: Date())
//            //let lastLogin = data["lastLogin"] as? Int ?? Timestamp(date: Date())
//            
//            var settings = UserSettings()
//            if let settingsData = data["settings"] as? [String: Any] {
//                settings = UserSettings(
//                    bkgMusic: settingsData["bkgMusic"] as? Bool ?? true,
//                    timerStudyMins: settingsData["timerStudyMins"] as? Int ?? 25,
//                    timerBreakMins: settingsData["timerBreakMins"] as? Int ?? 5,
//                    haptic: settingsData["haptic"] as? Bool ?? true,
//                    breakReminder: settingsData["breakReminder"] as? Bool ?? true,
//                    notifications: settingsData["notifications"] as? Bool ?? true
//                )
//            }
//            
//            if storedUsername != username {
//                print("Warning! firebase username \(storedUsername) does not match given username \(username)! Continuing with stored username")
//            }
//
//            // build user object using data from firestore
//            let user = User(
//                userUID: uid,
//                username: storedUsername,
//                num_coins: num_coins,
//                food: food,
//                hats: hats,
//                backgrounds: backgrounds,
//                equippedHat: equippedHat,
//                equippedBkg: equippedBkg,
//                settings: settings,
//                lastLogin: lastLogin
//            )
//            
//            // but we also need to set a new last login
//            user.lastLogin = Timestamp(date: Date())
//            user.uploadChangesToFirebase()
//
//            completion(user)
//        }
//
//    }
    
    // for debugging
    func debugInit(
        userUID: String,
        username: String,
        num_coins: Int,
        food: [String : Int],
        hats: [String],
        backgrounds: [String],
        equippedHat: String?,
        equippedBkg: String?,
        settings: UserSettings,
        lastLogin: Timestamp
    ) {
        self.userUID = userUID
        self.username = username
        self.num_coins = num_coins
        self.food = food
        self.hats = hats
        self.backgrounds = backgrounds
        self.equippedHat = equippedHat
        self.equippedBkg = equippedBkg
        self.settings = settings
        self.lastLogin = lastLogin
    }

    // for debugging
    func getPrettyString() -> String {
        return """
        User:
            username: \(username)
            userUID: \(userUID)
            num_coins: \(num_coins)
            food owned and count:
                \(food.map { "\($0.key): \($0.value)" }.joined(separator: "\n\t\t"))
            hats owned:
                \(hats.joined(separator: "\n\t\t"))
            backgrounds owned:
                \(backgrounds.joined(separator: "\n\t\t"))
            equippedHat: \(equippedHat ?? "none")
            equippedBkg: \(equippedBkg ?? "none")
            lastLogin: \(lastLogin)
            settings:
        \(settings.getPrettyString().replacingOccurrences(of: "\n", with: "\n\t"))
        """
    }
    
    // sync to firebase
    // upload changes to firebase
    func uploadChangesToFirebase() {
        let db = Firestore.firestore()
        
        let data: [String: Any] = [
            "username": self.username,
            "num_coins": self.num_coins,
            "food": self.food,
            "hats": self.hats,
            "backgrounds": self.backgrounds,
            "equippedHat": self.equippedHat ?? NSNull(), //temporary fix
            "equippedBkg": self.equippedBkg ?? NSNull(), //temporary fix
            "settings": self.settings.toDictionary(),
            "lastLogin": self.lastLogin
        ]
        
        db.collection("users").document(self.userUID).setData(data) { error in
            if let error = error {
                print("Failed to upload user data:", error)
            } else {
                print("Successfully updated user data in Firestore.")
            }
        }
    }
}


// // usage example
// var bob = User(userUID: "fb43-34k34-233", username: "bob")
// bob.debugInit(
//     userUID: "fb43-34k34-233",
//     username: "bob",
//     num_coins: 25,
//     food: ["apple": 2, "banana": 3, "pill": 1],
//     hats: ["cowboy", "cap"],
//     backgrounds: ["night", "ocean"],
//     equippedHat: "cowboy",
//     equippedBkg: "night",
//     settings: UserSettings(
//         bkgMusic: true,
//         timerStudyMins: 25,
//         timerBreakMins: 5,
//         haptic: true,
//         breakReminder: true,
//         notifications: true
//     ),
//     lastLogin: Timestamp(date: Date())
// )


