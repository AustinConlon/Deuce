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
import HealthKit

class ScoreboardInterfaceController: WKInterfaceController, WCSessionDelegate {
    // MARK: Properties
    
    var session: WCSession!
    var scoreManager: ScoreManager?
    let workoutManager = WorkoutManager()
    
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
    
    @IBOutlet var playerOneServingLabel: WKInterfaceLabel!
    @IBOutlet var playerTwoServingLabel: WKInterfaceLabel!
    
    @IBOutlet var playerOneTapGestureRecognizer: WKTapGestureRecognizer!
    @IBOutlet var playerTwoTapGestureRecognizer: WKTapGestureRecognizer!
    
    @IBOutlet var playerOneGameScoreLabel: WKInterfaceLabel!
    @IBOutlet var playerTwoGameScoreLabel: WKInterfaceLabel!
    
    // Column five always has the current set. Column one has the oldest set played.
    @IBOutlet var columnOnePlayerOneSetScoreLabel: WKInterfaceLabel!
    @IBOutlet var columnOnePlayerTwoSetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet var columnTwoPlayerOneSetScoreLabel: WKInterfaceLabel!
    @IBOutlet var columnTwoPlayerTwoSetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet var columnThreePlayerOneSetScoreLabel: WKInterfaceLabel!
    @IBOutlet var columnThreePlayerTwoSetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet var columnFourPlayerOneSetScoreLabel: WKInterfaceLabel!
    @IBOutlet var columnFourPlayerTwoSetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet var columnFivePlayerOneSetScoreLabel: WKInterfaceLabel!
    @IBOutlet var columnFivePlayerTwoSetScoreLabel: WKInterfaceLabel!
    
    // MARK: Initialization
    
    override init() {
        super.init()
        if (WCSession.isSupported()) {
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        let context = context as? MatchManager
        scoreManager = ScoreManager(context!)
        updateLabelsFromModel()
    }
    
    override func didAppear() {
        workoutManager.startWorkout()
    }
    
    override func willDisappear() {
        session.sendMessage(["end match" : "reset"], replyHandler: nil, errorHandler: { Error in
            print(Error)
        })
        workoutManager.stopWorkout()
    }
    
    @IBAction func scorePointForPlayerTwo(_ sender: Any) {
        session.sendMessage(["score point" : "player two"], replyHandler: nil, errorHandler: { Error in
            print(Error)
        })
        currentMatch.scorePointForPlayerTwoInCurrentGame()
        playHaptic()
        updateLabelsFromModel()
        if currentMatch.winner != nil {
            workoutManager.stopWorkout()
        }
    }
    
    @IBAction func scorePointForPlayerOne(_ sender: Any) {
        session.sendMessage(["score point" : "player one"], replyHandler: nil, errorHandler: { Error in
            print(Error)
        })
        currentMatch.scorePointForPlayerOneInCurrentGame()
        playHaptic()
        updateLabelsFromModel()
        if currentMatch.winner != nil {
            workoutManager.stopWorkout()
        }
    }
    
    func updateLabelsFromModel() {
        updateServingLabelsFromModel()
        updateGameScoresFromModel()
        updateSetScoresFromModel()
        if let winner = currentMatch.winner {
            switch winner {
            case .one:
                playerOneGameScoreLabel.setText("🏆")
                playerTwoGameScoreLabel.setHidden(true)
            case .two:
                playerTwoGameScoreLabel.setText("🏆")
                playerOneGameScoreLabel.setHidden(true)
            }
            playerOneServingLabel.setHidden(true)
            playerTwoServingLabel.setHidden(true)
            playerOneTapGestureRecognizer.isEnabled = false
            playerTwoTapGestureRecognizer.isEnabled = false
            self.setTitle("Done")
            updateSetLabelsToBeWhite()
        }
    }
    
    func updateServingLabelsFromModel() {
        switch (currentGame.server, currentGame.servingSide) {
        case (.one?, .right?):
            playerOneServingLabel.setHorizontalAlignment(.right)
            playerOneServingLabel.setHidden(false)
            playerTwoServingLabel.setHidden(true)
        case (.one?, .left?):
            playerOneServingLabel.setHorizontalAlignment(.left)
            playerOneServingLabel.setHidden(false)
            playerTwoServingLabel.setHidden(true)
        case (.two?, .left?):
            playerTwoServingLabel.setHorizontalAlignment(.left)
            playerTwoServingLabel.setHidden(false)
            playerOneServingLabel.setHidden(true)
        case (.two?, .right?):
            playerTwoServingLabel.setHorizontalAlignment(.right)
            playerTwoServingLabel.setHidden(false)
            playerOneServingLabel.setHidden(true)
        default:
            break
        }
    }
    
    func updateGameScoresFromModel() {
        switch currentGame.isTiebreak {
        case true:
            playerOneGameScoreLabel.setText(String(currentGame.playerOneGameScore))
            playerTwoGameScoreLabel.setText(String(currentGame.playerTwoGameScore))
        default:
            updatePlayerOneGameScoreFromModel()
            updatePlayerTwoGameScoreFromModel()
        }
    }
    
    func updatePlayerOneGameScoreFromModel() {
        switch currentGame.playerOneGameScore {
        case 0:
            playerOneGameScoreLabel.setText("Love")
        case 15, 30:
            playerOneGameScoreLabel.setText(String(currentGame.playerOneGameScore))
        case 40:
            if currentGame.playerTwoGameScore < 40 {
                playerOneGameScoreLabel.setText(String(currentGame.playerOneGameScore))
            } else if currentGame.playerTwoGameScore == 40 {
                playerOneGameScoreLabel.setText("Deuce")
            }
        default: // Alternating advantage and deuce situations.
            if currentGame.playerOneGameScore == currentGame.playerTwoGameScore + 1 {
                if currentGame.server == .one {
                    playerOneGameScoreLabel.setText("Ad in")
                    playerTwoGameScoreLabel.setText("")
                } else if currentGame.server == .two {
                    playerOneGameScoreLabel.setText("Ad out")
                    playerTwoGameScoreLabel.setText("")
                }
            } else if currentGame.playerOneGameScore == currentGame.playerTwoGameScore {
                playerOneGameScoreLabel.setText("Deuce")
            }
        }
    }
    
    func updatePlayerTwoGameScoreFromModel() {
        switch currentGame.playerTwoGameScore {
        case 0:
            playerTwoGameScoreLabel.setText("Love")
        case 15, 30:
            playerTwoGameScoreLabel.setText(String(currentGame.playerTwoGameScore))
        case 40:
            if currentGame.playerOneGameScore < 40 {
                playerTwoGameScoreLabel.setText(String(currentGame.playerTwoGameScore))
            } else if currentGame.playerOneGameScore == 40 {
                playerTwoGameScoreLabel.setText("Deuce")
            }
        default: // Alternating advantage and deuce situations.
            if currentGame.playerTwoGameScore == currentGame.playerOneGameScore + 1 {
                if currentGame.server == .two {
                    playerTwoGameScoreLabel.setText("Ad in")
                    playerOneGameScoreLabel.setText("")
                } else if currentGame.server == .one {
                    playerTwoGameScoreLabel.setText("Ad out")
                    playerOneGameScoreLabel.setText("")
                }
            } else if currentGame.playerTwoGameScore == currentGame.playerOneGameScore {
                playerTwoGameScoreLabel.setText("Deuce")
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
        columnFivePlayerOneSetScoreLabel.setText(String(currentSet.playerOneSetScore))
        columnFivePlayerTwoSetScoreLabel.setText(String(currentSet.playerTwoSetScore))
    }
    
    func updateSetScoresForEnteringSecondSet() {
        columnFourPlayerOneSetScoreLabel.setText(String(currentMatch.sets[0].playerOneSetScore))
        columnFourPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[0].playerTwoSetScore))
        columnFourPlayerOneSetScoreLabel.setHidden(false)
        columnFourPlayerTwoSetScoreLabel.setHidden(false)
    }
    
    func updateSetScoresForEnteringThirdSet() {
        columnThreePlayerOneSetScoreLabel.setText(String(currentMatch.sets[0].playerOneSetScore))
        columnThreePlayerTwoSetScoreLabel.setText(String(currentMatch.sets[0].playerTwoSetScore))
        columnFourPlayerOneSetScoreLabel.setText(String(currentMatch.sets[1].playerOneSetScore))
        columnFourPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[1].playerTwoSetScore))
        columnThreePlayerOneSetScoreLabel.setHidden(false)
        columnThreePlayerTwoSetScoreLabel.setHidden(false)
    }
    
    func updateSetScoresForEnteringFourthSet() {
        columnTwoPlayerOneSetScoreLabel.setText(String(currentMatch.sets[0].playerOneSetScore))
        columnTwoPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[0].playerTwoSetScore))
        columnThreePlayerOneSetScoreLabel.setText(String(currentMatch.sets[1].playerOneSetScore))
        columnThreePlayerTwoSetScoreLabel.setText(String(currentMatch.sets[1].playerTwoSetScore))
        columnFourPlayerOneSetScoreLabel.setText(String(currentMatch.sets[2].playerOneSetScore))
        columnFourPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[2].playerTwoSetScore))
        columnTwoPlayerOneSetScoreLabel.setHidden(false)
        columnTwoPlayerTwoSetScoreLabel.setHidden(false)
    }
    
    func updateSetScoresForEnteringFifthSet() {
        columnOnePlayerOneSetScoreLabel.setText(String(currentMatch.sets[0].playerOneSetScore))
        columnOnePlayerTwoSetScoreLabel.setText(String(currentMatch.sets[0].playerTwoSetScore))
        columnTwoPlayerOneSetScoreLabel.setText(String(currentMatch.sets[1].playerOneSetScore))
        columnTwoPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[1].playerTwoSetScore))
        columnThreePlayerOneSetScoreLabel.setText(String(currentMatch.sets[2].playerOneSetScore))
        columnThreePlayerTwoSetScoreLabel.setText(String(currentMatch.sets[2].playerTwoSetScore))
        columnFourPlayerOneSetScoreLabel.setText(String(currentMatch.sets[3].playerOneSetScore))
        columnFourPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[3].playerTwoSetScore))
        columnOnePlayerOneSetScoreLabel.setHidden(false)
        columnOnePlayerTwoSetScoreLabel.setHidden(false)
    }
    
    func updateSetLabelsToBeWhite() {
        columnOnePlayerOneSetScoreLabel.setTextColor(.white)
        columnOnePlayerTwoSetScoreLabel.setTextColor(.white)
        columnTwoPlayerOneSetScoreLabel.setTextColor(.white)
        columnTwoPlayerTwoSetScoreLabel.setTextColor(.white)
        columnThreePlayerOneSetScoreLabel.setTextColor(.white)
        columnThreePlayerTwoSetScoreLabel.setTextColor(.white)
        columnFourPlayerOneSetScoreLabel.setTextColor(.white)
        columnFourPlayerTwoSetScoreLabel.setTextColor(.white)
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
                switch currentGame.isTiebreak {
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
        DispatchQueue.main.async {
            if let scorePoint = message["score point"] {
                switch scorePoint as! String {
                case "player one":
                    self.currentMatch.scorePointForPlayerOneInCurrentGame()
                case "player two":
                    self.currentMatch.scorePointForPlayerTwoInCurrentGame()
                default:
                    break
                }
                self.playHaptic()
                self.updateLabelsFromModel()
            } else if message["end match"] != nil {
                self.pop()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let scorePoint = applicationContext["score point"] {
                switch scorePoint as! String {
                case "player one":
                    self.currentMatch.scorePointForPlayerOneInCurrentGame()
                case "player two":
                    self.currentMatch.scorePointForPlayerTwoInCurrentGame()
                default:
                    break
                }
                self.playHaptic()
                self.updateLabelsFromModel()
            } else if applicationContext["end match"] != nil {
                self.pop()
            }
        }
    }
}
