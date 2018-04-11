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
        }
        
        WKExtension.shared().isFrontmostTimeoutExtended = true
    }
    
    override func willDisappear() {
        session.sendMessage(["end match" : "reset"], replyHandler: nil, errorHandler: { Error in
            print(Error)
        })
    }
    
    @IBAction func scorePointForPlayerTwo(_ sender: Any) {
        session.sendMessage(["score point" : "player two"], replyHandler: nil)
        currentMatch.scorePointForPlayerTwoInCurrentGame()
        playHaptic()
        updateLabelsFromModel()
    }
    
    @IBAction func scorePointForPlayerOne(_ sender: Any) {
        session.sendMessage(["score point" : "player one"], replyHandler: nil)
        currentMatch.scorePointForPlayerOneInCurrentGame()
        playHaptic()
        updateLabelsFromModel()
    }
    
    func updateLabelsFromModel() {
        updateServingLabelsFromModel()
        updateGameScoresFromModel()
        updateSetScoresFromModel()
        if let winner = currentMatch.winner {
            switch winner {
            case .one:
                yourGameScoreLabel.setText("🏆")
                opponentGameScoreLabel.setHidden(true)
            case .two:
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
        case (.one?, .right?):
            yourServingLabel.setHorizontalAlignment(.right)
            yourServingLabel.setHidden(false)
            opponentServingLabel.setHidden(true)
        case (.one?, .left?):
            yourServingLabel.setHorizontalAlignment(.left)
            yourServingLabel.setHidden(false)
            opponentServingLabel.setHidden(true)
        case (.two?, .left?):
            opponentServingLabel.setHorizontalAlignment(.left)
            opponentServingLabel.setHidden(false)
            yourServingLabel.setHidden(true)
        case (.two?, .right?):
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
            yourGameScoreLabel.setText(String(currentGame.playerOneGameScore))
            opponentGameScoreLabel.setText(String(currentGame.playerTwoGameScore))
        default:
            updateYourCurrentGameScoreFromModel()
            updateOpponentCurrentGameScoreFromModel()
        }
    }
    
    func updateYourCurrentGameScoreFromModel() {
        switch currentGame.playerOneGameScore {
        case 0:
            yourGameScoreLabel.setText("Love")
        case 15, 30:
            yourGameScoreLabel.setText(String(currentGame.playerOneGameScore))
        case 40:
            if currentGame.playerTwoGameScore < 40 {
                yourGameScoreLabel.setText(String(currentGame.playerOneGameScore))
            } else if currentGame.playerTwoGameScore == 40 {
                yourGameScoreLabel.setText("Deuce")
            }
        default: // Alternating advantage and deuce situations.
            if currentGame.playerOneGameScore == currentGame.playerTwoGameScore + 1 {
                if currentGame.server == .one {
                    yourGameScoreLabel.setText("Ad in")
                    opponentGameScoreLabel.setText("")
                } else if currentGame.server == .two {
                    yourGameScoreLabel.setText("Ad out")
                    opponentGameScoreLabel.setText("")
                }
            } else if currentGame.playerOneGameScore == currentGame.playerTwoGameScore {
                yourGameScoreLabel.setText("Deuce")
            }
        }
    }
    
    func updateOpponentCurrentGameScoreFromModel() {
        switch currentGame.playerTwoGameScore {
        case 0:
            opponentGameScoreLabel.setText("Love")
        case 15, 30:
            opponentGameScoreLabel.setText(String(currentGame.playerTwoGameScore))
        case 40:
            if currentGame.playerOneGameScore < 40 {
                opponentGameScoreLabel.setText(String(currentGame.playerTwoGameScore))
            } else if currentGame.playerOneGameScore == 40 {
                opponentGameScoreLabel.setText("Deuce")
            }
        default: // Alternating advantage and deuce situations.
            if currentGame.playerTwoGameScore == currentGame.playerOneGameScore + 1 {
                if currentGame.server == .two {
                    opponentGameScoreLabel.setText("Ad in")
                    yourGameScoreLabel.setText("")
                } else if currentGame.server == .one {
                    opponentGameScoreLabel.setText("Ad out")
                    yourGameScoreLabel.setText("")
                }
            } else if currentGame.playerTwoGameScore == currentGame.playerOneGameScore {
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
        columnFiveYourSetScoreLabel.setText(String(currentSet.playerOneSetScore))
        columnFiveOpponentSetScoreLabel.setText(String(currentSet.playerTwoSetScore))
    }
    
    func updateSetScoresForEnteringSecondSet() {
        columnFourYourSetScoreLabel.setText(String(currentMatch.sets[0].playerOneSetScore))
        columnFourOpponentSetScoreLabel.setText(String(currentMatch.sets[0].playerTwoSetScore))
        columnFourYourSetScoreLabel.setHidden(false)
        columnFourOpponentSetScoreLabel.setHidden(false)
    }
    
    func updateSetScoresForEnteringThirdSet() {
        columnThreeYourSetScoreLabel.setText(String(currentMatch.sets[0].playerOneSetScore))
        columnThreeOpponentSetScoreLabel.setText(String(currentMatch.sets[0].playerTwoSetScore))
        columnFourYourSetScoreLabel.setText(String(currentMatch.sets[1].playerOneSetScore))
        columnFourOpponentSetScoreLabel.setText(String(currentMatch.sets[1].playerTwoSetScore))
        columnThreeYourSetScoreLabel.setHidden(false)
        columnThreeOpponentSetScoreLabel.setHidden(false)
    }
    
    func updateSetScoresForEnteringFourthSet() {
        columnTwoYourSetScoreLabel.setText(String(currentMatch.sets[0].playerOneSetScore))
        columnTwoOpponentSetScoreLabel.setText(String(currentMatch.sets[0].playerTwoSetScore))
        columnThreeYourSetScoreLabel.setText(String(currentMatch.sets[1].playerOneSetScore))
        columnThreeOpponentSetScoreLabel.setText(String(currentMatch.sets[1].playerTwoSetScore))
        columnFourYourSetScoreLabel.setText(String(currentMatch.sets[2].playerOneSetScore))
        columnFourOpponentSetScoreLabel.setText(String(currentMatch.sets[2].playerTwoSetScore))
        columnTwoYourSetScoreLabel.setHidden(false)
        columnTwoOpponentSetScoreLabel.setHidden(false)
    }
    
    func updateSetScoresForEnteringFifthSet() {
        columnOneYourSetScoreLabel.setText(String(currentMatch.sets[0].playerOneSetScore))
        columnOneOpponentSetScoreLabel.setText(String(currentMatch.sets[0].playerTwoSetScore))
        columnTwoYourSetScoreLabel.setText(String(currentMatch.sets[1].playerOneSetScore))
        columnTwoOpponentSetScoreLabel.setText(String(currentMatch.sets[1].playerTwoSetScore))
        columnThreeYourSetScoreLabel.setText(String(currentMatch.sets[2].playerOneSetScore))
        columnThreeOpponentSetScoreLabel.setText(String(currentMatch.sets[2].playerTwoSetScore))
        columnFourYourSetScoreLabel.setText(String(currentMatch.sets[3].playerOneSetScore))
        columnFourOpponentSetScoreLabel.setText(String(currentMatch.sets[3].playerTwoSetScore))
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
            if currentMatch.winner == .one {
                WKInterfaceDevice.current().play(.success)
            } else if currentMatch.winner == .two {
                WKInterfaceDevice.current().play(.failure)
            }
        case false:
            if currentGame.gameScore != (0, 0) {
                // The point has concluded but not a game.
                switch currentGame.isTiebreaker {
                case true:
                    if (currentGame.playerOneGameScore + currentGame.playerTwoGameScore) % 2 == 1 {
                        WKInterfaceDevice.current().play(.start)
                    } else {
                        WKInterfaceDevice.current().play(.click)
                    }
                case false:
                    WKInterfaceDevice.current().play(.click)
                }
            } else if (currentMatch.totalNumberOfGamesPlayed % 2 == 1) {
                // Players switch servers but not ends of the court.
                WKInterfaceDevice.current().play(.stop)
            } else if (currentMatch.totalNumberOfGamesPlayed % 2 == 0) {
                // Players switch servers and switch ends of the court.
                WKInterfaceDevice.current().play(.start)
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
    }
}
