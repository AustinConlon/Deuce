//
//  ScoreInterfaceController.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 1/31/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation
import CloudKit
import WatchConnectivity
import HealthKit

class ScoreInterfaceController: WKInterfaceController {
    
    // MARK: - Properties
    
    var match = Match()
    var undoStack = Stack<Match>()
    
    var workout = Workout()
    
    var playerOneGameScore: String!
    var playerTwoGameScore: String!
    
    @IBOutlet weak var playerOneServiceLabel: WKInterfaceLabel!
    @IBOutlet weak var playerTwoServiceLabel: WKInterfaceLabel!
    
    @IBOutlet weak var playerOneButton: WKInterfaceButton!
    @IBOutlet weak var playerTwoButton: WKInterfaceButton!
        
    @IBOutlet weak var playerOneGameScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var playerTwoGameScoreLabel: WKInterfaceLabel!
    
    @IBOutlet weak var playerOneCurrentSetScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var playerTwoCurrentSetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet weak var playerOneColumnFourSetScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var playerTwoColumnFourSetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet weak var playerOneColumnThreeSetScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var playerTwoColumnThreeSetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet weak var playerOneColumnTwoSetScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var playerTwoColumnTwoSetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet weak var playerOneColumnOneSetScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var playerTwoColumnOneSetScoreLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        playerOneServiceLabel.setHidden(true)
        playerTwoServiceLabel.setHidden(true)
        updateMenu()
    }
    
    override func didAppear() {
        workout.requestAuthorization()
    }
    
    // MARK: - Actions
    
    @IBAction func scorePointForPlayerOne(_ sender: Any) {
        switch match.state {
        case .notStarted:
            presentServiceChoice()
        case .playing:
            match.scorePoint(for: .playerOne)
            undoStack.push(match)
            updateUI()
        case .finished:
            break
        }
    }
    
    @IBAction func scorePointForPlayerTwo(_ sender: Any) {
        switch match.state {
        case .notStarted:
            presentServiceChoice()
        case .playing:
            match.scorePoint(for: .playerTwo)
            undoStack.push(match)
            updateUI()
        case .finished:
            break
        }
    }
    
    private func updateUI() {
        playHaptic(for: match)
        updateGameScoreLabels(for: match.set.game)
        updateTitle(for: match)
        updateScores(for: match)
        updateServiceSide(for: match.set.game)
        updateServicePlayer(for: match.set.game)
        updateMenu()
        updateInteractionEnabledState()
    }
    
    @objc func undoPoint() {
        undoStack.pop()
        if let lastMatch = undoStack.topItem {
            match = lastMatch
        }
        
        updateUI()
        
        playerOneGameScoreLabel.setVerticalAlignment(.center)
        playerTwoGameScoreLabel.setVerticalAlignment(.center)
        
        let numberOfSetsFinished = match.sets.count
        switch numberOfSetsFinished {
        case 0:
            playerOneColumnFourSetScoreLabel.setHidden(true)
            playerTwoColumnFourSetScoreLabel.setHidden(true)
        case 1:
            playerOneColumnThreeSetScoreLabel.setHidden(true)
            playerTwoColumnThreeSetScoreLabel.setHidden(true)
        case 2:
            playerOneColumnTwoSetScoreLabel.setHidden(true)
            playerTwoColumnTwoSetScoreLabel.setHidden(true)
        case 3:
            playerOneColumnOneSetScoreLabel.setHidden(true)
            playerTwoColumnOneSetScoreLabel.setHidden(true)
        default:
            break
        }
        
        match.state = .playing
        
        updateInteractionEnabledState()
    }
    
    @objc func endMatch() {
        workout.stop()
        match.stop()
        
        uploadMatchToCloud()
        
        match = Match()
        
        updateTitle(for: match)
        updateGameScoreLabels(for: match.set.game)
        updateScores(for: match)
        playerOneServiceLabel.setHidden(true)
        playerTwoServiceLabel.setHidden(true)
        updateMenu()
        
        playerOneColumnOneSetScoreLabel.setHidden(true)
        playerTwoColumnOneSetScoreLabel.setHidden(true)
        
        playerOneColumnTwoSetScoreLabel.setHidden(true)
        playerTwoColumnTwoSetScoreLabel.setHidden(true)
        
        playerOneColumnThreeSetScoreLabel.setHidden(true)
        playerTwoColumnThreeSetScoreLabel.setHidden(true)
        
        playerOneColumnFourSetScoreLabel.setHidden(true)
        playerTwoColumnFourSetScoreLabel.setHidden(true)
        
        playerOneGameScoreLabel.setVerticalAlignment(.center)
        playerTwoGameScoreLabel.setVerticalAlignment(.center)
        
        updateInteractionEnabledState()
    }
    
    func updateServiceSide(for game: Game) {
        switch (match.set.game.servicePlayer, match.set.game.serviceSide) {
        case (.playerOne?, .deuceCourt):
            playerOneServiceLabel.setHorizontalAlignment(.right)
        case (.playerOne?, .adCourt):
            playerOneServiceLabel.setHorizontalAlignment(.left)
        case (.playerTwo?, .deuceCourt):
            playerTwoServiceLabel.setHorizontalAlignment(.left)
        case (.playerTwo?, .adCourt):
            playerTwoServiceLabel.setHorizontalAlignment(.right)
        default:
            break
        }
    
        if match.rulesFormat == .noAd && match.set.game.score == [3, 3] && !match.set.isSupertiebreak && !match.set.game.isTiebreak {
            playerOneServiceLabel.setHorizontalAlignment(.center)
            playerTwoServiceLabel.setHorizontalAlignment(.center)
        }
    }
    
    func updateServicePlayer(for game: Game) {
        switch match.set.game.servicePlayer {
        case .playerOne:
            playerOneServiceLabel.setHidden(false)
            playerTwoServiceLabel.setHidden(true)
        case .playerTwo:
            playerOneServiceLabel.setHidden(true)
            playerTwoServiceLabel.setHidden(false)
        default:
            break
        }
        
        if let matchWinner = match.winner {
            workout.stop()
            
            match.state = .finished
            
            playerOneServiceLabel.setHidden(true)
            playerTwoServiceLabel.setHidden(true)
            
            switch matchWinner {
            case .playerOne:
                playerOneGameScoreLabel.setText("🏆")
            case .playerTwo:
                playerTwoGameScoreLabel.setText("🏆")
            }
            
            playerOneGameScoreLabel.setVerticalAlignment(.bottom)
            playerTwoGameScoreLabel.setVerticalAlignment(.top)
        }
    }
    
    func updateGameScoreLabels(for game: Game) {
        let playerOneGameScore = match.set.game.getScore(for: .playerOne)
        let playerTwoGameScore = match.set.game.getScore(for: .playerTwo)
        
        let localizedPlayerOneGameScore = NSLocalizedString(playerOneGameScore, tableName: "Interface", comment: "Player one's score for the current game.")
        let localizedPlayerTwoGameScore = NSLocalizedString(playerTwoGameScore, tableName: "Interface", comment: "Player two's score for the current game.")
        
        playerOneGameScoreLabel.setText(localizedPlayerOneGameScore)
        playerTwoGameScoreLabel.setText(localizedPlayerTwoGameScore)
        
        self.playerOneGameScore = localizedPlayerOneGameScore
        self.playerTwoGameScore = localizedPlayerTwoGameScore
        
        if match.set.game.isTiebreak == false {
            if match.set.game.score[0] == 4 {
                switch match.set.game.servicePlayer! {
                case .playerOne:
                    playerOneGameScoreLabel.setText(NSLocalizedString("Ad in", tableName: "Interface", comment: ""))
                    self.playerOneGameScore = NSLocalizedString("Ad in", tableName: "Interface", comment: "")
                case .playerTwo:
                    playerOneGameScoreLabel.setText(NSLocalizedString("Ad out", tableName: "Interface", comment: ""))
                    self.playerOneGameScore = NSLocalizedString("Ad out", tableName: "Interface", comment: "")
                }
                
                playerTwoGameScoreLabel.setText(nil)
            }
            
            if match.set.game.score[1] == 4 {
                switch match.set.game.servicePlayer! {
                case .playerOne:
                    playerTwoGameScoreLabel.setText(NSLocalizedString("Ad out", tableName: "Interface", comment: ""))
                    self.playerTwoGameScore = NSLocalizedString("Ad out", tableName: "Interface", comment: "")
                case .playerTwo:
                    playerTwoGameScoreLabel.setText(NSLocalizedString("Ad in", tableName: "Interface", comment: ""))
                    self.playerOneGameScore = NSLocalizedString("Ad in", tableName: "Interface", comment: "")
                    
                }
                
                playerOneGameScoreLabel.setText(nil)
            }
        }
    }
    
    func updateScores(for match: Match) {
        playerOneCurrentSetScoreLabel.setText(match.set.getScore(for: .playerOne))
        playerTwoCurrentSetScoreLabel.setText(match.set.getScore(for: .playerTwo))
        
        if match.winner == nil {
            let numberOfSetsFinished = match.sets.count
            switch numberOfSetsFinished {
            case 1:
                playerOneColumnFourSetScoreLabel.setHidden(false)
                playerTwoColumnFourSetScoreLabel.setHidden(false)
                
                playerOneColumnFourSetScoreLabel.setText(match.sets[0].getScore(for: .playerOne))
                playerTwoColumnFourSetScoreLabel.setText(match.sets[0].getScore(for: .playerTwo))
            case 2:
                playerOneColumnThreeSetScoreLabel.setHidden(false)
                playerTwoColumnThreeSetScoreLabel.setHidden(false)
                
                playerOneColumnThreeSetScoreLabel.setText(match.sets[0].getScore(for: .playerOne))
                playerTwoColumnThreeSetScoreLabel.setText(match.sets[0].getScore(for: .playerTwo))
                
                playerOneColumnFourSetScoreLabel.setText(match.sets[1].getScore(for: .playerOne))
                playerTwoColumnFourSetScoreLabel.setText(match.sets[1].getScore(for: .playerTwo))
            case 3:
                playerOneColumnTwoSetScoreLabel.setHidden(false)
                playerTwoColumnTwoSetScoreLabel.setHidden(false)
                
                playerOneColumnTwoSetScoreLabel.setText(match.sets[0].getScore(for: .playerOne))
                playerTwoColumnTwoSetScoreLabel.setText(match.sets[0].getScore(for: .playerTwo))
                
                playerOneColumnThreeSetScoreLabel.setText(match.sets[1].getScore(for: .playerOne))
                playerTwoColumnThreeSetScoreLabel.setText(match.sets[1].getScore(for: .playerTwo))
                
                playerOneColumnFourSetScoreLabel.setText(match.sets[2].getScore(for: .playerOne))
                playerTwoColumnFourSetScoreLabel.setText(match.sets[2].getScore(for: .playerTwo))
            case 4:
                playerOneColumnOneSetScoreLabel.setHidden(false)
                playerTwoColumnOneSetScoreLabel.setHidden(false)
                
                playerOneColumnOneSetScoreLabel.setText(match.sets[0].getScore(for: .playerOne))
                playerTwoColumnOneSetScoreLabel.setText(match.sets[0].getScore(for: .playerTwo))
                
                playerOneColumnTwoSetScoreLabel.setText(match.sets[1].getScore(for: .playerOne))
                playerTwoColumnTwoSetScoreLabel.setText(match.sets[1].getScore(for: .playerTwo))
                
                playerOneColumnThreeSetScoreLabel.setText(match.sets[2].getScore(for: .playerOne))
                playerTwoColumnThreeSetScoreLabel.setText(match.sets[2].getScore(for: .playerTwo))
                
                playerOneColumnFourSetScoreLabel.setText(match.sets[3].getScore(for: .playerOne))
                playerTwoColumnFourSetScoreLabel.setText(match.sets[3].getScore(for: .playerTwo))
            default:
                break
            }
        }
        
        if match.winner != nil {
            playerOneCurrentSetScoreLabel.setText(match.sets.last?.getScore(for: .playerOne))
            playerTwoCurrentSetScoreLabel.setText(match.sets.last?.getScore(for: .playerTwo))
        }
    }
    
    func updateTitle(for match: Match) {
        setTitle(nil)
        
        if match.set.game.isBreakPoint() {
            setTitle(NSLocalizedString("Break Point", tableName: "Interface", comment: "Receiving player is one point away from winning the game."))
        }
        
        
        if match.set.isSetPoint() {
            switch match.set.game.playerWithGamePoint() {
            case .playerOne:
                playerOneGameScoreLabel.setText("\(playerOneGameScore ?? "") → 🏅")
            case .playerTwo:
                playerTwoGameScoreLabel.setText("\(playerTwoGameScore ?? "") → 🏅")
            default:
                break
            }
        }
        
        if match.set.game.isTiebreak && match.set.game.isPointAfterSwitchingEnds {
            setTitle(NSLocalizedString("Changeover", tableName: "Interface", comment: "Both players switch ends of the court."))
        }
        
        if match.isMatchPoint() {
            switch match.set.game.playerWithGamePoint() {
            case .playerOne:
                playerOneGameScoreLabel.setText("\(playerOneGameScore ?? "") → 🏆")
            case .playerTwo:
                playerTwoGameScoreLabel.setText("\(playerTwoGameScore ?? "") → 🏆")
            default:
                break
            }
        }
        
        if match.isChangeover {
            setTitle(NSLocalizedString("Changeover", tableName: "Interface", comment: "Both players switch ends of the court."))
        }
        
        if match.set.game.score == [0, 0] {
            if match.set.game.isTiebreak {
                setTitle(NSLocalizedString("Tiebreak", tableName: "Interface", comment: ""))
            }
            
            if match.set.isSupertiebreak {
                if match.isChangeover {
                    setTitle(NSLocalizedString("Changeover", tableName: "Interface", comment: "Both players switch ends of the court."))
                } else {
                    setTitle(NSLocalizedString("Supertiebreak", tableName: "Interface", comment: ""))
                }
            }
        }
        
        
        if match.winner != nil  {
            setTitle(nil)
        }
    }
    
    func playHaptic(for match: Match) {
        if match.winner != nil {
            WKInterfaceDevice.current().play(.success)
        }
        
        if match.set.game.score != [0, 0] {
            if match.set.game.isTiebreak && match.isChangeover {
                WKInterfaceDevice.current().play(.retry)
            } else {
                WKInterfaceDevice.current().play(.start)
            }
        }
        
        if match.set.game.score == [0, 0] {
            if (match.set.score == [0, 0] || match.set.game.isTiebreak) && !match.isChangeover {
                WKInterfaceDevice.current().play(.success)
            }
            
            if match.isChangeover {
                WKInterfaceDevice.current().play(.retry)
            } else {
                WKInterfaceDevice.current().play(.directionUp)
            }
        }
    }
    
    func updateMenu() {
        clearAllMenuItems()
        
        if match.state == .notStarted {
            let formatsMenuItemTitle = NSLocalizedString("Formats", tableName: "Interface", comment: "Menu item for presenting the formats screen")
            
            let gearSymbol = UIImage(systemName: "gear", withConfiguration: UIImage.SymbolConfiguration(textStyle: .title2, scale: .medium))!
           
            addMenuItem(with: gearSymbol, title: formatsMenuItemTitle, action: #selector(presentRulesFormatsController))
        }
        
        if match.state == .playing || match.state == .finished {
            let undoMenuItemTitle = NSLocalizedString("Undo", tableName: "Interface", comment: "Undo the previous point")
            let arrowCounterclockwiseSymbol = UIImage(systemName: "arrow.counterclockwise", withConfiguration: UIImage.SymbolConfiguration(textStyle: .title2, scale: .medium))!
            addMenuItem(with: arrowCounterclockwiseSymbol, title: undoMenuItemTitle, action: #selector(undoPoint))
        }
        
        if match.state == .playing || match.winner != nil {
            if match.set.game.score == [0, 0] && match.set.score == [0, 0] && match.score == [0, 0] {
                // Undo is not shown at the start of a match.
                clearAllMenuItems()
            }
            
            let endMatchMenuItemTitle = NSLocalizedString("End Match", tableName: "Interface", comment: "")
            let iCloudAndArrowUpSymbol = UIImage(systemName: "icloud.and.arrow.up", withConfiguration: UIImage.SymbolConfiguration(textStyle: .title2, scale: .medium))!
            addMenuItem(with: iCloudAndArrowUpSymbol, title: endMatchMenuItemTitle, action: #selector(endMatch))
        }
        
        
    }
    
    @objc func presentRulesFormatsController() {
        presentController(withName: "Rules Formats", context: nil)
    }
    
    @objc func startMatch() {
        undoStack.push(match)
        
        workout.start()
        updateServicePlayer(for: match.set.game)
        match.state = .playing
        
        if UserDefaults.standard.integer(forKey: "minimumSetsToWinMatch") != 0 {
            match.numberOfSetsToWin = UserDefaults.standard.integer(forKey: "minimumSetsToWinMatch")
        }
        
        clearAllMenuItems()
        updateMenu()
    }
    
    @objc func presentServiceChoice() {
        let playerTwoServesFirst = WKAlertAction(title: NSLocalizedString("Opponent", tableName: "Interface", comment: "Player the watch wearer is playing against"), style: .`default`) {
            self.match.set.game.servicePlayer = .playerTwo
            self.startMatch()
        }
        
        let playerOneServesFirst = WKAlertAction(title: NSLocalizedString("You", tableName: "Interface", comment: "Player wearing the watch"), style: .`default`) {
            self.match.set.game.servicePlayer = .playerOne
            self.startMatch()
        }
        
        let localizedServiceQuestion = NSLocalizedString("Who will serve first?", tableName: "Interface", comment: "Question to the user of whether the coin toss winner chose to serve first or receive first")
        
        let userDefaults = UserDefaults()
        var localizedRulesFormatTitle = NSLocalizedString(match.rulesFormat.rawValue, tableName: "Interface", comment: "Rules format to be played")
        
        if let rulesFormatTitle = userDefaults.string(forKey: "Rules Format") {
            localizedRulesFormatTitle = NSLocalizedString(rulesFormatTitle, tableName: "Interface", comment: "Rules format to be played")
        }
        
        presentAlert(withTitle: localizedRulesFormatTitle, message: localizedServiceQuestion, preferredStyle: .actionSheet, actions: [playerTwoServesFirst, playerOneServesFirst])
    }
    
    private func updateInteractionEnabledState() {
        switch match.state {
        case .notStarted, .playing:
            playerOneButton.setEnabled(true)
            playerTwoButton.setEnabled(true)
        case .finished:
            playerOneButton.setEnabled(false)
            playerTwoButton.setEnabled(false)
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("\(#function): activationState:\(WCSession.default.activationState.rawValue)")
    }
    
    private func testMatch() {
        match = Match()
        let calendar = Calendar.current
        let dateComponents = DateComponents(calendar: calendar, year: 2019, month: 10, day: 13)
        match.date = calendar.date(from: dateComponents)
        match.set.game.servicePlayer = .playerOne
        
        while match.winner == nil {
            switch Bool.random() {
            case true:
                match.scorePoint(for: .playerOne)
            case false:
                match.scorePoint(for: .playerTwo)
            }
        }
    }
    
    private func uploadMatchToCloud() {
        if let matchData = try? PropertyListEncoder().encode(match) {
            let database = CKContainer.default().privateCloudDatabase
            let matchRecord = CKRecord(recordType: "Match")
            matchRecord["matchData"] = matchData as NSData
            
            database.save(matchRecord) { (savedRecord, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
    }
}
