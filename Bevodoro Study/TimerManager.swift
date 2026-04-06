//
//  TimerManager.swift
//  Bevodoro Study
//
//  Created by Yim, Isabella H on 3/28/26.
//  inspired by UserManager class
//

import Foundation

// demo mode settings
let demoModeStudySeconds = 7
let demoModeBreakSeconds = 5
let demoModeCoinsPerMinute = 60.0
let bevoSickAlertCooldownSeconds: TimeInterval = SettingViewController.isDemoModeEnabled ? 2 * 60 : 5 * 60 // rate limit to show alert every 5 minutes

// 1 coin per minute earning rate
var coinsPerMinute: Double {
    SettingViewController.isDemoModeEnabled ? demoModeCoinsPerMinute : 1.0
}

// defaults
let defaultTimerStudyMins = 25
let defaultTimerBreakMins = 5
let secondsPerMin = 60
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
    private(set) var inStudyMode = true
    private var secondsRemaining: Int

    // use computed properties to get initial study time seconds in case currentUser is null
    var initialStudyTimeSeconds: Int {
        SettingViewController.isDemoModeEnabled ? demoModeStudySeconds :
        (UserManager.shared.currentUser?.settings.timerStudyMins ?? defaultTimerStudyMins) * secondsPerMin
    }
    var initialBreakTimeSeconds: Int {
        SettingViewController.isDemoModeEnabled ? demoModeBreakSeconds :
        (UserManager.shared.currentUser?.settings.timerBreakMins ?? defaultTimerBreakMins) * secondsPerMin
    }
    var isRunning: Bool {
        timer?.isValid == true
    }
    
    // signals
    var onTick: ((Int) -> Void)?
    var onStateChange: ((TimerState) -> Void)? // running / not running
    var onModeChange: ((Bool) -> Void)?  // study / break
    
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
                secondsRemaining = studyMins * secondsPerMin
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
            
            if inStudyMode {
                // ended study mode
                transitionToBreak()
            }
            // fire notification signal before toggling mode
            onTimerComplete?(inStudyMode)

            inStudyMode.toggle()
            onModeChange?(inStudyMode)
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

        secondsRemaining = inStudyMode
            ? initialStudyTimeSeconds
            : initialBreakTimeSeconds

        state = .notStarted
        onStateChange?(state)
    }
    
    // sets the timer back into study mode
    func resetHard() {
        timer?.invalidate()
        timer = nil
        endDate = nil

        inStudyMode = true
        secondsRemaining = initialStudyTimeSeconds

        state = .notStarted
        onStateChange?(state)
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
        // compute coins once
        let earned = UserManager.shared.addCoins(
            timeInSeconds: initialStudyTimeSeconds
        )

        lastStudyEarnedCoins = earned

        // tell UserManager to persist
        UserManager.shared.handleStudyCompleted(
            timeInSeconds: initialStudyTimeSeconds
        )

        // onModeChange?(false)
    }
}
