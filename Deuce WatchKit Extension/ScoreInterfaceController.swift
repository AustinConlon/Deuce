//
//  ScoreboardInterfaceController.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 2/18/18.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import HealthKit

class ScoreInterfaceController: WKInterfaceController, WCSessionDelegate, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    // MARK: Properties
    var session: WCSession!
    
    var maximumNumberOfSetsInMatch = 1
    var setType: SetType = .tiebreak
    var gameType: GameType = .standard
    
    var score: Score? {
        didSet {
            if score != nil {
                isPlaying = true
            } else if score == nil {
                isPlaying = false
            }
        }
    }
    
    var isPlaying = false {
        didSet {
            switch isPlaying {
            case true:
                clearAllMenuItems()
                addMenuItem(with: .decline, title: NSLocalizedString("End", tableName: "Interface", comment: "Finishes the match"), action: #selector(stopMatch))
            case false:
                break
            }
        }
    }
    
    var undoManager = UndoManager()
    
    // HKWorkoutSession Properties
    var workoutSession: HKWorkoutSession?
    var healthStore = HKHealthStore()
    var liveWorkoutBuilder: HKLiveWorkoutBuilder?
    var workoutStartDate: Date?
    var totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 0)
    var totalStepCount = HKQuantity(unit: HKUnit.count(), doubleValue: 0)
    
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
    
    var match: MatchManager {
        get {
            return score!.currentMatch
        }
    }
    
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
            case false:
                switch currentGame.player1Score {
                case 0:
                    return NSLocalizedString("LOVE", tableName: "Interface", comment: "Game score of 0")
                case 15, 30:
                    return String(currentGame.player1Score)
                case 40:
                    if currentGame.player2Score < 40 {
                        return String(currentGame.player1Score)
                    } else if currentGame.player2Score == 40 {
                        return NSLocalizedString("Deuce", tableName: "Interface", comment: "Game score is 40-40")
                    }
                default: // Alternating advantage and deuce situations.
                    if currentGame.player1Score == currentGame.player2Score + 1 {
                        if currentGame.server == .one {
                            return NSLocalizedString("AD IN", tableName: "Interface", comment: "After a deuce situation, the service player is now winning by one point")
                        } else if currentGame.server == .two {
                            return NSLocalizedString("AD OUT", tableName: "Interface", comment: "After a deuce situation, the receiving player is now winning by one point")
                        }
                    } else if currentGame.player1Score == currentGame.player2Score {
                        return NSLocalizedString("Deuce", tableName: "Interface", comment: "Game score is 40-40")
                    }
                }
            }
            return ""
        }
    }
    
    var playerTwoGameScore: String {
        get {
            switch currentGame.isTiebreak {
            case true:
                return String(currentGame.player2Score)
            case false:
                switch currentGame.player2Score {
                case 0:
                    return NSLocalizedString("LOVE", tableName: "Interface", comment: "Game score of 0")
                case 15, 30:
                    return String(currentGame.player2Score)
                case 40:
                    if currentGame.player1Score < 40 {
                        return String(currentGame.player2Score)
                    } else if currentGame.player1Score == 40 {
                        return NSLocalizedString("Deuce", tableName: "Interface", comment: "Game score is 40-40")
                    }
                default: // Alternating advantage and deuce situations.
                    if currentGame.player2Score == currentGame.player1Score + 1 {
                        if currentGame.server == .two {
                            return NSLocalizedString("AD IN", tableName: "Interface", comment: "After a deuce situation, the service player is now winning by one point")
                        } else if currentGame.server == .one {
                            return NSLocalizedString("AD OUT", tableName: "Interface", comment: "After a deuce situation, the receiving player is now winning by one point")
                        }
                    } else if currentGame.player2Score == currentGame.player1Score {
                        return NSLocalizedString("Deuce", tableName: "Interface", comment: "Game score is 40-40")
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
        addMenuItem(with: .more, title: NSLocalizedString("Number of Sets", tableName: "Interface", comment: "Length of the match, which is a series of sets."), action: #selector(presentNumberOfSetsAlertAction))
        addMenuItem(with: .more, title: NSLocalizedString("Set Type", tableName: "Interface", comment: "When the set score is 6 games to 6, should a tiebreak game be played or should you continue until someone wins by a margin of 2 games (advantage)"), action: #selector(presentSetTypeAlertAction))
        addMenuItem(with: .more, title: NSLocalizedString("Game Type", tableName: "Interface", comment: "When the game score is Deuce, players might continue to advantage (standard) or instead win"), action: #selector(presentGameTypeAlertAction))
    }
    
    override func awake(withContext context: Any?) {
        requestAccessToHealthKit()
    }
    
    override func willDisappear() {
        session.sendMessage(["end match" : "reset"], replyHandler: nil, errorHandler: { Error in
            print(Error)
        })
    }
    
    // MARK: Actions
    @IBAction func scorePointForPlayerOne(_ sender: Any) {
        switch isPlaying {
        case false:
            presentCoinToss()
        case true:
            match.scorePoint(for: Player.one)
            playHaptic()
            updateLabelsFromModel()
            
            undoManager.registerUndo(withTarget: match) { $0.undoPlayer1Score() }
            
            sendSetScoresToPhone()
            clearAllMenuItems()
            if match.winner == nil {
                addMenuItem(with: .repeat, title: NSLocalizedString("Undo", tableName: "Interface", comment: "Reverts the score to the previous state"), action: #selector(undo))
            }
            addMenuItem(with: .decline, title: NSLocalizedString("End", tableName: "Interface", comment: "Finishes the match"), action: #selector(stopMatch))
        }
    }
    
    @IBAction func scorePointForPlayerTwo(_ sender: Any) {
        switch isPlaying {
        case false:
            presentCoinToss()
        case true:
            match.scorePoint(for: Player.two)
            playHaptic()
            updateLabelsFromModel()
            
            undoManager.registerUndo(withTarget: match) { $0.undoPlayer2Score() }
            
            sendSetScoresToPhone()
            clearAllMenuItems()
            if match.winner == nil {
                addMenuItem(with: .repeat, title: NSLocalizedString("Undo", tableName: "Interface", comment: "Reverts the score to the previous state"), action: #selector(undo))
            }
            addMenuItem(with: .decline, title: NSLocalizedString("End", tableName: "Interface", comment: "Finishes the match"), action: #selector(stopMatch))
        }
    }
    
    @objc func undo() {
        undoManager.undo()
        updateLabelsFromModel()
        sendSetScoresToPhone()
        clearAllMenuItems()
        setTitle(nil)
        addMenuItem(with: .decline, title: NSLocalizedString("End", tableName: "Interface", comment: "Finishes the match"), action: #selector(stopMatch))
    }
    
    @IBAction func startMatch() {
        presentCoinToss()
    }
    
    @IBAction func stopMatch() {
        self.score = Score(MatchManager(maximumNumberOfSetsInMatch, setType: setType, gameType: gameType, Player.two))
        updateLabelsFromModel()
        playerOneServiceLabel.setHidden(true)
        playerTwoServiceLabel.setHidden(true)
        score = nil
        stopWorkout()
        
        columnOnePlayerOneSetScoreLabel.setText(String(0))
        columnOnePlayerTwoSetScoreLabel.setText(String(0))
        columnTwoPlayerOneSetScoreLabel.setText(String(0))
        columnTwoPlayerTwoSetScoreLabel.setText(String(0))
        columnThreePlayerOneSetScoreLabel.setText(String(0))
        columnThreePlayerTwoSetScoreLabel.setText(String(0))
        columnFourPlayerOneSetScoreLabel.setText(String(0))
        columnFourPlayerTwoSetScoreLabel.setText(String(0))
        
        columnOnePlayerOneSetScoreLabel.setHidden(true)
        columnOnePlayerTwoSetScoreLabel.setHidden(true)
        columnTwoPlayerOneSetScoreLabel.setHidden(true)
        columnTwoPlayerTwoSetScoreLabel.setHidden(true)
        columnThreePlayerOneSetScoreLabel.setHidden(true)
        columnThreePlayerTwoSetScoreLabel.setHidden(true)
        columnFourPlayerOneSetScoreLabel.setHidden(true)
        columnFourPlayerTwoSetScoreLabel.setHidden(true)
        
        playerOneTapGestureRecognizer.isEnabled = true
        playerTwoTapGestureRecognizer.isEnabled = true
        
        playerOneGameScoreLabel.setHidden(false)
        playerTwoGameScoreLabel.setHidden(false)
        
        clearAllMenuItems()
        addMenuItem(with: .more, title: NSLocalizedString("Number of Sets", tableName: "Interface", comment: "Length of the match, which is a series of sets."), action: #selector(presentNumberOfSetsAlertAction))
        addMenuItem(with: .more, title: NSLocalizedString("Set Type", tableName: "Interface", comment: "When the set score is 6 games to 6, should a tiebreak game be played or should you continue until someone wins by a margin of 2 games (advantage)"), action: #selector(presentSetTypeAlertAction))
        addMenuItem(with: .more, title: NSLocalizedString("Game Type", tableName: "Interface", comment: "When the game score is Deuce, players might continue to advantage (standard) or instead win"), action: #selector(presentGameTypeAlertAction))
    }
    
    @objc func presentNumberOfSetsAlertAction() {
        let oneSet = WKAlertAction(title: "1 set", style: .default) {
            self.maximumNumberOfSetsInMatch = 1
        }
        
        let bestOfThreeSets = WKAlertAction(title: NSLocalizedString("Best-of 3 sets", tableName: "Interface", comment: "First to win 2 sets wins the series"), style: .default) {
            self.maximumNumberOfSetsInMatch = 3
        }
        
        let bestOfFiveSets = WKAlertAction(title: NSLocalizedString("Best-of 5 sets", tableName: "Interface", comment: "First to win 3 sets wins the series"), style: .default) {
            self.maximumNumberOfSetsInMatch = 5
        }
        
        let localizedMatchLengthTitle = NSLocalizedString("Match Length", tableName: "Interface", comment: "Length of the best-of series of sets")
        
        presentAlert(withTitle: localizedMatchLengthTitle, message: nil, preferredStyle: .actionSheet, actions: [oneSet, bestOfThreeSets, bestOfFiveSets])
    }
    
    @objc func presentSetTypeAlertAction() {
        let tiebreak = WKAlertAction(title: NSLocalizedString("Tiebreak", tableName: "Interface", comment: "When the set score is 6 games to 6, a tiebreak game will be played"), style: .default) {
            self.setType = .tiebreak
        }
        
        let superTiebreak = WKAlertAction(title: NSLocalizedString("Super Tiebreak in 3rd Set", tableName: "Interface", comment: "The 3rd set tiebreak would require a minimum of 10 points"), style: .default) {
            self.setType = .superTiebreak
            self.maximumNumberOfSetsInMatch = 3
        }
        
        let advantage = WKAlertAction(title: NSLocalizedString("Advantage", tableName: "Interface", comment: "When the set score is 6 games to 6, the set will continue being played until someone wins by a margin of 2 games"), style: .default) {
            self.setType = .advantage
        }
        
        presentAlert(withTitle: "Type of Set", message: nil, preferredStyle: .actionSheet, actions: [tiebreak, superTiebreak, advantage])
    }
    
    @objc func presentGameTypeAlertAction() {
        let standard = WKAlertAction(title: NSLocalizedString("Standard", tableName: "Interface", comment: "When the game score is deuce, continue as normal with advantage in and advantage out"), style: .default) {
            self.gameType = .standard
        }
        
        let noAd = WKAlertAction(title: NSLocalizedString("No-ad", tableName: "Interface", comment: "When the game score is deuce, the winner of the next point wins the game"), style: .default) {
            self.gameType = .noAd
        }
        
        presentAlert(withTitle: "Game Type", message: nil, preferredStyle: .actionSheet, actions: [standard, noAd])
    }
    
    @objc func presentCoinToss() {
        let playerTwoBeginService = WKAlertAction(title: NSLocalizedString("Opponent", tableName: "Interface", comment: "Player the watch wearer is playing against"), style: .`default`) {
            self.score = Score(MatchManager(self.maximumNumberOfSetsInMatch, setType: self.setType, gameType: self.gameType, Player.two))
            self.updateLabelsFromModel()
            
            do {
                try self.session.updateApplicationContext(["start new match" : ""])
            } catch {
                print(error)
            }
            
            self.startWorkout()
            self.isPlaying = true
        }
        
        let playerOneBeginService = WKAlertAction(title: NSLocalizedString("You", tableName: "Interface", comment: "Player wearing the watch"), style: .`default`) {
            self.score = Score(MatchManager(self.maximumNumberOfSetsInMatch, setType: self.setType, gameType: self.gameType, Player.one))
            self.updateLabelsFromModel()
            
            do {
                try self.session.updateApplicationContext(["start new match" : ""])
            } catch {
                print(error)
            }
            
            self.startWorkout()
            self.isPlaying = true
        }
        
        var coinTossWinnerMessage: String
        
        switch MatchManager.coinTossWinner {
        case .one:
            coinTossWinnerMessage = "You won the coin toss."
        case .two:
            coinTossWinnerMessage = "Your opponent won the coin toss."
        }
        
        let localizedCoinTossWinnerMessage = NSLocalizedString(coinTossWinnerMessage, tableName: "Interface", comment: "Announcement of which player won the coin toss")
        
        let localizedCoinTossQuestion = NSLocalizedString("Who will serve first?", tableName: "Interface", comment: "Question to the user of whether the coin toss winner chose to serve first or receive first")
        
        presentAlert(withTitle: localizedCoinTossWinnerMessage, message: localizedCoinTossQuestion, preferredStyle: .actionSheet, actions: [playerTwoBeginService, playerOneBeginService])
    }
    
    func updateLabelsFromModel() {
        updateServingLabelsFromModel()
        updateGameScoresFromModel()
        updateSetScoresFromModel()
        
        if let winner = match.winner {
            setTitle(NSLocalizedString("Winner", tableName: "Interface", comment: "Match is finished"))
            
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
            stopWorkout()
            clearAllMenuItems()
            addMenuItem(with: .decline, title: NSLocalizedString("End", tableName: "Interface", comment: "Finishes the match"), action: #selector(stopMatch))
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
        setTitle(nil)
        switch currentGame.isTiebreak {
        case true:
            if currentGame.score == (0, 0) {
                setTitle("Tiebreak")
            }
            
            if ((currentGame.player1Score + currentGame.player2Score) % 6 == 0) && currentGame.score != (0, 0) {
                setTitle(NSLocalizedString("Switch Ends", tableName: "Interface", comment: "Both players change sides of the court"))
            }
            
            playerOneGameScoreLabel.setText(String(currentGame.player1Score))
            playerTwoGameScoreLabel.setText(String(currentGame.player2Score))
        case false:
            if (currentSet.isOddGameFinished && currentGame.score == (0, 0)) || (currentSet.score == (0, 0) && match.score > (0, 0)) {
                setTitle(NSLocalizedString("Switch Ends", tableName: "Interface", comment: "Both players change sides of the court"))
            }
            updatePlayer1GameScore()
            updatePlayer2GameScore()
        }
    }
    
    func updatePlayer1GameScore() {
        switch currentGame.player1Score {
        case 0:
            playerOneGameScoreLabel.setText(NSLocalizedString("LOVE", tableName: "Interface", comment: "Game score of 0"))
        case 15, 30:
            playerOneGameScoreLabel.setText(String(currentGame.player1Score))
        case 40:
            if currentGame.player2Score < 40 {
                playerOneGameScoreLabel.setText(String(currentGame.player1Score))
            } else if currentGame.player2Score == 40 {
                playerOneGameScoreLabel.setText("40")
                setTitle(NSLocalizedString("Deuce", tableName: "Interface", comment: "Game score is 40-40"))
            }
        default: // Alternating advantage and deuce situations.
            if currentGame.player1Score == currentGame.player2Score + 1 {
                if currentGame.server == .one {
                    playerOneGameScoreLabel.setText(NSLocalizedString("AD IN", tableName: "Interface", comment: "After a deuce situation, the service player is now winning by one point"))
                } else if currentGame.server == .two {
                    playerOneGameScoreLabel.setText(NSLocalizedString("AD OUT", tableName: "Interface", comment: "After a deuce situation, the receiving player is now winning by one point"))
                }
                playerTwoGameScoreLabel.setText("")
            } else if currentGame.player1Score == currentGame.player2Score {
                playerOneGameScoreLabel.setText("40")
                setTitle(NSLocalizedString("Deuce", tableName: "Interface", comment: "Game score is 40-40"))
            }
        }
    }
    
    func updatePlayer2GameScore() {
        switch currentGame.player2Score {
        case 0:
            playerTwoGameScoreLabel.setText(NSLocalizedString("LOVE", tableName: "Interface", comment: "Game score of 0"))
        case 15, 30:
            playerTwoGameScoreLabel.setText(String(currentGame.player2Score))
        case 40:
            if currentGame.player1Score < 40 {
                playerTwoGameScoreLabel.setText(String(currentGame.player2Score))
            } else if currentGame.player1Score == 40 {
                playerTwoGameScoreLabel.setText("40")
                setTitle(NSLocalizedString("Deuce", tableName: "Interface", comment: "Game score is 40-40"))
            }
        default: // Alternating advantage and deuce situations.
            if currentGame.player2Score == currentGame.player1Score + 1 {
                if currentGame.server == .two {
                    playerTwoGameScoreLabel.setText(NSLocalizedString("AD IN", tableName: "Interface", comment: "After a deuce situation, the service player is now winning by one point"))
                } else if currentGame.server == .one {
                    playerTwoGameScoreLabel.setText(NSLocalizedString("AD OUT", tableName: "Interface", comment: "After a deuce situation, the receiving player is now winning by one point"))
                }
                playerOneGameScoreLabel.setText("")
            } else if currentGame.player2Score == currentGame.player1Score {
                playerTwoGameScoreLabel.setText("40")
                setTitle(NSLocalizedString("Deuce", tableName: "Interface", comment: "Game score is 40-40"))
            }
        }
    }
    
    func updateSetScoresFromModel() {
        switch (score?.currentMatch.sets.count) {
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
        columnFivePlayerOneSetScoreLabel.setText(String(currentSet.player1Score))
        columnFivePlayerTwoSetScoreLabel.setText(String(currentSet.player2Score))
    }
    
    func updateColumnsForTwoSets() {
        columnFourPlayerOneSetScoreLabel.setText(String(match.sets[0].player1Score))
        columnFourPlayerTwoSetScoreLabel.setText(String(match.sets[0].player2Score))
        columnFourPlayerOneSetScoreLabel.setHidden(false)
        columnFourPlayerTwoSetScoreLabel.setHidden(false)
    }
    
    func updateColumnsForThreeSets() {
        columnThreePlayerOneSetScoreLabel.setText(String(match.sets[0].player1Score))
        columnThreePlayerTwoSetScoreLabel.setText(String(match.sets[0].player2Score))
        columnFourPlayerOneSetScoreLabel.setText(String(match.sets[1].player1Score))
        columnFourPlayerTwoSetScoreLabel.setText(String(match.sets[1].player2Score))
        columnThreePlayerOneSetScoreLabel.setHidden(false)
        columnThreePlayerTwoSetScoreLabel.setHidden(false)
    }
    
    func updateColumnsForFourSets() {
        columnTwoPlayerOneSetScoreLabel.setText(String(match.sets[0].player1Score))
        columnTwoPlayerTwoSetScoreLabel.setText(String(match.sets[0].player2Score))
        columnThreePlayerOneSetScoreLabel.setText(String(match.sets[1].player1Score))
        columnThreePlayerTwoSetScoreLabel.setText(String(match.sets[1].player2Score))
        columnFourPlayerOneSetScoreLabel.setText(String(match.sets[2].player1Score))
        columnFourPlayerTwoSetScoreLabel.setText(String(match.sets[2].player2Score))
        columnTwoPlayerOneSetScoreLabel.setHidden(false)
        columnTwoPlayerTwoSetScoreLabel.setHidden(false)
    }
    
    func updateColumnsForFiveSets() {
        columnOnePlayerOneSetScoreLabel.setText(String(match.sets[0].player1Score))
        columnOnePlayerTwoSetScoreLabel.setText(String(match.sets[0].player2Score))
        columnTwoPlayerOneSetScoreLabel.setText(String(match.sets[1].player1Score))
        columnTwoPlayerTwoSetScoreLabel.setText(String(match.sets[1].player2Score))
        columnThreePlayerOneSetScoreLabel.setText(String(match.sets[2].player1Score))
        columnThreePlayerTwoSetScoreLabel.setText(String(match.sets[2].player2Score))
        columnFourPlayerOneSetScoreLabel.setText(String(match.sets[3].player1Score))
        columnFourPlayerTwoSetScoreLabel.setText(String(match.sets[3].player2Score))
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
        switch match.sets.count {
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
        switch match.matchState {
        case .finished:
            if match.winner == .one {
                WKInterfaceDevice.current().play(.success)
            } else if match.winner == .two {
                WKInterfaceDevice.current().play(.failure)
            }
        default:
            if currentGame.score != (0, 0) {
                // The point concluded but not the game.
                switch currentGame.isTiebreak {
                case true:
                    if (currentGame.player1Score + currentGame.player2Score) % 2 == 1 {
                        WKInterfaceDevice.current().play(.start)
                    } else if (currentGame.player1Score + currentGame.player2Score) % 6 == 0 {
                        WKInterfaceDevice.current().play(.stop)
                    } else {
                        WKInterfaceDevice.current().play(.click)
                    }
                case false:
                    WKInterfaceDevice.current().play(.click)
                }
            } else if currentSet.isOddGameFinished || (currentSet.score == (0, 0) && match.score > (0, 0)) {
                // Change both service and ends of the court.
                WKInterfaceDevice.current().play(.stop)
            } else {
                // Change service but not ends of the court.
                WKInterfaceDevice.current().play(.start)
            }
        }
    }
    
    func sendSetScoresToPhone() {
        var setsToBeSentToPhone = [[Int]]()
        for set in 0..<match.sets.count {
            setsToBeSentToPhone.append([0, 0])
            setsToBeSentToPhone[set][0] = match.sets[set].player1Score
            setsToBeSentToPhone[set][1] = match.sets[set].player2Score
        }
        
        do {
            try session.updateApplicationContext(["sets" : setsToBeSentToPhone])
        } catch {
            print(error)
        }
        
        switch match.winner {
        case .one?:
            session.transferUserInfo(["winner" : "player one"])
        case .two?:
            session.transferUserInfo(["winner" : "player two"])
        case .none:
            break
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    // MARK: Workout
    private func requestAccessToHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let healthStore = HKHealthStore()
        
        let typesToShare: Set = [
            HKQuantityType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .stepCount)!
        ]
        
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            if let error = error, !success {
                print(error.localizedDescription)
            }
        }
    }
    
    private func startWorkout() {
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .tennis
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
            liveWorkoutBuilder = workoutSession!.associatedWorkoutBuilder()
            workoutStartDate = Date()
        } catch {
            return
        }
        
        workoutSession?.delegate = self
        liveWorkoutBuilder?.delegate = self
        liveWorkoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: workoutConfiguration)
        
        workoutSession?.startActivity(with: workoutStartDate)
        
        liveWorkoutBuilder!.beginCollection(withStart: workoutStartDate!) { (success, error) in
            if let error = error, !success {
                print(error.localizedDescription)
            }
        }
    }
    
    private func stopWorkout() {
        // Create energy samples
        let totalEnergyBurnedSample = HKQuantitySample(type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                                                       quantity: self.totalEnergyBurned,
                                                       start: self.workoutStartDate!,
                                                       end: Date())
        
        let totalStepCountSample = HKQuantitySample(type: HKQuantityType.quantityType(forIdentifier: .stepCount)!,
                                                       quantity: self.totalStepCount,
                                                       start: self.workoutStartDate!,
                                                       end: Date())
        
        liveWorkoutBuilder?.add([totalEnergyBurnedSample, totalStepCountSample]) { (success, error) in
            if let error = error, !success {
                print(error.localizedDescription)
            }
        }
        
        workoutSession?.end()
        
        liveWorkoutBuilder?.endCollection(withEnd: Date()) { (success, error) in
            if let error = error, !success {
                print(error.localizedDescription)
            }
        }
        
        liveWorkoutBuilder?.finishWorkout { (workout, error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        
    }
}
