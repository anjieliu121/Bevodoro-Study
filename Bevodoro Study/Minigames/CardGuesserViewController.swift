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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pipMsg.text = ""
        suitMsg.text = ""
        guessMsg.text = ""
        
        // generate a random card
        correctPipIndex = Int.random(in: 0..<pips.count)
        correctSuitIndex = Int.random(in: 0..<suits.count)
        correctPip = pips[correctPipIndex]
        correctSuit = suits[correctSuitIndex]
        print("correctPip= \(correctPip), correctSuit=\(correctSuit)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
                guessMsg.text = "You guessed correctly in \(guessCount) tries!"
            } else {
                guessMsg.text = "Guesses so far: \(guessCount)"
            }
        }        
    }
    
    func changePip(newPip: String) {
        pipGuess = newPip
    }
    
    func changeSuit(newSuit: String) {
        suitGuess = newSuit
    }
}
