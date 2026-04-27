//
//  TimerViewController.swift
//  Bevodoro Study
//
//  Created by Yim, Isabella H on 3/5/26.
//

import UIKit
import UserNotifications

let endStudyMessage: String = "Study complete!"
let endBreakMessage: String = "Great break. Let's get back to it!"
let endMessage: String = "Session ended."

class TimerViewController: UIViewController {
    @IBOutlet weak var timerLabel: UILabel!  // displays the current time
    @IBOutlet weak var startButton: UIButton!  // the start/pause button
    @IBOutlet weak var endButton: UIButton!  // the end study session button
    @IBOutlet weak var endView: UIView!  // view holding endMsg
    @IBOutlet weak var endMsg: UILabel!  // messages that appear when the timer reaches 0
    @IBOutlet weak var modeLabel: UILabel! // mode currently in (study, break, long break
    
    var delegate: UIViewController!  // note: will eventually neeed to segue from main to here.
    
    let timerManager = TimerManager.shared  // timer
    var modeLabelStudy: String { "Study! \(TimerManager.shared.studySessionCounter + 1)/\(TimerManager.shared.cycleLength)" }
    let modeLabelBreak: String  = "Break!"
    let modeLabelLongBreak: String  = "Long Break!"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // font for buttons
        startButton.titleLabel?.font = UIFont(name: "SourGummy", size: 20)
        endButton.titleLabel?.font = UIFont(name: "SourGummy", size: 20)

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
        timerManager.onModeChange = { [weak self] mode in
            guard let self = self else { return }

            // only show when something FINISHED not only on initial load
            let shouldShowEndMessage = (timerManager.state == .finished)
            self.endView.isHidden = !shouldShowEndMessage

            switch mode {
            case .study:
                // Break or long break just ended
                self.modeLabel.text = modeLabelStudy
                self.endMsg.text = endBreakMessage
            case .breakTime:
                // Normal break started = study just completed
                self.modeLabel.text = modeLabelBreak
                self.showStudyCompletedMessage(isLongBreak: false)

            case .longBreak:
                // Long break started = study just completed
                self.modeLabel.text = modeLabelLongBreak
                self.showStudyCompletedMessage(isLongBreak: true)
            }
        }
        
        // fire a local notification when the timer finishes
        timerManager.onTimerComplete = { completedStudyMode in
            if completedStudyMode {
                TimerViewController.sendNotif(
                    title: "Study session complete!",
                    body: "Great work! Time to take a break."
                )
            } else {
                TimerViewController.sendNotif(
                    title: "Break's over!",
                    body: "Ready to get back to studying?"
                )
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
        
        // Always hide end message when re-entering
        endView.isHidden = true
        endMsg.text = ""

        // update mode label
        switch timerManager.currentMode {
        case .study:
            modeLabel.text = modeLabelStudy
        case .breakTime:
            modeLabel.text = modeLabelBreak
        case .longBreak:
            modeLabel.text = modeLabelLongBreak
        }
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
        
        // fonts please stay
        startButton.titleLabel?.font = UIFont(name: "SourGummy", size: 20)
        endButton.titleLabel?.font = UIFont(name: "SourGummy", size: 20)

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
        if timerManager.currentMode == .study {
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
        guard seconds < Int(secondsPerMinute) * minsPerHour else { return "60:00*" }
        let mins = (seconds / Int(secondsPerMinute)) % Int(secondsPerMinute)
        let secs = seconds % Int(secondsPerMinute)
        return String(format: "%02i:%02i", mins, secs)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // dispose of any resouces that can be recreated.
        // why do i need this? no clue but it sounds like it makes sense.
        guard let user = UserManager.shared.currentUser else { return }
        print("TimerViewController Warning: didReceiveMemoryWarning was triggered for user \(user.user)")
    }
    
    // Sends notifcsations
    private static func sendNotif(title: String, body: String) {
        guard SettingViewController.isNotificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
            
        // fire immediately (0.1s delay required by the API)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("TimerViewController: failed to send notification: \(error)")
            }
        }
    }
    
    private func showStudyCompletedMessage(isLongBreak: Bool) {
        let earned = timerManager.lastStudyEarnedCoins

        let attributed = NSMutableAttributedString(
            string: "\(endStudyMessage) You earned "
        )

        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: "Coin")
        attachment.bounds = CGRect(x: 0, y: -4, width: 18, height: 18)

        attributed.append(NSAttributedString(attachment: attachment))
        
        if isLongBreak {
            attributed.append(NSAttributedString(string: " \(earned)! \nGreat job finishing a cycle, so now enjoy a long break! Remember to stretch and drink water. \nCompleted pomodoro cycle bonus of +\(coinCycleFinishBonus) "))
            attributed.append(NSAttributedString(attachment: attachment))
        } else {
            attributed.append(NSAttributedString(string: " \(earned)! Let's take a break!"))
        }
        
        endMsg.attributedText = attributed
        endMsg.numberOfLines = 0
    }

}
