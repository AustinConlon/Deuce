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
    
    var undoManager = UndoManager()
    
    let healthStore = HKHealthStore()
    
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
    
    var serverScore: String {
        get {
            if currentGame.server == .one {
                return playerOneGameScore
            } else {
                return playerTwoScore
            }
        }
    }
    
    var receiverScore: String {
        get {
            if currentGame.server == .one {
                return playerTwoScore
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
            case false:
                switch currentGame.playerOneScore {
                case 0:
                    return "LOVE"
                case 15, 30:
                    return String(currentGame.playerOneScore)
                case 40:
                    if currentGame.playerTwoScore < 40 {
                        return String(currentGame.playerOneScore)
                    } else if currentGame.playerTwoScore == 40 {
                        return "DEUCE"
                    }
                default: // Alternating advantage and deuce situations.
                    if currentGame.playerOneScore == currentGame.playerTwoScore + 1 {
                        if currentGame.server == .one {
                            return "AD IN"
                        } else if currentGame.server == .two {
                            return "AD OUT"
                        }
                    } else if currentGame.playerOneScore == currentGame.playerTwoScore {
                        return "DEUCE"
                    }
                }
            }
            return ""
        }
    }
    
    var playerTwoScore: String {
        get {
            switch currentGame.isTiebreak {
            case true:
                return String(currentGame.playerTwoScore)
            case false:
                switch currentGame.playerTwoScore {
                case 0:
                    return "LOVE"
                case 15, 30:
                    return String(currentGame.playerTwoScore)
                case 40:
                    if currentGame.playerOneScore < 40 {
                        return String(currentGame.playerTwoScore)
                    } else if currentGame.playerOneScore == 40 {
                        return "DEUCE"
                    }
                default: // Alternating advantage and deuce situations.
                    if currentGame.playerTwoScore == currentGame.playerOneScore + 1 {
                        if currentGame.server == .two {
                            return "AD IN"
                        } else if currentGame.server == .one {
                            return "AD OUT"
                        }
                    } else if currentGame.playerTwoScore == currentGame.playerOneScore {
                        return "DEUCE"
                    }
                }
            }
            return ""
        }
    }
    
    @IBOutlet var playerOneServiceLabel: WKInterfaceLabel!
    @IBOutlet var playerTwoServiceLabel: WKInterfaceLabel!
    
    @IBOutlet var playerOneGroup: WKInterfaceGroup!
    @IBOutlet var playerTwoGroup: WKInterfaceGroup!
    
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
            session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        let context = context as? MatchManager
        scoreManager = ScoreManager(context!)
        updateLabelsFromModel()
        do {
            try session.updateApplicationContext(["start new match" : ""])
        } catch {
            print(error)
        }
    }
    
    override func didAppear() {
        let typesToShare: Set = [
            HKQuantityType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: nil) { (success, error) in
            if let error = error, !success {
                print("The error was: \(error.localizedDescription).")
            }
        }
    }
    
    override func willDisappear() {
        session.sendMessage(["end match" : "reset"], replyHandler: nil, errorHandler: { Error in
            print(Error)
        })
    }
    
    // MARK: Actions
    
    @IBAction func scorePointForPlayerOne(_ sender: Any) {
        currentMatch.scorePointForPlayerOne()
        playHaptic()
        updateLabelsFromModel()
        
        undoManager.registerUndo(withTarget: currentMatch) { $0.undoPlayerOneScore() }
        
        sendSetScoresToPhone()
        clearAllMenuItems()
        if currentMatch.winner == nil {
            addMenuItem(with: .repeat, title: "Undo", action: #selector(undo))
        }
    }
    
    @IBAction func scorePointForPlayerTwo(_ sender: Any) {
        currentMatch.scorePointForPlayerTwo()
        playHaptic()
        updateLabelsFromModel()
        
        undoManager.registerUndo(withTarget: currentMatch) { $0.undoPlayerTwoScore() }
        
        sendSetScoresToPhone()
        clearAllMenuItems()
        if currentMatch.winner == nil {
            addMenuItem(with: .repeat, title: "Undo", action: #selector(undo))
        }
    }
    
    @IBAction func scoreSetPointForPlayerTwo(_ sender: Any) {
        currentMatch.increaseSetPointForPlayerTwoInCurrentGame()
        playHaptic()
        updateLabelsFromModel()
        sendSetScoresToPhone()
    }
    
    @IBAction func scoreSetPointForPlayerOne(_ sender: Any) {
        currentMatch.increaseSetPointForPlayerOneInCurrentGame()
        playHaptic()
        updateLabelsFromModel()
        sendSetScoresToPhone()
    }
    
    @objc func undo() {
        undoManager.undo()
        updateLabelsFromModel()
        sendSetScoresToPhone()
        clearAllMenuItems()
    }
    
    @IBAction func endMatch() {
        popToRootController()
    }
    
    func updateLabelsFromModel() {
        updateServingLabelsFromModel()
        updateGameScoresFromModel()
        updateSetScoresFromModel()
        
        if (currentMatch.totalNumberOfGamesPlayed % 2 == 1 && currentGame.score == (0, 0)) {
            setTitle("Switch Ends")
        }
        
        if let winner = currentMatch.winner {
            setTitle("Winner")
            
            switch winner {
            case .one:
                playerOneGameScoreLabel.setText("🏆")
                playerTwoGameScoreLabel.setHidden(true)
            case .two:
                playerTwoGameScoreLabel.setText("🏆")
                playerOneGameScoreLabel.setHidden(true)
            }
            
            playerOneServiceLabel.setHidden(true)
            playerTwoServiceLabel.setHidden(true)
            playerOneTapGestureRecognizer.isEnabled = false
            playerTwoTapGestureRecognizer.isEnabled = false
            updateSetLabelsToBeWhite()
        }
    }
    
    func updateServingLabelsFromModel() {
        switch (currentGame.server, currentGame.serverSide) {
        case (.one?, .deuceCourt):
            playerOneServiceLabel.setHorizontalAlignment(.right)
            playerOneServiceLabel.setHidden(false)
            playerTwoServiceLabel.setHidden(true)
        case (.one?, .adCourt):
            playerOneServiceLabel.setHorizontalAlignment(.left)
            playerOneServiceLabel.setHidden(false)
            playerTwoServiceLabel.setHidden(true)
        case (.two?, .deuceCourt):
            playerTwoServiceLabel.setHorizontalAlignment(.left)
            playerTwoServiceLabel.setHidden(false)
            playerOneServiceLabel.setHidden(true)
        case (.two?, .adCourt):
            playerTwoServiceLabel.setHorizontalAlignment(.right)
            playerTwoServiceLabel.setHidden(false)
            playerOneServiceLabel.setHidden(true)
        default:
            break
        }
    }
    
    func updateGameScoresFromModel() {
        switch currentGame.isTiebreak {
        case true:
            setTitle("Tiebreak")
            playerOneGameScoreLabel.setText(String(currentGame.playerOneScore))
            playerTwoGameScoreLabel.setText(String(currentGame.playerTwoScore))
        case false:
            setTitle(nil)
            updatePlayerOneGameScoreFromModel()
            updatePlayerTwoGameScoreFromModel()
        }
    }
    
    func updatePlayerOneGameScoreFromModel() {
        switch currentGame.playerOneScore {
        case 0:
            playerOneGameScoreLabel.setText("LOVE")
        case 15, 30:
            playerOneGameScoreLabel.setText(String(currentGame.playerOneScore))
        case 40:
            if currentGame.playerTwoScore < 40 {
                playerOneGameScoreLabel.setText(String(currentGame.playerOneScore))
            } else if currentGame.playerTwoScore == 40 {
                playerOneGameScoreLabel.setText("40")
                setTitle("Deuce")
            }
        default: // Alternating advantage and deuce situations.
            if currentGame.playerOneScore == currentGame.playerTwoScore + 1 {
                if currentGame.server == .one {
                    playerOneGameScoreLabel.setText("AD IN")
                } else if currentGame.server == .two {
                    playerOneGameScoreLabel.setText("AD OUT")
                }
                playerTwoGameScoreLabel.setText("")
            } else if currentGame.playerOneScore == currentGame.playerTwoScore {
                playerOneGameScoreLabel.setText("40")
                setTitle("Deuce")
            }
        }
    }
    
    func updatePlayerTwoGameScoreFromModel() {
        switch currentGame.playerTwoScore {
        case 0:
            playerTwoGameScoreLabel.setText("LOVE")
        case 15, 30:
            playerTwoGameScoreLabel.setText(String(currentGame.playerTwoScore))
        case 40:
            if currentGame.playerOneScore < 40 {
                playerTwoGameScoreLabel.setText(String(currentGame.playerTwoScore))
            } else if currentGame.playerOneScore == 40 {
                playerTwoGameScoreLabel.setText("40")
                setTitle("Deuce")
            }
        default: // Alternating advantage and deuce situations.
            if currentGame.playerTwoScore == currentGame.playerOneScore + 1 {
                if currentGame.server == .two {
                    playerTwoGameScoreLabel.setText("AD IN")
                } else if currentGame.server == .one {
                    playerTwoGameScoreLabel.setText("AD OUT")
                }
                playerOneGameScoreLabel.setText("")
            } else if currentGame.playerTwoScore == currentGame.playerOneScore {
                playerTwoGameScoreLabel.setText("40")
                setTitle("Deuce")
            }
        }
    }
    
    func updateSetScoresFromModel() {
        switch (scoreManager?.currentMatch.sets.count) {
        case 1:
            updateColumnsForOneSet()
        case 2:
            updateColumnsForTwoSets()
        case 3:
            updateColumnsForThreeSets()
        case 4:
            updateColumnsForFourSets()
        case 5:
            updateColumnsForFiveSets()
        default:
            break
        }
        updateColumnsForOneSet()
        hideMostRecentColumnAfterUndo()
    }
    
    func updateColumnsForOneSet() {
        columnFivePlayerOneSetScoreLabel.setText(String(currentSet.playerOneScore))
        columnFivePlayerTwoSetScoreLabel.setText(String(currentSet.playerTwoScore))
    }
    
    func updateColumnsForTwoSets() {
        columnFourPlayerOneSetScoreLabel.setText(String(currentMatch.sets[0].playerOneScore))
        columnFourPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[0].playerTwoScore))
        columnFourPlayerOneSetScoreLabel.setHidden(false)
        columnFourPlayerTwoSetScoreLabel.setHidden(false)
    }
    
    func updateColumnsForThreeSets() {
        columnThreePlayerOneSetScoreLabel.setText(String(currentMatch.sets[0].playerOneScore))
        columnThreePlayerTwoSetScoreLabel.setText(String(currentMatch.sets[0].playerTwoScore))
        columnFourPlayerOneSetScoreLabel.setText(String(currentMatch.sets[1].playerOneScore))
        columnFourPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[1].playerTwoScore))
        columnThreePlayerOneSetScoreLabel.setHidden(false)
        columnThreePlayerTwoSetScoreLabel.setHidden(false)
    }
    
    func updateColumnsForFourSets() {
        columnTwoPlayerOneSetScoreLabel.setText(String(currentMatch.sets[0].playerOneScore))
        columnTwoPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[0].playerTwoScore))
        columnThreePlayerOneSetScoreLabel.setText(String(currentMatch.sets[1].playerOneScore))
        columnThreePlayerTwoSetScoreLabel.setText(String(currentMatch.sets[1].playerTwoScore))
        columnFourPlayerOneSetScoreLabel.setText(String(currentMatch.sets[2].playerOneScore))
        columnFourPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[2].playerTwoScore))
        columnTwoPlayerOneSetScoreLabel.setHidden(false)
        columnTwoPlayerTwoSetScoreLabel.setHidden(false)
    }
    
    func updateColumnsForFiveSets() {
        columnOnePlayerOneSetScoreLabel.setText(String(currentMatch.sets[0].playerOneScore))
        columnOnePlayerTwoSetScoreLabel.setText(String(currentMatch.sets[0].playerTwoScore))
        columnTwoPlayerOneSetScoreLabel.setText(String(currentMatch.sets[1].playerOneScore))
        columnTwoPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[1].playerTwoScore))
        columnThreePlayerOneSetScoreLabel.setText(String(currentMatch.sets[2].playerOneScore))
        columnThreePlayerTwoSetScoreLabel.setText(String(currentMatch.sets[2].playerTwoScore))
        columnFourPlayerOneSetScoreLabel.setText(String(currentMatch.sets[3].playerOneScore))
        columnFourPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[3].playerTwoScore))
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
    
    func hideMostRecentColumnAfterUndo() {
        switch currentMatch.sets.count {
        case 1:
            columnFourPlayerOneSetScoreLabel.setHidden(true)
            columnFourPlayerTwoSetScoreLabel.setHidden(true)
        case 2:
            columnThreePlayerOneSetScoreLabel.setHidden(true)
            columnThreePlayerTwoSetScoreLabel.setHidden(true)
        case 3:
            columnTwoPlayerOneSetScoreLabel.setHidden(true)
            columnTwoPlayerTwoSetScoreLabel.setHidden(true)
        case 4:
            columnOnePlayerOneSetScoreLabel.setHidden(true)
            columnOnePlayerTwoSetScoreLabel.setHidden(true)
        default:
            break
        }
    }
    
    func playHaptic() {
        switch currentMatch.isFinished {
        case true:
            if currentMatch.winner == .one {
                WKInterfaceDevice.current().play(.success)
            } else if currentMatch.winner == .two {
                WKInterfaceDevice.current().play(.failure)
            }
        case false:
            if currentGame.score != (0, 0) {
                // The point has concluded but not a game.
                switch currentGame.isTiebreak {
                case true:
                    if (currentGame.playerOneScore + currentGame.playerTwoScore) % 2 == 1 {
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
            } else if (currentMatch.totalNumberOfGamesPlayed % 2 == 0) || currentSet.score == (0, 0) {
                // Players switch servers and switch ends of the court.
                WKInterfaceDevice.current().play(.start)
            }
        }
    }
    
    func sendSetScoresToPhone() {
        var setsToBeSentToPhone = [[Int]]()
        for set in 0..<currentMatch.sets.count {
            setsToBeSentToPhone.append([0, 0])
            setsToBeSentToPhone[set][0] = currentMatch.sets[set].playerOneScore
            setsToBeSentToPhone[set][1] = currentMatch.sets[set].playerTwoScore
        }
        
        do {
            try session.updateApplicationContext(["sets" : setsToBeSentToPhone])
        } catch {
            print(error)
        }
        
        switch currentMatch.winner {
        case .one?:
            session.transferUserInfo(["winner" : "player one"])
        case .two?:
            session.transferUserInfo(["winner" : "player two"])
        case .none:
            break
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }}
