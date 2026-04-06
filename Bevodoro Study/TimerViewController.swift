//
//  TimerViewController.swift
//  Bevodoro Study
//
//  Created by Yim, Isabella H on 3/5/26.
//

import UIKit

let endStudyMessage: String = "Study complete!"
let endBreakMessage: String = "Great break. Let's get back to it!"
let endMessage: String = "Session ended."

class TimerViewController: UIViewController {
    @IBOutlet weak var timerLabel: UILabel!  // displays the current time
    @IBOutlet weak var startButton: UIButton!  // the start/pause button
    @IBOutlet weak var endButton: UIButton!  // the end study session button
    @IBOutlet weak var endView: UIView!  // view holding endMsg
    @IBOutlet weak var endMsg: UILabel!  // messages that appear when the timer reaches 0
    var delegate: UIViewController!  // note: will eventually neeed to segue from main to here.
    
    let timerManager = TimerManager.shared  // timer

    override func viewDidLoad() {
        super.viewDidLoad()

        // ---- setup handlers for timer state changes ----
        // display the seconds, updated every second
        timerManager.onTick = { [weak self] secondsRemaining in
            guard let self = self else { return }  // prevent loop thingy
            self.timerLabel.text = self.seconds2String(seconds: secondsRemaining)
        }

        // change start button text when timer starts / pauses
        timerManager.onStateChange = { [weak self] state in
            guard let self = self else { return }
            self.updateUI(state: state)
        }

        // set end messages when study/break mode switches
        timerManager.onModeChange = { [weak self] inStudyMode in
            guard let self = self else { return }

            self.endView.isHidden = false
            if inStudyMode {
                self.endMsg.text = endBreakMessage
            } else {
                let earned = self.timerManager.lastStudyEarnedCoins
                let attributed = NSMutableAttributedString(string: "\(endStudyMessage) You earned ")

                let attachment = NSTextAttachment()
                attachment.image = UIImage(named: "Coin")
                attachment.bounds = CGRect(x: 0, y: -4, width: 18, height: 18)

                attributed.append(NSAttributedString(attachment: attachment))
                attributed.append(NSAttributedString(string: " \(earned)! Let's take a break!"))

                endMsg.attributedText = attributed
                endMsg.numberOfLines = 0
            }
        }
        
        // initial UI state
        timerLabel.text = seconds2String(seconds: timerManager.getSecondsRemaining())
        endButton.isHidden = true
        endView.isHidden = true
        endMsg.text = ""
        updateUI(state: timerManager.state)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        timerManager.refreshFromSettings()
        timerLabel.text = seconds2String(seconds: timerManager.getSecondsRemaining())
        updateUI(state: timerManager.state)
    }
    
    func updateUI(state: TimerState) {
        switch state {
        case .notStarted, .finished:
            startButton.setTitle("Start Timer!", for: .normal)
            endButton.isHidden = true

        case .running:
            startButton.setTitle("pause", for: .normal)
            endButton.isHidden = true

        case .paused:
            startButton.setTitle("resume", for: .normal)
            endButton.isHidden = false
        }
    }
    
    // functions as both the start AND pause button
    @IBAction func startButtonPressed(_ sender: Any) {
        endView.isHidden = true
        endMsg.text = ""  // clear any previous end message

        // fill the timer with the correct number of seconds
        switch timerManager.state {
        case .notStarted, .paused:
            timerManager.start()

        case .running:
            timerManager.pause()

        case .finished:
            timerManager.reset()
            timerManager.start()
        }
        
        // fill the correct number of seconds in the label
        self.timerLabel.text = seconds2String(seconds: timerManager.getSecondsRemaining())
    }
    
    @IBAction func endButtonPressed(_ sender: Any) {
        // show message only if ending a study session
        if timerManager.inStudyMode {
            let attributed = NSMutableAttributedString(string: "\(endMessage) No ")

            let attachment = NSTextAttachment()
            attachment.image = UIImage(named: "Coin")
            attachment.bounds = CGRect(x: 0, y: -4, width: 18, height: 18)

            attributed.append(NSAttributedString(attachment: attachment))
            attributed.append(NSAttributedString(string: " earned"))

            endMsg.attributedText = attributed
            endMsg.numberOfLines = 0

            endView.isHidden = false
        } else {
            endMsg.text = ""
            endView.isHidden = true
        }
        // force reset back to study mode
        timerManager.resetHard()
        // show the seconds
        timerLabel.text = seconds2String(seconds: timerManager.getSecondsRemaining())
    }

    // converts a TimeInterval to a string. assumes < 1 hour
    func seconds2String(seconds: Int) -> String {
        guard seconds < secondsPerMin * minsPerHour else { return "60:00*" }
        let mins = (seconds / secondsPerMin) % secondsPerMin
        let secs = seconds % secondsPerMin
        return String(format: "%02i:%02i", mins, secs)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // dispose of any resouces that can be recreated.
        // why do i need this? no clue but it sounds like it makes sense.
        guard let user = UserManager.shared.currentUser else { return }
        print("TimerViewController Warning: didReceiveMemoryWarning was triggered for user \(user.user)")
    }
}

