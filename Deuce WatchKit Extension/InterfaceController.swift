//
//  InterfaceController.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 11/27/16.
//  Copyright © 2017 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(watchOS 2.2, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }

    // MARK: Properties
    var session: WCSession!
    
    @IBOutlet var matchLengthLabel: WKInterfaceLabel!
    @IBOutlet var matchLengthSlider: WKInterfaceSlider!
    @IBOutlet var setTypeSwitch: WKInterfaceSwitch!
    
    @IBOutlet var playerOneServingLabel: WKInterfaceLabel!
    @IBOutlet var playerOneSetScoreLabel: WKInterfaceLabel!
    @IBOutlet var playerOneGameScoreLabel: WKInterfaceLabel!
    @IBOutlet var playerOneMatchScoreLabel: WKInterfaceLabel!
    
    @IBOutlet var playerTwoServingLabel: WKInterfaceLabel!
    @IBOutlet var playerTwoSetScoreLabel: WKInterfaceLabel!
    @IBOutlet var playerTwoGameScoreLabel: WKInterfaceLabel!
    @IBOutlet var playerTwoMatchScoreLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        ScoreManager.determineWhoServes()
        updateServingLabels()
        
        if (WCSession.isSupported()) {
            session = WCSession.default()
            session.delegate = self
            session.activate()
            switch ScoreManager.server {
            case .first?:
                session.sendMessage(["server" : "first player"], replyHandler: nil)
            case .second?:
                session.sendMessage(["server" : "second player"], replyHandler: nil)
            default:
                break
            }
        }
        
        // If the user presses the back button and then Start to restart the match
        ScoreManager.reset()
        session.sendMessage(["new match" : "reset"], replyHandler: nil)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    @IBAction func matchLengthSlider(_ value: Float) {
        ScoreManager.matchLength = Int(value)
        let matchLengthText: String
        switch value {
        case 3:
            matchLengthText = "Best-of three sets"
        case 5:
            matchLengthText = "Best-of five sets"
        case 7:
            matchLengthText = "Best-of seven sets"
        default:
            matchLengthText = "One set"
        }
        matchLengthLabel.setText(matchLengthText)
        session.sendMessage(["match length" : ScoreManager.matchLength], replyHandler: nil)
        session.sendMessage(["match length text" : matchLengthText], replyHandler: nil)
    }
    
    @IBAction func changeSetType(_ value: Bool) {
        switch value {
        case false:
            ScoreManager.setType = .tiebreak
            setTypeSwitch.setTitle("Tiebreaker set")
            session.sendMessage(["set type" : "Tiebreaker set"], replyHandler: nil)
        case true:
            ScoreManager.setType = .advantage
            setTypeSwitch.setTitle("Advantage set")
            session.sendMessage(["set type" : "Advantage set"], replyHandler: nil)
        }
    }
    
    @IBAction func incrementFirstPlayerScore(_ sender: Any) {
        WKInterfaceDevice.current().play(.click)
        playerOne.scorePoint()
        updateFirstPlayerGameScoreLabel()
        updateSetScoreLabels()
        updateMatchScoreLabels()
        session.sendMessage(["scored" : "first player"], replyHandler: nil)
    }
    
    @IBAction func incrementSecondPlayerScore(_ sender: Any) {
        WKInterfaceDevice.current().play(.click)
        playerTwo.scorePoint()
        updateSecondPlayerGameScoreLabel()
        updateSetScoreLabels()
        updateMatchScoreLabels()
        session.sendMessage(["scored" : "second player"], replyHandler: nil)
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
                    playerOneGameScoreLabel.setText("Advantage in")
                case .second?:
                    playerOneGameScoreLabel.setText("Advantage out")
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
                    playerTwoGameScoreLabel.setText("Advantage out")
                case .second?:
                    playerTwoGameScoreLabel.setText("Advantage in")
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
    
    func resetGameScoreLabels() {
        playerOneGameScoreLabel.setHidden(false)
        playerTwoGameScoreLabel.setHidden(false)
        playerOneGameScoreLabel.setText("Love")
        playerTwoGameScoreLabel.setText("Love")
    }
    
    func updateGameScoreLabelsForDeuce() {
        playerOneGameScoreLabel.setText("Deuce")
        playerTwoGameScoreLabel.setText("Deuce")
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
        hideServingLabels()
    }
    
    func updateServingLabels() {
        switch ScoreManager.server {
        case .first?:
            playerOneServingLabel?.setHidden(false)
            playerTwoServingLabel?.setHidden(true)
        case .second?:
            playerOneServingLabel?.setHidden(true)
            playerTwoServingLabel?.setHidden(false)
        default:
            break
        }
    }
    
    func hideServingLabels() {
        playerOneServingLabel?.setHidden(true)
        playerTwoServingLabel?.setHidden(true)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.sync {
            switch message {
            case _ where message["match length"] != nil:
                ScoreManager.matchLength = message["match length"] as! Int
                matchLengthSlider.setValue(message["match length"] as! Float)
            case _ where message["match length text"] != nil:
                matchLengthLabel.setText(message["match length text"] as? String)
            case _ where message["set type"] != nil:
                switch message["set type"] as! String {
                case "Tiebreaker set":
                    ScoreManager.setType = .tiebreak
                    setTypeSwitch.setOn(false)
                case "Advantage set":
                    ScoreManager.setType = .advantage
                    setTypeSwitch.setOn(true)
                default:
                    break
                }
                setTypeSwitch.setTitle(message["set type"] as? String)
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
                WKInterfaceDevice.current().play(.click)
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
                updateServingLabels()
                updateSetScoreLabels()
                updateMatchScoreLabels()
                if let _ = ScoreManager.winner {
                    updateLabelsForEndOfMatch()
                }
            case _ where message["start new match"] != nil:
                ScoreManager.reset()
                ScoreManager.determineWhoServes()
                updateServingLabels()
                switch ScoreManager.server {
                case .first?:
                    session.sendMessage(["server" : "first player"], replyHandler: nil)
                case .second?:
                    session.sendMessage(["server" : "second player"], replyHandler: nil)
                default:
                    break
                }
                resetGameScoreLabels()
                updateSetScoreLabels()
                updateMatchScoreLabels()
            default:
                break
            }
        }
    }
    
    override init() {
        // Initialize properties here.
        super.init()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}
