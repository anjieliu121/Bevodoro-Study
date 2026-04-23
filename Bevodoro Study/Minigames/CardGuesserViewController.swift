//
//  CardGuesserViewController.swift
//  Bevodoro Study
//
//  Created by Yim, Isabella H on 2/16/26.
//
//  Original Project: YimIsabella-HW4
//  EID: iy925
//  Course: CS371L
//

import UIKit

protocol PipChanger {
    func changePip(newPip: String)
}
protocol SuitChanger {
    func changeSuit(newSuit: String)
}

class CardGuesserViewController: UIViewController, PipChanger, SuitChanger {
    @IBOutlet weak var pipButtonText: UIButton!
    @IBOutlet weak var suitButtonText: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var pipMsg: UILabel!
    @IBOutlet weak var suitMsg: UILabel!
    @IBOutlet weak var guessMsg: UILabel!
    
    let pips: [String] = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
    let suits: [String] = ["Clubs", "Diamonds", "Hearts", "Spades"]
    
    var correctPip: String = ""
    var correctSuit: String = ""
    var correctPipIndex: Int = -1
    var correctSuitIndex: Int = -1

    var pipGuess = ""
    var suitGuess = ""
    var guessCount: Int = 0
    
    var gameIsOver: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetGame()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reloadButtonTitles()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CardGuesserPipSelectSegueIdentifier",
           let nextVC = segue.destination as? CardGuesserPipSelectViewController {
            // moving to CardGuesserPipSelectViewController: set up delegate
            nextVC.delegate = self
            nextVC.pips = self.pips
        }
        if segue.identifier == "CardGuesserSuitSelectSegueIdentifier", let nextVC = segue.destination as? CardGuesserSuitSelectViewController {
            // moving to CardGuesserSuitSelectViewController: set up delegate
            nextVC.delegate = self
            nextVC.suits = self.suits
        }
    }
    
    // check for matches
    @IBAction func submitButtonPressed(_ sender: Any) {
        if gameIsOver {
            // retry was pressed
            resetGame()
        }
        
        if pipGuess == "" || suitGuess == "" {
            guessMsg.text = "Select a pip value and suit first"
        } else {
            guessCount += 1
            var pipCorrect: Bool = false
            var suitCorrect: Bool = false
            
            // set pip message
            let pipGuessIndex: Int = pips.firstIndex(of: pipGuess)!
            if pipGuessIndex < correctPipIndex {
                pipMsg.text = "Your pip value is too low"
            } else if pipGuessIndex > correctPipIndex {
                pipMsg.text = "Your pip value is too high"
            } else {
                pipMsg.text = "Correct pip value"
                pipCorrect = true
            }
            
            // set suit message
            if suitGuess == correctSuit {
                suitMsg.text = "Correct suit"
                suitCorrect = true
            } else {
                suitMsg.text = "Incorrect suit"
            }
            
            // set guess count message
            if pipCorrect && suitCorrect {
                // disable buttons
                disableButtons()
                
                // award coins
                var earned = MinigameMenuViewController.awardCoins()
                
                // display
                let attributed = NSMutableAttributedString(
                    string: "You guessed correctly in \(guessCount) tries! Earned "
                )
                let attachment = NSTextAttachment()
                attachment.image = UIImage(named: "Coin")
                attachment.bounds = CGRect(x: 0, y: -4, width: 18, height: 18)
                attributed.append(NSAttributedString(attachment: attachment))
                attributed.append(NSAttributedString(string: " \(earned)"))
                guessMsg.attributedText = attributed
                
                // change this button to a retry button
                submitButton.setTitle("Retry", for: .normal)
                gameIsOver = true
            } else {
                guessMsg.text = "Guesses so far: \(guessCount)"
            }
        }        
    }
    
    func resetGame() {
        enableButtons()
        setRandomCard()
        
        pipMsg.text = ""
        suitMsg.text = ""
        guessMsg.text = ""
        
        pipGuess = ""
        suitGuess = ""
        guessCount = 0
        
        submitButton.setTitle("Submit Guess", for: .normal)
        reloadButtonTitles()
        
        gameIsOver = false
    }
    
    func setRandomCard() {
        // generate a random card
        correctPipIndex = Int.random(in: 0..<pips.count)
        correctSuitIndex = Int.random(in: 0..<suits.count)
        correctPip = pips[correctPipIndex]
        correctSuit = suits[correctSuitIndex]
        print("correctPip= \(correctPip), correctSuit=\(correctSuit)")
    }
    
    func reloadButtonTitles() {
        // set pip button text
        if pipGuess == "" {
            pipButtonText.setTitle("select pip", for: .normal)
        } else {
            pipButtonText.setTitle(pipGuess, for: .normal)
        }
        
        // set suit button text
        if suitGuess == "" {
            suitButtonText.setTitle("select suit", for: .normal)
        } else {
            suitButtonText.setTitle(suitGuess, for: .normal)
        }
    }
    
    func disableButtons() {
        pipButtonText.isEnabled = false
        suitButtonText.isEnabled = false
    }
    
    func enableButtons() {
        pipButtonText.isEnabled = true
        suitButtonText.isEnabled = true
    }
    
    func changePip(newPip: String) {
        pipGuess = newPip
    }
    
    func changeSuit(newSuit: String) {
        suitGuess = newSuit
    }
}
