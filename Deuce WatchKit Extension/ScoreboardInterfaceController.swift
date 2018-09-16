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

class ScoreboardInterfaceController: WKInterfaceController, WCSessionDelegate, HKWorkoutSessionDelegate {
    // MARK: Properties
    
    var session: WCSession!
    var scoreManager: ScoreManager?
    var undoManager = UndoManager()
    
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
    
    let healthStore = HKHealthStore()
    
    // Used to track the current `HKWorkoutSession`.
    var currentWorkoutSession: HKWorkoutSession?
    
    var workoutBeginDate: Date?
    var workoutEndDate: Date?
    
    var isWorkoutRunning = false
    
    var currentQuery: HKQuery?
    
    var activeEnergySamples = [HKQuantitySample]()
    
    // Start with a zero quantity.
    var currentActiveEnergyQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 0.0)
    
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
        do {
            try session.updateApplicationContext(["start new match" : ""])
        } catch {
            print(error)
        }
    }
  
    override func didAppear() {
        // Only proceed if health data is available.
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        // We need to be able to write workouts, so they display as a standalone workout in the Activity app on iPhone.
        // We also need to be able to write Active Energy Burned to write samples to HealthKit to later associating with our app.
        let typesToShare = Set([
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!])
        
        let typesToRead = Set([
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!])
      
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error, !success {
                print("The error was: \(error.localizedDescription).")
            }
        }
        
        // Begin workout.
        isWorkoutRunning = true
        
        // Clear the local Active Energy Burned quantity when beginning a workout session.
        currentActiveEnergyQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 0.0)
        
        currentQuery = nil
        activeEnergySamples = []
        
        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .tennis
        workoutConfiguration.locationType = .outdoor
        var workoutSession: HKWorkoutSession
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
            workoutSession.delegate = self
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        currentWorkoutSession = workoutSession
        
        healthStore.start(workoutSession)
    }
    
    override func willDisappear() {
        session.sendMessage(["end match" : "reset"], replyHandler: nil, errorHandler: { Error in
            print(Error)
        })
        guard let workoutSession = currentWorkoutSession else { return }
        
        workoutSession.end()
        isWorkoutRunning = false
    }
    
    // MARK: Actions
    
    @IBAction func scorePointForPlayerOne(_ sender: Any) {
        currentMatch.scorePointForPlayerOne()
        playHaptic()
        updateLabelsFromModel()
        
        undoManager.registerUndo(withTarget: currentMatch) { $0.undoPlayerOneScore() }
        
        if currentMatch.winner != nil {
            guard let workoutSession = currentWorkoutSession else { return }
        
            workoutSession.end()
            isWorkoutRunning = false
        }
        
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
        
        if currentMatch.winner != nil {
            guard let workoutSession = currentWorkoutSession else { return }
            
            workoutSession.end()
            isWorkoutRunning = false
        }
        
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
        columnFivePlayerOneSetScoreLabel.setText(String(currentSet.playerOneSetScore))
        columnFivePlayerTwoSetScoreLabel.setText(String(currentSet.playerTwoSetScore))
    }
    
    func updateColumnsForTwoSets() {
        columnFourPlayerOneSetScoreLabel.setText(String(currentMatch.sets[0].playerOneSetScore))
        columnFourPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[0].playerTwoSetScore))
        columnFourPlayerOneSetScoreLabel.setHidden(false)
        columnFourPlayerTwoSetScoreLabel.setHidden(false)
    }
    
    func updateColumnsForThreeSets() {
        columnThreePlayerOneSetScoreLabel.setText(String(currentMatch.sets[0].playerOneSetScore))
        columnThreePlayerTwoSetScoreLabel.setText(String(currentMatch.sets[0].playerTwoSetScore))
        columnFourPlayerOneSetScoreLabel.setText(String(currentMatch.sets[1].playerOneSetScore))
        columnFourPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[1].playerTwoSetScore))
        columnThreePlayerOneSetScoreLabel.setHidden(false)
        columnThreePlayerTwoSetScoreLabel.setHidden(false)
    }
    
    func updateColumnsForFourSets() {
        columnTwoPlayerOneSetScoreLabel.setText(String(currentMatch.sets[0].playerOneSetScore))
        columnTwoPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[0].playerTwoSetScore))
        columnThreePlayerOneSetScoreLabel.setText(String(currentMatch.sets[1].playerOneSetScore))
        columnThreePlayerTwoSetScoreLabel.setText(String(currentMatch.sets[1].playerTwoSetScore))
        columnFourPlayerOneSetScoreLabel.setText(String(currentMatch.sets[2].playerOneSetScore))
        columnFourPlayerTwoSetScoreLabel.setText(String(currentMatch.sets[2].playerTwoSetScore))
        columnTwoPlayerOneSetScoreLabel.setHidden(false)
        columnTwoPlayerTwoSetScoreLabel.setHidden(false)
    }
    
    func updateColumnsForFiveSets() {
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
            } else if (currentMatch.totalNumberOfGamesPlayed % 2 == 0) {
                // Players switch servers and switch ends of the court.
                WKInterfaceDevice.current().play(.start)
            }
        }
    }
    
    func sendSetScoresToPhone() {
        var setsToBeSentToPhone = [[Int]]()
        for set in 0..<currentMatch.sets.count {
            setsToBeSentToPhone.append([0, 0])
            setsToBeSentToPhone[set][0] = currentMatch.sets[set].playerOneSetScore
            setsToBeSentToPhone[set][1] = currentMatch.sets[set].playerTwoSetScore
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
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    // MARK: Convenience
    
    /*
     Create and save an HKWorkout with the amount of Active Energy Burned we accumulated during the HKWorkoutSession.
     
     Additionally, associate the Active Energy Burned samples to our workout to facilitate showing our app as credited for these samples in the Move graph in the Activity app on iPhone.
     */
    func saveWorkout() {
        // Obtain the `HKObjectType` for active energy burned.
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned) else { return }
        
        // Only proceed if both `beginDate` and `endDate` are non-nil.
        guard let beginDate = workoutBeginDate, let endDate = workoutEndDate else { return }
        
        /*
         NOTE: There is a known bug where activityType property of HKWorkoutSession returns 0, as of iOS 9.1 and watchOS 2.0.1. So, rather than set it using the value from the `HKWorkoutSession`, set it explicitly for the HKWorkout object.
         */
        
        let workout = HKWorkout(activityType: HKWorkoutActivityType.tennis, start: beginDate, end: endDate, duration: endDate.timeIntervalSince(beginDate), totalEnergyBurned: currentActiveEnergyQuantity, totalDistance: HKQuantity(unit: HKUnit.meter(), doubleValue: 0.0), metadata: nil)
        
        // Save the array of samples that produces the energy burned total
        let finalActiveEnergySamples = activeEnergySamples
        
        guard healthStore.authorizationStatus(for: activeEnergyType) == .sharingAuthorized && healthStore.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized else { return }
        
        healthStore.save(workout) { success, error in
            if let error = error, !success {
                print("An error occurred saving the workout. The error was: \(error.localizedDescription)")
                return
            }
            
            // Since HealthKit completion blocks may come back on a background queue, please dispatch back to the main queue.
            if success && finalActiveEnergySamples.count > 0 {
                // Associate the accumulated samples with the workout.
                self.healthStore.add(finalActiveEnergySamples, to: workout) { [unowned self] success, error in
                    if let error = error, !success {
                        print("An error occurred adding samples to the workout. The error was: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func beginWorkout(on beginDate: Date) {
        // Obtain the `HKObjectType` for active energy burned and the `HKUnit` for kilocalories.
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned) else { return }
        let energyUnit = HKUnit.kilocalorie()
        
        // Update properties.
        workoutBeginDate = beginDate
        
        // Set up a predicate to obtain only samples from the local device starting from `beginDate`.
        let datePredicate = HKQuery.predicateForSamples(withStart: beginDate, end: nil, options: HKQueryOptions())
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate, devicePredicate])
        
        /*
         Create a results handler to recreate the samples generated by a query of active energy samples so that they can be associated with this app in the move graph. It should be noted that if your app has different heuristics for active energy burned you can generate your own quantities rather than rely on those from the watch. The sum of your sample's quantity values should equal the energy burned value provided for the workout.
         */
        let sampleHandler = { [weak self] (samples: [HKQuantitySample]) -> Void in
            DispatchQueue.main.async { [weak self] in
                
                let initialActiveEnergy = self?.currentActiveEnergyQuantity.doubleValue(for: energyUnit)
                
                let processedResults: (Double, [HKQuantitySample]) = samples.reduce((initialActiveEnergy ?? 0, [])) { current, sample in
                    let accumulatedValue = current.0 + sample.quantity.doubleValue(for: energyUnit)
                    
                    let ourSample = HKQuantitySample(type: activeEnergyType, quantity: sample.quantity, start: sample.startDate, end: sample.endDate)
                    
                    return (accumulatedValue, current.1 + [ourSample])
                }
                
                // Update the UI.
                self?.currentActiveEnergyQuantity = HKQuantity(unit: energyUnit, doubleValue: processedResults.0)
                
                // Update our samples.
                self?.activeEnergySamples += processedResults.1
            }
        }
        
        // Create a query to report new Active Energy Burned samples to our app.
        let activeEnergyQuery = HKAnchoredObjectQuery(type: activeEnergyType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { query, samples, deletedObjects, anchor, error in
            if let error = error {
                print("An error occurred with the `activeEnergyQuery`. The error was: \(error.localizedDescription)")
                return
            }
            // NOTE: `deletedObjects` are not considered in the handler as there is no way to delete samples from the watch during a workout.
            guard let activeEnergySamples = samples as? [HKQuantitySample] else { return }
            sampleHandler(activeEnergySamples)
        }
        
        // Assign the same handler to process future samples generated while the query is still active.
        activeEnergyQuery.updateHandler = { query, samples, deletedObjects, anchor, error in
            if let error = error {
                print("An error occurred with the `activeEnergyQuery`. The error was: \(error.localizedDescription)")
                return
            }
            // NOTE: `deletedObjects` are not considered in the handler as there is no way to delete samples from the watch during a workout.
            guard let activeEnergySamples = samples as? [HKQuantitySample] else { return }
            sampleHandler(activeEnergySamples)
        }
        
        currentQuery = activeEnergyQuery
        healthStore.execute(activeEnergyQuery)
    }
    
    func endWorkout(on endDate: Date) {
        workoutEndDate = endDate
        
        if let query = currentQuery {
            healthStore.stop(query)
        }
        
        saveWorkout()
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async { [unowned self] in
            switch toState {
            case .running:
                self.beginWorkout(on: date)
            case .ended:
                self.endWorkout(on: date)
            default:
                print("Unexpected workout session state: \(toState)")
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("The workout session failed. The error was: \(error.localizedDescription)")
    }
}
