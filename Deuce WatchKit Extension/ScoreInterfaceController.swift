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

class ScoreInterfaceController: WKInterfaceController, WCSessionDelegate, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    // MARK: Properties
    var session: WCSession!
    
    var scoreManager: ScoreManager? {
        didSet {
            if scoreManager != nil {
                isPlaying = true
            } else if scoreManager == nil {
                isPlaying = false
            }
        }
    }
    
    var isPlaying = false {
        didSet {
            if isPlaying == true {
                clearAllMenuItems()
                addMenuItem(with: .decline, title: "End", action: #selector(endMatch))
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
            case false:
                switch currentGame.playerOneScore {
                case 0:
                    return NSLocalizedString("LOVE", tableName: "Interface", comment: "Game score of 0")
                case 15, 30:
                    return String(currentGame.playerOneScore)
                case 40:
                    if currentGame.playerTwoScore < 40 {
                        return String(currentGame.playerOneScore)
                    } else if currentGame.playerTwoScore == 40 {
                        return NSLocalizedString("Deuce", tableName: "Interface", comment: "Game score is 40-40")
                    }
                default: // Alternating advantage and deuce situations.
                    if currentGame.playerOneScore == currentGame.playerTwoScore + 1 {
                        if currentGame.server == .one {
                            return NSLocalizedString("AD IN", tableName: "Interface", comment: "After a deuce situation, the service player is now winning by one point")
                        } else if currentGame.server == .two {
                            return NSLocalizedString("AD OUT", tableName: "Interface", comment: "After a deuce situation, the receiving player is now winning by one point")
                        }
                    } else if currentGame.playerOneScore == currentGame.playerTwoScore {
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
                return String(currentGame.playerTwoScore)
            case false:
                switch currentGame.playerTwoScore {
                case 0:
                    return NSLocalizedString("LOVE", tableName: "Interface", comment: "Game score of 0")
                case 15, 30:
                    return String(currentGame.playerTwoScore)
                case 40:
                    if currentGame.playerOneScore < 40 {
                        return String(currentGame.playerTwoScore)
                    } else if currentGame.playerOneScore == 40 {
                        return NSLocalizedString("Deuce", tableName: "Interface", comment: "Game score is 40-40")
                    }
                default: // Alternating advantage and deuce situations.
                    if currentGame.playerTwoScore == currentGame.playerOneScore + 1 {
                        if currentGame.server == .two {
                            return NSLocalizedString("AD IN", tableName: "Interface", comment: "After a deuce situation, the service player is now winning by one point")
                        } else if currentGame.server == .one {
                            return NSLocalizedString("AD OUT", tableName: "Interface", comment: "After a deuce situation, the receiving player is now winning by one point")
                        }
                    } else if currentGame.playerTwoScore == currentGame.playerOneScore {
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
        addMenuItem(with: .play, title: "Play", action: #selector(presentCoinToss))
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
            currentMatch.scorePointForPlayerOne()
            playHaptic()
            updateLabelsFromModel()
            
            undoManager.registerUndo(withTarget: currentMatch) { $0.undoPlayerOneScore() }
            
            sendSetScoresToPhone()
            clearAllMenuItems()
            if currentMatch.winner == nil {
                addMenuItem(with: .repeat, title: NSLocalizedString("Undo", tableName: "Interface", comment: "Reverts the score to the previous state"), action: #selector(undo))
            }
            addMenuItem(with: .decline, title: "End", action: #selector(endMatch))
        }
    }
    
    @IBAction func scorePointForPlayerTwo(_ sender: Any) {
        switch isPlaying {
        case false:
            presentCoinToss()
        case true:
            currentMatch.scorePointForPlayerTwo()
            playHaptic()
            updateLabelsFromModel()
            
            
            undoManager.registerUndo(withTarget: currentMatch) { $0.undoPlayerTwoScore() }
            
            sendSetScoresToPhone()
            clearAllMenuItems()
            if currentMatch.winner == nil {
                addMenuItem(with: .repeat, title: NSLocalizedString("Undo", tableName: "Interface", comment: "Reverts the score to the previous state"), action: #selector(undo))
            }
            addMenuItem(with: .decline, title: "End", action: #selector(endMatch))
        }
    }
    
    @objc func undo() {
        undoManager.undo()
        updateLabelsFromModel()
        sendSetScoresToPhone()
        clearAllMenuItems()
        addMenuItem(with: .decline, title: "End", action: #selector(endMatch))
    }
    
    @IBAction func startMatch() {
        presentCoinToss()
    }
    
    @IBAction func endMatch() {
        self.scoreManager = ScoreManager(MatchManager(5, .tiebreak, Player.two))
        updateLabelsFromModel()
        playerOneServiceLabel.setHidden(true)
        playerTwoServiceLabel.setHidden(true)
        scoreManager = nil
        stopWorkout()
        // TODO: Clean this up.
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
    }
    
    @objc func presentCoinToss() {
        let playerTwoBeginService = WKAlertAction(title: NSLocalizedString("Opponent", tableName: "Interface", comment: "Player the watch wearer is playing against"), style: .`default`) {
            self.scoreManager = ScoreManager(MatchManager(5, .tiebreak, Player.two))
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
            self.scoreManager = ScoreManager(MatchManager(5, .tiebreak, Player.one))
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
        
        if let winner = currentMatch.winner {
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
            addMenuItem(with: .decline, title: "End", action: #selector(endMatch))
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
            if ((currentGame.playerOneScore + currentGame.playerTwoScore) % 6 == 0) && currentGame.isTiebreak == false {
                setTitle(NSLocalizedString("Switch Ends", tableName: "Interface", comment: "Both players change sides of the court"))
            }
            
            playerOneGameScoreLabel.setText(String(currentGame.playerOneScore))
            playerTwoGameScoreLabel.setText(String(currentGame.playerTwoScore))
        case false:
            if currentMatch.totalNumberOfGamesPlayed % 2 == 1 && currentGame.score == (0, 0) {
                setTitle(NSLocalizedString("Switch Ends", tableName: "Interface", comment: "Both players change sides of the court"))
            }
            updatePlayerOneGameScoreFromModel()
            updatePlayerTwoGameScoreFromModel()
        }
    }
    
    func updatePlayerOneGameScoreFromModel() {
        switch currentGame.playerOneScore {
        case 0:
            playerOneGameScoreLabel.setText(NSLocalizedString("LOVE", tableName: "Interface", comment: "Game score of 0"))
        case 15, 30:
            playerOneGameScoreLabel.setText(String(currentGame.playerOneScore))
        case 40:
            if currentGame.playerTwoScore < 40 {
                playerOneGameScoreLabel.setText(String(currentGame.playerOneScore))
            } else if currentGame.playerTwoScore == 40 {
                playerOneGameScoreLabel.setText("40")
                setTitle(NSLocalizedString("Deuce", tableName: "Interface", comment: "Game score is 40-40"))
            }
        default: // Alternating advantage and deuce situations.
            if currentGame.playerOneScore == currentGame.playerTwoScore + 1 {
                if currentGame.server == .one {
                    playerOneGameScoreLabel.setText(NSLocalizedString("AD IN", tableName: "Interface", comment: "After a deuce situation, the service player is now winning by one point"))
                } else if currentGame.server == .two {
                    playerOneGameScoreLabel.setText(NSLocalizedString("AD OUT", tableName: "Interface", comment: "After a deuce situation, the receiving player is now winning by one point"))
                }
                playerTwoGameScoreLabel.setText("")
            } else if currentGame.playerOneScore == currentGame.playerTwoScore {
                playerOneGameScoreLabel.setText("40")
                setTitle(NSLocalizedString("Deuce", tableName: "Interface", comment: "Game score is 40-40"))
            }
        }
    }
    
    func updatePlayerTwoGameScoreFromModel() {
        switch currentGame.playerTwoScore {
        case 0:
            playerTwoGameScoreLabel.setText(NSLocalizedString("LOVE", tableName: "Interface", comment: "Game score of 0"))
        case 15, 30:
            playerTwoGameScoreLabel.setText(String(currentGame.playerTwoScore))
        case 40:
            if currentGame.playerOneScore < 40 {
                playerTwoGameScoreLabel.setText(String(currentGame.playerTwoScore))
            } else if currentGame.playerOneScore == 40 {
                playerTwoGameScoreLabel.setText("40")
                setTitle(NSLocalizedString("Deuce", tableName: "Interface", comment: "Game score is 40-40"))
            }
        default: // Alternating advantage and deuce situations.
            if currentGame.playerTwoScore == currentGame.playerOneScore + 1 {
                if currentGame.server == .two {
                    playerTwoGameScoreLabel.setText(NSLocalizedString("AD IN", tableName: "Interface", comment: "After a deuce situation, the service player is now winning by one point"))
                } else if currentGame.server == .one {
                    playerTwoGameScoreLabel.setText(NSLocalizedString("AD OUT", tableName: "Interface", comment: "After a deuce situation, the receiving player is now winning by one point"))
                }
                playerOneGameScoreLabel.setText("")
            } else if currentGame.playerTwoScore == currentGame.playerOneScore {
                playerTwoGameScoreLabel.setText("40")
                setTitle(NSLocalizedString("Deuce", tableName: "Interface", comment: "Game score is 40-40"))
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
                // The point concluded but not the game.
                switch currentGame.isTiebreak {
                case true:
                    if (currentGame.playerOneScore + currentGame.playerTwoScore) % 2 == 1 {
                        WKInterfaceDevice.current().play(.start)
                    } else if (currentGame.playerOneScore + currentGame.playerTwoScore) % 6 == 0 {
                        WKInterfaceDevice.current().play(.stop)
                    } else {
                        WKInterfaceDevice.current().play(.click)
                    }
                case false:
                    WKInterfaceDevice.current().play(.click)
                }
            } else if (currentMatch.totalNumberOfGamesPlayed % 2 == 1) {
                // Change service but not ends of the court.
                WKInterfaceDevice.current().play(.stop)
            } else if (currentMatch.totalNumberOfGamesPlayed % 2 == 0) {
                // Change both service and ends of the court.
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
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    // MARK: Workout
    private func requestAccessToHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let healthStore = HKHealthStore()
        
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
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
        liveWorkoutBuilder?.add([totalEnergyBurnedSample]) { (success, error) in
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
