//
//  ScoreboardInterfaceController.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 11/19/17.
//  Copyright © 2017 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class ScoreboardInterfaceController: WKInterfaceController, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    // MARK: Properties
    var session: WCSession!
    
    // Opponent of person wearing Apple Watch
    @IBOutlet var playerOneServingStatusLabel: WKInterfaceLabel!
    @IBOutlet var playerOneTapGestureRecognizer: WKTapGestureRecognizer!
    @IBOutlet var playerOneGameScoreLabel: WKInterfaceLabel!
    @IBOutlet var playerOneSetScoreLabel: WKInterfaceLabel!
    @IBOutlet var playerOneMatchScoreLabel: WKInterfaceLabel!
    
    // Person wearing Apple Watch
    @IBOutlet var playerTwoServingStatusLabel: WKInterfaceLabel!
    @IBOutlet var playerTwoTapGestureRecognizer: WKTapGestureRecognizer!
    @IBOutlet var playerTwoGameScoreLabel: WKInterfaceLabel!
    @IBOutlet var playerTwoSetScoreLabel: WKInterfaceLabel!
    @IBOutlet var playerTwoMatchScoreLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        ScoreManager.determineWhoServes()
        updateServingLabels()
        
        if (WCSession.isSupported()) {
            session = WCSession.default()
            session.delegate = self
            session.activate()
            sendServingStatusToPhone()
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        ScoreManager.reset()
        session.sendMessage(["start new match" : "reset"], replyHandler: nil)
    }
    
    func updateServingLabels() {
        switch ScoreManager.server {
        case .first?:
            playerOneServingStatusLabel?.setHidden(false)
            playerTwoServingStatusLabel?.setHidden(true)
            switch playerOne.servingSide {
            case .left:
                playerOneServingStatusLabel.setHorizontalAlignment(.left)
            case .right:
                playerOneServingStatusLabel.setHorizontalAlignment(.right)
            }
        case .second?:
            playerOneServingStatusLabel?.setHidden(true)
            playerTwoServingStatusLabel?.setHidden(false)
            switch playerTwo.servingSide {
            case .left:
                playerTwoServingStatusLabel.setHorizontalAlignment(.left)
            case .right:
                playerTwoServingStatusLabel.setHorizontalAlignment(.right)
            }
        default:
            break
        }
    }
    
    func hideServingLabels() {
        playerOneServingStatusLabel?.setHidden(true)
        playerTwoServingStatusLabel?.setHidden(true)
    }
    
    func sendServingStatusToPhone() {
        switch ScoreManager.server {
        case .first?:
            session.sendMessage(["server" : "first player"], replyHandler: nil)
        case .second?:
            session.sendMessage(["server" : "second player"], replyHandler: nil)
        default:
            break
        }
    }
    
    @IBAction func firstPlayerScored(_ sender: Any) {
        playerOne.scorePoint()
        print("Player one serving side is \(playerOne.servingSide))")
        print("Player two serving side is \(playerTwo.servingSide))")
        playHaptic()
        session.sendMessage(["scored" : "first player"], replyHandler: nil)
        updateFirstPlayerGameScoreLabel()
        updateSetScoreLabels()
        updateMatchScoreLabels()
        updateServingLabels()
    }
    
    @IBAction func secondPlayerScored(_ sender: Any) {
        playerTwo.scorePoint()
        print("Player one serving side is \(playerOne.servingSide)")
        print("Player two serving side is \(playerTwo.servingSide)")
        playHaptic()
        session.sendMessage(["scored" : "second player"], replyHandler: nil)
        updateSecondPlayerGameScoreLabel()
        updateSetScoreLabels()
        updateMatchScoreLabels()
        updateServingLabels()
    }
    
    func playHaptic() {
        switch (playerOne.gameScore, playerTwo.gameScore) {
        case (0, 0):
            switch ScoreManager.winner {
            case let winner? where ScoreManager.winner != nil:
                switch winner {
                case .first:
                    WKInterfaceDevice.current().play(.failure)
                case .second:
                    WKInterfaceDevice.current().play(.success)
                }
            default:
                WKInterfaceDevice.current().play(.stop)
            }
        default:
            WKInterfaceDevice.current().play(.click)
        }
    }
    
    func updateFirstPlayerGameScoreLabel() {
        switch (playerOne.gameScore, ScoreManager.isDeuce) {
        case (0, false): // New game
            updateServingLabels()
            resetGameScoreLabels()
        case (15...30, false):
            playerOneGameScoreLabel.setText(String(playerOne.gameScore))
        case (40, true):
            updateGameScoreLabelsForDeuce()
        case (40, false):
            switch ScoreManager.advantage {
            case .first?:
                switch ScoreManager.server {
                case .first?:
                    playerOneGameScoreLabel.setText("Ad in")
                case .second?:
                    playerOneGameScoreLabel.setText("Ad out")
                default:
                    break
                }
                playerTwoGameScoreLabel.setText("🎾")
            default:
                playerOneGameScoreLabel.setText(String(playerOne.gameScore))
            }
        default:
            break
        }
    }
    
    func updateSecondPlayerGameScoreLabel() {
        switch (playerTwo.gameScore, ScoreManager.isDeuce) {
        case (0, false): // New game
            updateServingLabels()
            resetGameScoreLabels()
        case (15...30, false):
            playerTwoGameScoreLabel.setText(String(playerTwo.gameScore))
        case (40, true):
            updateGameScoreLabelsForDeuce()
        case (40, false):
            switch ScoreManager.advantage {
            case .second?:
                switch ScoreManager.server {
                case .first?:
                    playerTwoGameScoreLabel.setText("Ad out")
                case .second?:
                    playerTwoGameScoreLabel.setText("Ad in")
                default:
                    break
                }
                playerOneGameScoreLabel.setText("🎾")
            default:
                playerTwoGameScoreLabel.setText(String(playerTwo.gameScore))
            }
        default:
            break
        }
    }
    
    func updateGameScoreLabelsForDeuce() {
        playerOneGameScoreLabel.setText("Deuce")
        playerTwoGameScoreLabel.setText("Deuce")
    }
    
    func resetGameScoreLabels() {
        playerOneGameScoreLabel.setHidden(false)
        playerTwoGameScoreLabel.setHidden(false)
        playerOneGameScoreLabel.setText("Love")
        playerTwoGameScoreLabel.setText("Love")
    }
    
    func updateSetScoreLabels() {
        switch ScoreManager.isInTiebreakGame {
        case true:
            playerOneSetScoreLabel.setText("Tiebreak")
            playerTwoSetScoreLabel.setText("Tiebreak")
        default:
            playerOneSetScoreLabel.setText(String(playerOne.setScore))
            playerTwoSetScoreLabel.setText(String(playerTwo.setScore))
        }
    }
    
    func updateMatchScoreLabels() {
        playerOneMatchScoreLabel.setText(String(playerOne.matchScore))
        playerTwoMatchScoreLabel.setText(String(playerTwo.matchScore))
        if let _ = ScoreManager.winner {
            updateLabelsForEndOfMatch()
        }
    }
    
    func updateLabelsForEndOfMatch() {
        switch ScoreManager.winner {
        case .first?:
            playerOneGameScoreLabel.setText("🏆")
            playerTwoGameScoreLabel.setHidden(true)
        case .second?:
            playerOneGameScoreLabel.setHidden(true)
            playerTwoGameScoreLabel.setText("🏆")
        default:
            break
        }
        playerOneTapGestureRecognizer.isEnabled = false
        playerTwoTapGestureRecognizer.isEnabled = false
        hideServingLabels()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.sync {
            switch message {
            case _ where message["server"] != nil:
                switch message["server"] as! String {
                case "first player":
                    ScoreManager.server = .first
                case "second player":
                    ScoreManager.server = .second
                default:
                    break
                }
                updateServingLabels()
            case _ where message["scored"] != nil:
                switch message["scored"] as! String {
                case "first player":
                    playerOne.scorePoint()
                    updateFirstPlayerGameScoreLabel()
                case "second player":
                    playerTwo.scorePoint()
                    updateSecondPlayerGameScoreLabel()
                default:
                    break
                }
                playHaptic()
                updateServingLabels()
                updateSetScoreLabels()
                updateMatchScoreLabels()
                if let _ = ScoreManager.winner {
                    updateLabelsForEndOfMatch()
                }
            default:
                break
            }
        }
    }
}
