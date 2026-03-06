//
//  TimerViewController.swift
//  Bevodoro Study
//
//  Created by Yim, Isabella H on 3/5/26.
//

import UIKit

// what the timer gets initialized to. TODO eventually change to a global variable in settings
//    var initialTimeSeconds = 60 * 25
let initialTimeSeconds: Int = 65

class TimerViewController: UIViewController {
    @IBOutlet weak var timerLabel: UILabel!  // displays the current time
    @IBOutlet weak var buttonLabel: UIButton!  // the start/pause button
    var delegate: UIViewController!  // note: will eventually neeed to segue from main to here.
    
    var timerIsRunning: Bool = false
    var curSeconds: Int = initialTimeSeconds
    var timer: Timer = Timer()

    override func viewDidLoad() {
        super.viewDidLoad()
        timerLabel.text = time2String(time: curSeconds)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // dispose of any resouces that can be recreated.
        // why do i need this? no clue but it sounds like it makes sense.
        print("TimerViewController Warning: didReceiveMemoryWarning wa triggered")
    }
    
    // functions as both the start AND pause button
    @IBAction func startButtonPressed(_ sender: Any) {
        if timerIsRunning {
            // pause the timer
            timer.invalidate()
            timerIsRunning = false
            buttonLabel.setTitle("start", for: .normal)
        } else {
            // resume the timer
            runTimer()
            buttonLabel.setTitle("pause", for: .normal)
        }
    }
    
    // debug: reset the timer (will move placement later to another button)
    @IBAction func resetButtonPressed(_ sender: Any) {
        timer.invalidate()
        timerIsRunning = false
        buttonLabel.setTitle("Start Timer!", for: .normal)
        curSeconds = initialTimeSeconds
        timerLabel.text = time2String(time: initialTimeSeconds)
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
        } else {
            curSeconds -= 1
            timerLabel.text = time2String(time: curSeconds)
        }
    }
}

