//
//  ScoreboardInterfaceController.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 2/18/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class ScoreboardInterfaceController: WKInterfaceController, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    // MARK: Properties
    var session: WCSession!
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
    
    @IBOutlet var yourServingLabel: WKInterfaceLabel!
    @IBOutlet var opponentServingLabel: WKInterfaceLabel!
    
    @IBOutlet var yourSideTapGestureRecognizer: WKTapGestureRecognizer!
    @IBOutlet var opponentSideTapGestureRecognizer: WKTapGestureRecognizer!
    
    @IBOutlet var yourGameScoreLabel: WKInterfaceLabel!
    @IBOutlet var opponentGameScoreLabel: WKInterfaceLabel!
    
    @IBOutlet var columnOneYourSetScoreLabel: WKInterfaceLabel!
    @IBOutlet var columnOneOpponentSetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet var columnTwoYourSetScoreLabel: WKInterfaceLabel!
    @IBOutlet var columnTwoOpponentSetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet var columnThreeYourSetScoreLabel: WKInterfaceLabel!
    @IBOutlet var columnThreeOpponentSetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet var columnFourYourSetScoreLabel: WKInterfaceLabel!
    @IBOutlet var columnFourOpponentSetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet var columnFiveYourSetScoreLabel: WKInterfaceLabel!
    @IBOutlet var columnFiveOpponentSetScoreLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        let context = context as? MatchManager
        scoreManager = ScoreManager(context!)
        updateLabelsFromModel()

        if (WCSession.isSupported()) {
            session = WCSession.default()
            session.delegate = self
            session.activate()
            session.sendMessage(["start new match" : "reset"], replyHandler: nil)
        }
        
        WKExtension.shared().isFrontmostTimeoutExtended = true
    }
    
    @IBAction func scorePointForOpponent(_ sender: Any) {
        currentMatch.scorePointForOpponentInCurrentGame()
        playHaptic()
        updateLabelsFromModel()
    }
    
    @IBAction func scorePointForYou(_ sender: Any) {
        currentMatch.scorePointForYouInCurrentGame()
        playHaptic()
        updateLabelsFromModel()
    }
    
    func updateLabelsFromModel() {
        updateServingLabelsFromModel()
        updateGameScoresFromModel()
        updateSetScoresFromModel()
        if let winner = currentMatch.winner {
            switch winner {
            case .you:
                yourGameScoreLabel.setText("🏆")
                opponentGameScoreLabel.setHidden(true)
            case .opponent:
                opponentGameScoreLabel.setText("🏆")
                yourGameScoreLabel.setHidden(true)
            }
            yourServingLabel.setHidden(true)
            opponentServingLabel.setHidden(true)
            yourSideTapGestureRecognizer.isEnabled = false
            opponentSideTapGestureRecognizer.isEnabled = false
            self.setTitle("Done")
            updateSetLabelsToBeWhite()
        }
    }
    
    func updateServingLabelsFromModel() {
        switch (currentGame.server, currentGame.servingSide) {
        case (.you?, .right?):
            yourServingLabel.setHorizontalAlignment(.right)
            yourServingLabel.setHidden(false)
            opponentServingLabel.setHidden(true)
        case (.you?, .left?):
            yourServingLabel.setHorizontalAlignment(.left)
            yourServingLabel.setHidden(false)
            opponentServingLabel.setHidden(true)
        case (.opponent?, .left?):
            opponentServingLabel.setHorizontalAlignment(.left)
            opponentServingLabel.setHidden(false)
            yourServingLabel.setHidden(true)
        case (.opponent?, .right?):
            opponentServingLabel.setHorizontalAlignment(.right)
            opponentServingLabel.setHidden(false)
            yourServingLabel.setHidden(true)
        default:
            break
        }
    }
    
    func updateGameScoresFromModel() {
        switch currentGame.isTiebreaker {
        case true:
            yourGameScoreLabel.setText(String(currentGame.yourGameScore))
            opponentGameScoreLabel.setText(String(currentGame.opponentGameScore))
        default:
            updateYourCurrentGameScoreFromModel()
            updateOpponentCurrentGameScoreFromModel()
        }
    }
    
    func updateYourCurrentGameScoreFromModel() {
        switch currentGame.yourGameScore {
        case 0:
            yourGameScoreLabel.setText("Love")
        case 15, 30:
            yourGameScoreLabel.setText(String(currentGame.yourGameScore))
        case 40:
            if currentGame.opponentGameScore < 40 {
                yourGameScoreLabel.setText(String(currentGame.yourGameScore))
            } else if currentGame.opponentGameScore == 40 {
                yourGameScoreLabel.setText("Deuce")
            }
        default: // Alternating advantage and deuce situations.
            if currentGame.yourGameScore == currentGame.opponentGameScore + 1 {
                if currentGame.server == .you {
                    yourGameScoreLabel.setText("Ad in")
                    opponentGameScoreLabel.setText("")
                } else if currentGame.server == .opponent {
                    yourGameScoreLabel.setText("Ad out")
                    opponentGameScoreLabel.setText("")
                }
            } else if currentGame.yourGameScore == currentGame.opponentGameScore {
                yourGameScoreLabel.setText("Deuce")
            }
        }
    }
    
    func updateOpponentCurrentGameScoreFromModel() {
        switch currentGame.opponentGameScore {
        case 0:
            opponentGameScoreLabel.setText("Love")
        case 15, 30:
            opponentGameScoreLabel.setText(String(currentGame.opponentGameScore))
        case 40:
            if currentGame.yourGameScore < 40 {
                opponentGameScoreLabel.setText(String(currentGame.opponentGameScore))
            } else if currentGame.yourGameScore == 40 {
                opponentGameScoreLabel.setText("Deuce")
            }
        default: // Alternating advantage and deuce situations.
            if currentGame.opponentGameScore == currentGame.yourGameScore + 1 {
                if currentGame.server == .opponent {
                    opponentGameScoreLabel.setText("Ad in")
                    yourGameScoreLabel.setText("")
                } else if currentGame.server == .you {
                    opponentGameScoreLabel.setText("Ad out")
                    yourGameScoreLabel.setText("")
                }
            } else if currentGame.opponentGameScore == currentGame.yourGameScore {
                opponentGameScoreLabel.setText("Deuce")
            }
        }
    }
    
    func updateSetScoresFromModel() {
        switch (currentGame.gameScore, scoreManager?.currentMatch.sets.count) {
        // Cases with current game scores of (0, 0) are new games.
        // Second part of the tuple is the set you are now entering.
        // Cases with current sets scores of (0, 0) are new sets.
        case ((0, 0), 1):
            updateCurrentSetScoreColumn()
        case ((0, 0), 2):
            updateSetScoresForEnteringSecondSet()
        case ((0, 0), 3):
            updateSetScoresForEnteringThirdSet()
        case ((0, 0), 4):
            updateSetScoresForEnteringFourthSet()
        case ((0, 0), 5):
            updateSetScoresForEnteringFifthSet()
        default:
            break
        }
        updateCurrentSetScoreColumn()
    }
    
    func updateCurrentSetScoreColumn() {
        columnFiveYourSetScoreLabel.setText(String(currentSet.yourSetScore))
        columnFiveOpponentSetScoreLabel.setText(String(currentSet.opponentSetScore))
    }
    
    func updateSetScoresForEnteringSecondSet() {
        columnFourYourSetScoreLabel.setText(String(currentMatch.sets[0].yourSetScore))
        columnFourOpponentSetScoreLabel.setText(String(currentMatch.sets[0].opponentSetScore))
        columnFourYourSetScoreLabel.setHidden(false)
        columnFourOpponentSetScoreLabel.setHidden(false)
    }
    
    func updateSetScoresForEnteringThirdSet() {
        columnThreeYourSetScoreLabel.setText(String(currentMatch.sets[0].yourSetScore))
        columnThreeOpponentSetScoreLabel.setText(String(currentMatch.sets[0].opponentSetScore))
        columnFourYourSetScoreLabel.setText(String(currentMatch.sets[1].yourSetScore))
        columnFourOpponentSetScoreLabel.setText(String(currentMatch.sets[1].opponentSetScore))
        columnThreeYourSetScoreLabel.setHidden(false)
        columnThreeOpponentSetScoreLabel.setHidden(false)
    }
    
    func updateSetScoresForEnteringFourthSet() {
        columnTwoYourSetScoreLabel.setText(String(currentMatch.sets[0].yourSetScore))
        columnTwoOpponentSetScoreLabel.setText(String(currentMatch.sets[0].opponentSetScore))
        columnThreeYourSetScoreLabel.setText(String(currentMatch.sets[1].yourSetScore))
        columnThreeOpponentSetScoreLabel.setText(String(currentMatch.sets[1].opponentSetScore))
        columnFourYourSetScoreLabel.setText(String(currentMatch.sets[2].yourSetScore))
        columnFourOpponentSetScoreLabel.setText(String(currentMatch.sets[2].opponentSetScore))
        columnTwoYourSetScoreLabel.setHidden(false)
        columnTwoOpponentSetScoreLabel.setHidden(false)
    }
    
    func updateSetScoresForEnteringFifthSet() {
        columnOneYourSetScoreLabel.setText(String(currentMatch.sets[0].yourSetScore))
        columnOneOpponentSetScoreLabel.setText(String(currentMatch.sets[0].opponentSetScore))
        columnTwoYourSetScoreLabel.setText(String(currentMatch.sets[1].yourSetScore))
        columnTwoOpponentSetScoreLabel.setText(String(currentMatch.sets[1].opponentSetScore))
        columnThreeYourSetScoreLabel.setText(String(currentMatch.sets[2].yourSetScore))
        columnThreeOpponentSetScoreLabel.setText(String(currentMatch.sets[2].opponentSetScore))
        columnFourYourSetScoreLabel.setText(String(currentMatch.sets[3].yourSetScore))
        columnFourOpponentSetScoreLabel.setText(String(currentMatch.sets[3].opponentSetScore))
        columnOneYourSetScoreLabel.setHidden(false)
        columnOneOpponentSetScoreLabel.setHidden(false)
    }
    
    func updateSetLabelsToBeWhite() {
        columnOneYourSetScoreLabel.setTextColor(.white)
        columnOneOpponentSetScoreLabel.setTextColor(.white)
        columnTwoYourSetScoreLabel.setTextColor(.white)
        columnTwoOpponentSetScoreLabel.setTextColor(.white)
        columnThreeYourSetScoreLabel.setTextColor(.white)
        columnThreeOpponentSetScoreLabel.setTextColor(.white)
        columnFourYourSetScoreLabel.setTextColor(.white)
        columnFourOpponentSetScoreLabel.setTextColor(.white)
    }
    
    func playHaptic() {
        switch currentMatch.matchEnded {
        case true:
            if currentMatch.winner == .you {
                WKInterfaceDevice.current().play(.success)
            } else if currentMatch.winner == .opponent {
                WKInterfaceDevice.current().play(.failure)
            }
        case false:
            if currentGame.gameScore != (0, 0) {
                // The point has concluded but not a game.
                switch currentGame.isTiebreaker {
                case true:
                    if (currentGame.yourGameScore + currentGame.opponentGameScore) % 2 == 1 {
                        WKInterfaceDevice.current().play(.start)
                    } else {
                        WKInterfaceDevice.current().play(.click)
                    }
                case false:
                    WKInterfaceDevice.current().play(.click)
                }
            } else if (currentSet.games.count % 2 == 0) {
                // The server is changing but you're not switching sides yet.
                WKInterfaceDevice.current().play(.start)
            } else if (currentSet.games.count % 2 == 1) {
                // The server is changing and you're switching sides.
                WKInterfaceDevice.current().play(.stop)
            }
        }
    }
}
