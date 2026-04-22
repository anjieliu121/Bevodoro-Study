//
//  TimerManager.swift
//  Bevodoro Study
//
//  Created by Yim, Isabella H on 3/28/26.
//  inspired by UserManager class
//

import Foundation

// demo mode settings
let demoModeStudySeconds = 4
let demoModeBreakSeconds = 2
let demoModeLongBreakSeconds = 3
let demoModeCycleLength = 2
let demoModeCoinsPerMinute = 60.0
let bevoSickAlertCooldownSeconds: TimeInterval = 5 * secondsPerMinute // rate limit to show alert every 5 minutes
let demoBevoSickAlertCooldownSeconds: TimeInterval = 2 * secondsPerMinute
let demoCoinBonusAmount = 500

// 1 coin per minute earning rate
var coinsBaseEarningRate = 1.0  // a multiplier (e.g. can increase for special events)
let baseCoinsPerMinute = 2.0
let coinCycleFinishBonus = 50
var coinsPerMinute: Double {
    coinsBaseEarningRate * (SettingViewController.isDemoModeEnabled ? demoModeCoinsPerMinute : baseCoinsPerMinute)
}

// defaults
let pomodoroDurations = [1, 5, 10, 15, 20, 25, 30, 45, 60] // minutes
let pomodoroCycleLengths = [2, 3, 4, 5, 6]

let defaultTimerStudyMins = 25
let defaultTimerBreakMins = 5
let defaultTimerLongBreakMins = 15
let defaultTimerCycleLength = 4  // how many study sessions must be completed before a long break
let minsPerHour = 60

// all possible states the timer can be in
enum TimerState {
    case notStarted
    case running
    case paused
    case finished
}

// manages one timer, which toggles between two modes: study and break. Uses settings from the UserManager object, or defaults
class TimerManager {
    static let shared = TimerManager()  // the manager is a singleton object
    
    // study complete: save coins and timestamp
    var lastStudyEarnedCoins: Int = -1  // last earned study coins

    // timer data
    private var timer: Timer?
    private(set) var state: TimerState = .notStarted
    private var secondsRemaining: Int
    var studySessionCounter: Int = 0  // for Long Break Timer; how many study sesssions were completed during this run of the app.
    
    // modes
    enum TimerMode {
        case study
        case breakTime
        case longBreak
    }
    var currentMode: TimerMode = .study

    // use computed properties to get initial study time seconds in case currentUser is null
    var initialStudyTimeSeconds: Int {
        SettingViewController.isDemoModeEnabled ? demoModeStudySeconds :
        (UserManager.shared.currentUser?.settings.timerStudyMins ?? defaultTimerStudyMins) * Int(secondsPerMinute)
    }
    var initialBreakTimeSeconds: Int {
        SettingViewController.isDemoModeEnabled ? demoModeBreakSeconds :
        (UserManager.shared.currentUser?.settings.timerBreakMins ?? defaultTimerBreakMins) * Int(secondsPerMinute)
    }
    var initialLongBreakTimeSeconds: Int {
        SettingViewController.isDemoModeEnabled ? demoModeLongBreakSeconds :
        (UserManager.shared.currentUser?.settings.timerLongBreakMins ?? defaultTimerLongBreakMins) * Int(secondsPerMinute)
    }
    var cycleLength: Int {
        SettingViewController.isDemoModeEnabled ? demoModeCycleLength :
        (UserManager.shared.currentUser?.settings.timerCycleLength ?? defaultTimerCycleLength)
    }
    
    var isRunning: Bool {
        timer?.isValid == true
    }
    
    // signals
    var onTick: ((Int) -> Void)?
    var onStateChange: ((TimerState) -> Void)? // running / not running
    var onModeChange: ((TimerMode) -> Void)?  // study / breakTime / longBreak
    
    // Called when the timer hits zero.
    var onTimerComplete: ((Bool) -> Void)?
    
    // prevent timer drifting
    private var correctionInterval: Int = 60  // correct every one minute
    private var endDate: Date?
    private var pausedAt: Date?
    
    private init() {
        // initialize variables
        secondsRemaining = defaultTimerStudyMins
        if let studyMins = UserManager.shared.currentUser?.settings.timerStudyMins {
                secondsRemaining = studyMins * Int(secondsPerMinute)
        } else {
            print("TimerManager ERROR: user is nil")
        }
        
        if SettingViewController.isDemoModeEnabled {
            secondsRemaining = demoModeStudySeconds
        }
    }
    
    // start the timer. always initialized to study mode
    func start() {
        guard state != .running else { return }  // prevent two timers from running

        // correct drift: compute an end date.
        if let pausedAt {
            // resume: push the end date forward
            let pauseDuration = Date.now.timeIntervalSince(pausedAt)
            endDate = endDate?.addingTimeInterval(pauseDuration)
            self.pausedAt = nil
        } else if endDate == nil {
            // initial start
            endDate = Date.now.addingTimeInterval(TimeInterval(secondsRemaining))
        }
        
        // create the timer
        timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(tick),
            userInfo: nil,
            repeats: true
        )
        state = .running
        onStateChange?(state)
    }
    
    // advance by one second
    
    @objc private func tick() {
        if secondsRemaining > 0 {
            secondsRemaining -= 1
            // check for timer drift every so often
            if (secondsRemaining % correctionInterval) == 0 {
                self.correctDrift()
            }
            onTick?(secondsRemaining)
        } else {
            // Timer finished
            timer?.invalidate()
            timer = nil

            state = .finished
            onStateChange?(state)

            // capture what just finished
            let finishedStudy = (currentMode == .study)

            // Study-specific side effects
            if finishedStudy {
                transitionToBreak()
            }

            // notify listeners BEFORE mode changes
            onTimerComplete?(finishedStudy)

            // Now switch modes
            switch currentMode {
            case .study:
                currentMode = (studySessionCounter == 0) ? .longBreak : .breakTime

            case .breakTime, .longBreak:
                currentMode = .study
            }

            onModeChange?(currentMode)
            endDate = nil
        }
    }
    
    // correct timer drift by checking with calculated end date
    func correctDrift() {
        guard let endDate else { return }
        let actualRemaining = Int(endDate.timeIntervalSinceNow.rounded())
        secondsRemaining = max(actualRemaining, 0)
    }
    
    // pause the timer
    func pause() {
        guard state == .running else { return }  // already paused

        // stop current timer
        timer?.invalidate()
        timer = nil
        
        // save pause date
        pausedAt = Date()
        
        // change state
        state = .paused
        onStateChange?(state)
    }
    
    // Note to self:  `reset()` is the ONLY place that sets secondsRemaining. Timer completion logic must never refill time.
    // stops the current timer and "refills" its seconds based on the current mode
    func reset() {
        timer?.invalidate()
        timer = nil
        endDate = nil

        switch currentMode {
        case .study:
            secondsRemaining = initialStudyTimeSeconds
        case .breakTime:
            secondsRemaining = initialBreakTimeSeconds
        case .longBreak:
            secondsRemaining = initialLongBreakTimeSeconds
        }

        state = .notStarted
        onStateChange?(state)
    }
    
    // sets the timer back into study mode
    func resetHard() {
        timer?.invalidate()
        timer = nil
        endDate = nil
        studySessionCounter = 0  // reset long break counter

        currentMode = .study
        secondsRemaining = initialStudyTimeSeconds

        state = .notStarted
        onStateChange?(state)
        onModeChange?(currentMode)
    }
    
    func getSecondsRemaining() -> Int {
        return secondsRemaining
    }

    // when time was changed in settings
    func refreshFromSettings() {
        // demo mode ignore firebase's values
        guard !SettingViewController.isDemoModeEnabled else { return }
        
        let minutes =
            UserManager.shared.currentUser?.settings.timerStudyMins
            ?? defaultTimerStudyMins

        let newSeconds = minutes * 60

        // Only update if the timer is not running
        if state == .notStarted || state == .finished {
            secondsRemaining = newSeconds
        }
    }
    
    // study just ended
    private func transitionToBreak() {
        // compute coins and add it
        let earned = calculateCoinsEarned()
        addCoinsToUser(amount: earned)
        lastStudyEarnedCoins = earned
        
        // check for bonus coins (just before long break)
        let transitioningToLongBreak = (studySessionCounter == 0)
        if transitioningToLongBreak {
            print("finished cycle, adding \(coinCycleFinishBonus) bonus coins")
            addCoinsToUser(amount: coinCycleFinishBonus)
        }

        // tell UserManager to persist
        UserManager.shared.handleStudyCompleted(
            timeInSeconds: initialStudyTimeSeconds
        )

        // update counter
        studySessionCounter = (studySessionCounter + 1) % cycleLength
        print("study session counter now at \(studySessionCounter) (CL=\(cycleLength))")
    }
    
    func calculateCoinsEarned() -> Int {
        // calculate coins
        let coinsPerSecond: Double = coinsPerMinute / 60.0   // divide by 60 to get sec
        let earned: Int = Int(Double(initialStudyTimeSeconds) * coinsPerSecond)  // round down
        return earned
    }
    
    func addCoinsToUser(amount: Int) {
        guard var user = UserManager.shared.currentUser else {
            print("error adding coins: user was null")
            return
        }
        print("user starts with \(user.num_coins) coins")
        user.addCoins(amount)
        UserManager.shared.currentUser = user  // MUST save the copy back to the original
        user.saveToFirestore()  // save to firestore
        print("user earned \(amount) coins, now has \(user.num_coins) coins")
    }
}
