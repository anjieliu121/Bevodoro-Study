//
//  TimerViewController.swift
//  Bevodoro Study
//
//  Created by Yim, Isabella H on 3/5/26.
//

import UIKit

// what the timer gets initialized to. TODO eventually change to a global variable in settings
let initialStudyTimeSeconds: Int = (UserManager.shared.currentUser?.settings.timerStudyMins ?? 25) * 60 // 6 //0 * 25  // 25 minutes
let initialBreakTimeSeconds: Int = (UserManager.shared.currentUser?.settings.timerBreakMins ?? 5) * 60 //0 * 5  // 5 minutes
// TODO convert the time mentioned in these variables to be calculated instead of hard coded
let endStudyMessage: String = "Study complete!"
let endBreakMessage: String = "Great break. Let's get back to it!"
let endMessage: String = "Session ended. No coins earned"

class TimerViewController: UIViewController {
    @IBOutlet weak var timerLabel: UILabel!  // displays the current time
    @IBOutlet weak var startButtonLabel: UIButton!  // the start/pause button
    @IBOutlet weak var endButtonLabel: UIButton!  // the end study session button
    @IBOutlet weak var endMsg: UILabel!  // messages that appear when the timer reaches 0
    var delegate: UIViewController!  // note: will eventually neeed to segue from main to here.
    
    var inStudyMode: Bool = true  // as opposed to break mode (controls timer initialization)
    var timerIsRunning: Bool = false
    var curSeconds: Int = initialStudyTimeSeconds
    var timer: Timer = Timer()

    override func viewDidLoad() {
        super.viewDidLoad()
        // initialize displayed time
        timerLabel.text = time2String(time: curSeconds)
        endButtonLabel.isHidden = true
    }
    
    // functions as both the start AND pause button
    @IBAction func startButtonPressed(_ sender: Any) {
        endMsg.text = ""  // reset the end message
        if timerIsRunning {
            // pause the timer
//            print("timer paused")
            endButtonLabel.isHidden = false
            timer.invalidate()
            timerIsRunning = false
            startButtonLabel.setTitle("resume", for: .normal)
        } else {
            // resume the timer
//            print("timer resumed")
            endButtonLabel.isHidden = true
            runTimer()
            startButtonLabel.setTitle("pause", for: .normal)
        }
    }
    
    // resets timer back to the beginning of study mode, no coins given
    // this also means that it stops th break.
    @IBAction func endButtonPressed(_ sender: Any) {
        endMsg.text = inStudyMode ? endMessage : ""
        inStudyMode = true
        resetTimer()
    }
    
    // debug: reset the timer (will move placement later to another button)
    @IBAction func resetButtonPressed(_ sender: Any) {
        resetTimer()
    }
    
    // resets the timer and display
    func resetTimer () {
        timer.invalidate()
        timerIsRunning = false
        startButtonLabel.setTitle("Start Timer!", for: .normal)
        curSeconds = inStudyMode ? initialStudyTimeSeconds : initialBreakTimeSeconds
        timerLabel.text = time2String(time: curSeconds)
        endButtonLabel.isHidden = true
    }
    
    // runs the timer
    func runTimer() {
        if timer.isValid {
            print("TimerViewController Warning: tried to make a duplicate timer! skipped.")
            return
        }
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
        timerIsRunning = true
    }
    
    // converts a TimeInterval to a string. assumes < 1 hour
    func time2String(time: Int) -> String {
        guard time < 60 * 60 else { return "60:00*" }
        let minutes = (time / 60) % 60
        let seconds = time % 60
        return String(format: "%02i:%02i", minutes, seconds)
    }
    
    // youtube turtoerial used objectice c function
    // use for now, even though we haven't learned it yet
    @objc func updateTimer() {
        if curSeconds < 1 {
            // reached 0 seconds. stops the timer.
            timer.invalidate()
            if inStudyMode {
                // end study time, start break time
                inStudyMode = false
                curSeconds = initialBreakTimeSeconds
                var earned: Int = addCoins(timeInSeconds: initialStudyTimeSeconds)
                endMsg.text = endStudyMessage + " You earned \(earned) coins. Let's take a break!"
            } else {
                // end break time, start study time
                inStudyMode = true
                endMsg.text = endBreakMessage
                curSeconds = initialStudyTimeSeconds
            }
            resetTimer()
        } else {
            curSeconds -= 1
            timerLabel.text = time2String(time: curSeconds)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // dispose of any resouces that can be recreated.
        // why do i need this? no clue but it sounds like it makes sense.
        guard var user = UserManager.shared.currentUser else { return }
        print("TimerViewController Warning: didReceiveMemoryWarning was triggered")
    }
    
    func addCoins(timeInSeconds: Int) -> Int {
        var rate: Double = 1.0/60  // 1 coin per minute
        var earned: Int = Int(Double(timeInSeconds) * rate) // round down
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

