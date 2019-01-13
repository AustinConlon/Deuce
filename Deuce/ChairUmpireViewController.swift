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
    var score: Score?
    var currentGame: GameManager {
        get {
            return currentSet.currentGame
        }
    }
    var currentSet: SetManager {
        get {
            return score!.currentMatch.currentSet
        }
    }
    var currentMatch: MatchManager {
        get {
            return score!.currentMatch
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
                return String(currentGame.player1Score)
            default:
                switch currentGame.player1Score {
                case 0:
                    return NSLocalizedString("Love", tableName: "Main", comment: "Game score of 0")
                case 15, 30:
                    return String(currentGame.player1Score)
                case 40:
                    if currentGame.player2Score < 40 {
                        return String(currentGame.player1Score)
                    } else if currentGame.player2Score == 40 {
                        return NSLocalizedString("Deuce", tableName: "Main", comment: "Game score is 40-40")
                    }
                default: // Alternating advantage and deuce situations.
                    if currentGame.player1Score == currentGame.player2Score + 1 {
                        if currentGame.server == .one {
                            return NSLocalizedString("Ad in", tableName: "Main", comment: "After a deuce situation, the service player is now winning by one point")
                        } else if currentGame.server == .two {
                            return NSLocalizedString("Ad out", tableName: "Main", comment: "After a deuce situation, the receiving player is now winning by one point")
                        }
                    } else if currentGame.player1Score == currentGame.player2Score {
                        return NSLocalizedString("Deuce", tableName: "Main", comment: "Game score is 40-40")
                    }
                }
            }
            return ""
        }
    }
    
    var playerTwoGameScore: String {
        switch currentGame.isTiebreak {
        case true:
            return String(currentGame.player2Score)
        default:
            switch currentGame.player2Score {
            case 0:
                return NSLocalizedString("Love", tableName: "Main", comment: "Game score of 0")
            case 15, 30:
                return String(currentGame.player2Score)
            case 40:
                if currentGame.player1Score < 40 {
                    return String(currentGame.player2Score)
                } else if currentGame.player1Score == 40 {
                    return NSLocalizedString("Deuce", tableName: "Main", comment: "Game score is 40-40")
                }
            default: // Alternating advantage and deuce situations.
                if currentGame.player2Score == currentGame.player1Score + 1 {
                    if currentGame.server == .two {
                        return NSLocalizedString("Ad in", tableName: "Main", comment: "After a deuce situation, the service player is now winning by one point")
                    } else if currentGame.server == .one {
                        return NSLocalizedString("Ad out", tableName: "Main", comment: "After a deuce situation, the receiving player is now winning by one point")
                    }
                } else if currentGame.player2Score == currentGame.player1Score {
                    return NSLocalizedString("Deuce", tableName: "Main", comment: "Game score is 40-40")
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
    @IBOutlet weak var player1GameScoreButton: UIButton!
    @IBOutlet weak var playerOneSetScoreLabel: UILabel!
    @IBOutlet weak var playerOneMatchScoreLabel: UILabel!
    
    @IBOutlet weak var playerTwoServiceLabel: UILabel!
    @IBOutlet weak var player2GameScoreButton: UIButton!
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
        switch currentMatch.matchState {
        case .finished:
            updateLabelsForEndOfMatch()
            self.navigationController?.popToRootViewController(animated: true)
        default:
            let alert = UIAlertController(title: "End Match?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel action"), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .destructive, handler: { _ in
                self.updateLabelsForEndOfMatch()
                self.navigationController?.popToRootViewController(animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func scorePointForPlayerOne(_ sender: Any) {
        currentMatch.scorePoint(for: Player.one)
        updateLabelsFromModel()
    }
    
    @IBAction func scorePointForPlayerTwo(_ sender: Any) {
        currentMatch.scorePoint(for: Player.two)
        updateLabelsFromModel()
    }
    
    func coinToss() {
        let coinTossResult: String
        let flippedHeads = Bool.random()
        
        if flippedHeads {
            coinTossResult = NSLocalizedString("The player starting on your left side won the coin toss. Select their choice of who will serve first.", tableName: "Main", comment: "Player to the left of the chair umpire won the coin toss.")
        } else {
            coinTossResult = NSLocalizedString("The player starting on your right side won the coin toss. Select their choice of who will serve first.", tableName: "Main", comment: "Player to the right of the chair umpire won the coin toss.")
        }
        
        let alert = UIAlertController(title: NSLocalizedString("Coin Toss", tableName: "Main", comment: "Coin is flipped to determine which player chooses who begins service."), message: coinTossResult, preferredStyle: .alert)
        
        let localizedLeftPlayerTitle = NSLocalizedString("Left Player", tableName: "Main", comment: "Player to the left of the chair umpire begins service.")
        alert.addAction(UIAlertAction(title: localizedLeftPlayerTitle, style: .default, handler: { _ in
            self.playerThatWillServeFirst = .one
            self.startScoring()
        }))
        
        let localizedRightPlayerTitle = NSLocalizedString("Right Player", tableName: "Main", comment: "Player to the right of the chair umpire begins service.")
        alert.addAction(UIAlertAction(title: localizedRightPlayerTitle, style: .default, handler: { _ in
            self.playerThatWillServeFirst = .two
            self.startScoring()
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func startScoring() {
        let match = MatchManager(self.maximumNumberOfSetsInMatch, self.typeOfSet, self.playerThatWillServeFirst!)
        self.score = Score(match)
        updateLabelsFromModel()
        changeMatchLengthSegmentedControl.isHidden = true
        setTypeSegmentedControl.isHidden = true
        startMatchButton.isEnabled = false
        endMatchButton.isEnabled = true
        player1GameScoreButton.isEnabled = true
        player1GameScoreButton.isHidden = false
        playerOneSetScoreLabel.isHidden = false
        playerOneMatchScoreLabel.isHidden = false
        player2GameScoreButton.isEnabled = true
        player2GameScoreButton.isHidden = false
        playerTwoSetScoreLabel.isHidden = false
        playerTwoMatchScoreLabel.isHidden = false
        let server = (score?.currentMatch.currentSet.currentGame.server)!
        switch server {
        case .one:
            playerOneServiceLabel.isHidden = false
        case .two:
            playerTwoServiceLabel.isHidden = false
        }
    }
    
    func updateLabelsFromModel() {
        updateServingLabelsFromModel()
        updateGameScoresFromModel()
        updateSetScoresFromModel()
        updateMatchScoresFromModel()
        if let winner = currentMatch.winner {
            switch winner {
            case .one:
                player1GameScoreButton.setTitle("🏆", for: .normal)
                player2GameScoreButton.isHidden = true
            case .two:
                player1GameScoreButton.isHidden = true
                player2GameScoreButton.setTitle("🏆", for: .normal)
            }
            playerOneServiceLabel.isHidden = true
            playerTwoServiceLabel.isHidden = true
            player1GameScoreButton.isEnabled = false
            player2GameScoreButton.isEnabled = false
            endMatchButton.style = .done
        }
    }
    
    func updateLabelsForEndOfMatch() {
        endMatchButton.isEnabled = false
        changeMatchLengthSegmentedControl.isHidden = false
        setTypeSegmentedControl.isHidden = false
        playerOneServiceLabel.isHidden = true
        player1GameScoreButton.isHidden = true
        playerOneSetScoreLabel.isHidden = true
        playerOneMatchScoreLabel.isHidden = true
        playerTwoServiceLabel.isHidden = true
        player2GameScoreButton.isHidden = true
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
    
    func updateGameScoresFromModel() {
        switch currentGame.isTiebreak {
        case true:
            player1GameScoreButton.setTitle(String(currentGame.player1Score), for: .normal)
            player2GameScoreButton.setTitle(String(currentGame.player2Score), for: .normal)
        default:
            updatePlayerOneGameScoreFromModel()
            updatePlayerTwoGameScoreFromModel()
        }
    }
    
    func updatePlayerOneGameScoreFromModel() {
        if playerTwoGameScore == "Ad in" || playerTwoGameScore == "Ad out" {
            player1GameScoreButton.setTitle("🎾", for: .normal)
        } else {
            player1GameScoreButton.setTitle(playerOneGameScore, for: .normal)
        }
    }
    
    func updatePlayerTwoGameScoreFromModel() {
        if playerOneGameScore == "Ad in" || playerOneGameScore == "Ad out" {
            player2GameScoreButton.setTitle("🎾", for: .normal)
        } else {
            player2GameScoreButton.setTitle(playerTwoGameScore, for: .normal)
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
