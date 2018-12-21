//
//  ChairUmpireSettingsViewController.swift
//  Deuce
//
//  Created by Austin Conlon on 4/1/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import UIKit
import WatchConnectivity

class ChairUmpireViewController: UIViewController {
    
    // MARK: Properties
    var scoreManager: ScoreManager?
    var currentGame: GameManager {
        get {
            return currentSet.currentGame
        }
    }
    var currentSet: SetManager {
        get {
            return scoreManager!.currentMatch.currentSet
        }
    }
    var currentMatch: MatchManager {
        get {
            return scoreManager!.currentMatch
        }
    }
    
    var maximumNumberOfSetsInMatch = 1 { // Matches are 1 set, best-of 3 sets, or best-of 5 sets.
        didSet {
            switch maximumNumberOfSetsInMatch {
            case 3:
                changeMatchLengthSegmentedControl.selectedSegmentIndex = 1
            case 5:
                changeMatchLengthSegmentedControl.selectedSegmentIndex = 2
            default:
                changeMatchLengthSegmentedControl.selectedSegmentIndex = 0
            }
        }
    }
    
    var typeOfSet: TypeOfSet = .tiebreak { // Tiebreak sets are more commonly played.
        didSet {
            switch typeOfSet {
            case .advantage:
                setTypeSegmentedControl.selectedSegmentIndex = 1
            default:
                setTypeSegmentedControl.selectedSegmentIndex = 0
            }
        }
    }
    
    var playerThatWillServeFirst: Player?
    
    // Properties for displaying the score to be easily read in the navigation bar.
    var serverScore: String {
        get {
            if currentGame.server == .one {
                return playerOneGameScore
            } else {
                return playerTwoGameScore
            }
        }
    }
    
    var receiverScore: String {
        get {
            if currentGame.server == .one {
                return playerTwoGameScore
            } else {
                return playerOneGameScore
            }
        }
    }
    
    var playerOneGameScore: String {
        get {
            switch currentGame.isTiebreak {
            case true:
                return String(currentGame.playerOneScore)
            default:
                switch currentGame.playerOneScore {
                case 0:
                    return NSLocalizedString("Love", tableName: "Main", comment: "Game score of 0")
                case 15, 30:
                    return String(currentGame.playerOneScore)
                case 40:
                    if currentGame.playerTwoScore < 40 {
                        return String(currentGame.playerOneScore)
                    } else if currentGame.playerTwoScore == 40 {
                        return "Deuce"
                    }
                default: // Alternating advantage and deuce situations.
                    if currentGame.playerOneScore == currentGame.playerTwoScore + 1 {
                        if currentGame.server == .one {
                            return "Ad in"
                        } else if currentGame.server == .two {
                            return "Ad out"
                        }
                    } else if currentGame.playerOneScore == currentGame.playerTwoScore {
                        return "Deuce"
                    }
                }
            }
            return ""
        }
    }
    
    var playerTwoGameScore: String {
        switch currentGame.isTiebreak {
        case true:
            return String(currentGame.playerTwoScore)
        default:
            switch currentGame.playerTwoScore {
            case 0:
                return NSLocalizedString("Love", tableName: "Main", comment: "Game score of 0")
            case 15, 30:
                return String(currentGame.playerTwoScore)
            case 40:
                if currentGame.playerOneScore < 40 {
                    return String(currentGame.playerTwoScore)
                } else if currentGame.playerOneScore == 40 {
                    return "Deuce"
                }
            default: // Alternating advantage and deuce situations.
                if currentGame.playerTwoScore == currentGame.playerOneScore + 1 {
                    if currentGame.server == .two {
                        return "Ad in"
                    } else if currentGame.server == .one {
                        return "Ad out"
                    }
                } else if currentGame.playerTwoScore == currentGame.playerOneScore {
                    return "Deuce"
                }
            }
        }
        return ""
    }
    
    @IBOutlet weak var startMatchButton: UIBarButtonItem!
    @IBOutlet weak var endMatchButton: UIBarButtonItem!
    @IBOutlet weak var changeMatchLengthSegmentedControl: UISegmentedControl!
    @IBOutlet weak var setTypeSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var playerOneServiceLabel: UILabel!
    @IBOutlet weak var playerOneGameScoreButton: UIButton!
    @IBOutlet weak var playerOneSetScoreLabel: UILabel!
    @IBOutlet weak var playerOneMatchScoreLabel: UILabel!
    
    @IBOutlet weak var playerTwoServiceLabel: UILabel!
    @IBOutlet weak var playerTwoGameScoreButton: UIButton!
    @IBOutlet weak var playerTwoSetScoreLabel: UILabel!
    @IBOutlet weak var playerTwoMatchScoreLabel: UILabel!
    
    @IBAction func changeMatchLength(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1:
            maximumNumberOfSetsInMatch = 3
        case 2:
            maximumNumberOfSetsInMatch = 5
        default:
            maximumNumberOfSetsInMatch = 1
        }
    }
    
    @IBAction func changeTypeOfSet(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            typeOfSet = .tiebreak
        case 1:
            typeOfSet = .advantage
        default:
            break
        }
    }
    
    @IBAction func startMatch(_ sender: Any) {
        coinToss()
    }
    
    @IBAction func stopMatch(_ sender: Any) {
        if currentMatch.isFinished == false {
            let alert = UIAlertController(title: "End Match?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel action"), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .destructive, handler: { _ in
                self.updateLabelsForEndOfMatch()
                self.navigationController?.popToRootViewController(animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            updateLabelsForEndOfMatch()
        }
    }
    
    @IBAction func scorePointForPlayerOne(_ sender: Any) {
        currentMatch.scorePointForPlayerOne()
        updateLabelsFromModel()
    }
    
    @IBAction func scorePointForPlayerTwo(_ sender: Any) {
        currentMatch.scorePointForPlayerTwo()
        updateLabelsFromModel()
    }
    
    func coinToss() {
        let coinTossResult: String
        let flippedHeads = Bool.random()
        if flippedHeads {
            coinTossResult = "The player starting on your left side won the coin toss. Select their choice of who will serve first."
        } else {
            coinTossResult = "The player starting on your right side won the coin toss. Select their choice of who will serve first."
        }
        let alert = UIAlertController(title: "Coin Toss", message: coinTossResult, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Left Player", style: .default, handler: { _ in
            self.playerThatWillServeFirst = .one
            self.startScoring()
        }))
        alert.addAction(UIAlertAction(title: "Right Player", style: .default, handler: { _ in
            self.playerThatWillServeFirst = .two
            self.startScoring()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func startScoring() {
        let match = MatchManager(self.maximumNumberOfSetsInMatch, self.typeOfSet, self.playerThatWillServeFirst!)
        self.scoreManager = ScoreManager(match)
        updateLabelsFromModel()
        changeMatchLengthSegmentedControl.isHidden = true
        setTypeSegmentedControl.isHidden = true
        startMatchButton.isEnabled = false
        endMatchButton.isEnabled = true
        playerOneGameScoreButton.isEnabled = true
        playerOneGameScoreButton.isHidden = false
        playerOneSetScoreLabel.isHidden = false
        playerOneMatchScoreLabel.isHidden = false
        playerTwoGameScoreButton.isEnabled = true
        playerTwoGameScoreButton.isHidden = false
        playerTwoSetScoreLabel.isHidden = false
        playerTwoMatchScoreLabel.isHidden = false
        let server = (scoreManager?.currentMatch.currentSet.currentGame.server)!
        switch server {
        case .one:
            playerOneServiceLabel.isHidden = false
        case .two:
            playerTwoServiceLabel.isHidden = false
        }
    }
    
    func updateLabelsFromModel() {
        updateServingLabelsFromModel()
        updateNavigationBarGameScoreFromModel()
        updateGameScoresFromModel()
        updateSetScoresFromModel()
        updateMatchScoresFromModel()
        if let winner = currentMatch.winner {
            switch winner {
            case .one:
                playerOneGameScoreButton.setTitle("🏆", for: .normal)
                playerTwoGameScoreButton.isHidden = true
            case .two:
                playerOneGameScoreButton.isHidden = true
                playerTwoGameScoreButton.setTitle("🏆", for: .normal)
            }
            playerOneServiceLabel.isHidden = true
            playerTwoServiceLabel.isHidden = true
            playerOneGameScoreButton.isEnabled = false
            playerTwoGameScoreButton.isEnabled = false
            endMatchButton.style = .done
        }
    }
    
    func updateLabelsForEndOfMatch() {
        endMatchButton.isEnabled = false
        changeMatchLengthSegmentedControl.isHidden = false
        setTypeSegmentedControl.isHidden = false
        playerOneServiceLabel.isHidden = true
        playerOneGameScoreButton.isHidden = true
        playerOneSetScoreLabel.isHidden = true
        playerOneMatchScoreLabel.isHidden = true
        playerTwoServiceLabel.isHidden = true
        playerTwoGameScoreButton.isHidden = true
        playerTwoSetScoreLabel.isHidden = true
        playerTwoMatchScoreLabel.isHidden = true
        title = "Chair Umpire"
    }
    
    func updateServingLabelsFromModel() {
        let newServer = currentGame.server
        switch newServer! {
        case .one:
            playerOneServiceLabel.isHidden = false
            playerTwoServiceLabel.isHidden = true
        case .two:
            playerOneServiceLabel.isHidden = true
            playerTwoServiceLabel.isHidden = false
        }
    }
    
    func updateNavigationBarGameScoreFromModel() {
        if serverScore == "Deuce" {
            title = "Deuce"
        } else if serverScore == "Ad in" || receiverScore == "Ad in" {
            title = "Advantage in"
        } else if serverScore == "Ad out" || receiverScore == "Ad out" {
            title = "Advantage out"
        } else {
            if currentMatch.winner == nil {
                title = "\(serverScore)-\(receiverScore)"
            } else {
                title = "Winner"
            }
        }
    }
    
    func updateGameScoresFromModel() {
        switch currentGame.isTiebreak {
        case true:
            playerOneGameScoreButton.setTitle(String(currentGame.playerOneScore), for: .normal)
            playerTwoGameScoreButton.setTitle(String(currentGame.playerTwoScore), for: .normal)
        default:
            updatePlayerOneGameScoreFromModel()
            updatePlayerTwoGameScoreFromModel()
        }
    }
    
    func updatePlayerOneGameScoreFromModel() {
        if playerTwoGameScore == "Ad in" || playerTwoGameScore == "Ad out" {
            playerOneGameScoreButton.setTitle("🎾", for: .normal)
        } else {
            playerOneGameScoreButton.setTitle(playerOneGameScore, for: .normal)
        }
    }
    
    func updatePlayerTwoGameScoreFromModel() {
        if playerOneGameScore == "Ad in" || playerOneGameScore == "Ad out" {
            playerTwoGameScoreButton.setTitle("🎾", for: .normal)
        } else {
            playerTwoGameScoreButton.setTitle(playerTwoGameScore, for: .normal)
        }
    }
    
    func updateSetScoresFromModel() {
        playerOneSetScoreLabel.text = "Set score: \(currentSet.playerOneScore)"
        playerTwoSetScoreLabel.text = "Set score: \(currentSet.playerTwoScore)"
    }
    
    func updateMatchScoresFromModel() {
        playerOneMatchScoreLabel.text = "Match score: \(currentMatch.playerOneScore)"
        playerTwoMatchScoreLabel.text = "Match score: \(currentMatch.playerTwoScore)"
    }
}
