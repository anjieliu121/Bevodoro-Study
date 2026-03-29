//
//  TimerManager.swift
//  Bevodoro Study
//
//  Created by Yim, Isabella H on 3/28/26.
//  inspired by UserManager class
//

import Foundation

let defaultTimerStudyMins = 25
let defaultTimerBreakMins = 5
let secondsPerMin = 60

// tracks one timer
class TimerManager {
    static let shared = TimerManager()  // the manager is a singleton object

    private var currentTimer: Timer?
    private(set) var inStudyMode = true
    private var secondsRemaining: Int

    // use computed properties to get initial study time seconds in case currentUser is null
    var initialStudyTimeSeconds: Int {
        (UserManager.shared.currentUser?.settings.timerStudyMins ?? defaultTimerStudyMins) * secondsPerMin
    }
    var initialBreakTimeSeconds: Int {
        (UserManager.shared.currentUser?.settings.timerBreakMins ?? defaultTimerBreakMins) * secondsPerMin
    }
    var isRunning: Bool {
        currentTimer?.isValid == true
    }
    
    private init() {
        // initialize variables
        secondsRemaining = (UserManager.shared.currentUser?.settings.timerStudyMins ?? defaultTimerStudyMins) * secondsPerMin
    }
}
