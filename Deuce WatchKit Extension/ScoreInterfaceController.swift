//
//  ScoreInterfaceController.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 1/31/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation

class ScoreInterfaceController: WKInterfaceController {
    
    // MARK: Properties
    
    lazy var match = Match()
    var undoStack = [Match]()
    
    var workout: Workout?
    
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
    
    override init() {
        super.init()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        playerOneServiceLabel.setHidden(true)
        playerTwoServiceLabel.setHidden(true)
        updateMenu()
    }
    
    // MARK: Actions
    
    @IBAction func scorePointForPlayerOne(_ sender: Any) {
        switch match.state {
        case .notStarted:
            presentCoinToss()
        default:
            match.scorePoint(for: .playerOne)
            undoStack.append(match)
            
            playHaptic(for: match)
            updateTitle(for: match)
            updateGameScoreLabels(for: match.set.game)
            updateScores(for: match)
            updateServiceSide(for: match.set.game)
            updateServicePlayer(for: match.set.game)
            updateMenu()
            updateInteractionEnabledState()
        }
    }
    
    @IBAction func scorePointForPlayerTwo(_ sender: Any) {
        switch match.state {
        case .notStarted:
            presentCoinToss()
        default:
            match.scorePoint(for: .playerTwo)
            undoStack.append(match)
            
            playHaptic(for: match)
            updateTitle(for: match)
            updateGameScoreLabels(for: match.set.game)
            updateScores(for: match)
            updateServiceSide(for: match.set.game)
            updateServicePlayer(for: match.set.game)
            updateMenu()
            updateInteractionEnabledState()
        }
    }
    
    @objc func undoPoint() {
        undoStack.removeLast()
        match = undoStack.last!
        
        updateTitle(for: match)
        updateGameScoreLabels(for: match.set.game)
        updateScores(for: match)
        updateServiceSide(for: match.set.game)
        updateServicePlayer(for: match.set.game)
        updateMenu()
        
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
        workout?.stop()
        
        // TODO: Reduce code duplication between reseting the match state and starting a new match.
        match = Match()
        undoStack = [Match]()
        
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
    }
    
    func updateServicePlayer(for game: Game) {
        switch match.set.game.servicePlayer {
        case .playerOne?:
            playerOneServiceLabel.setHidden(false)
            playerTwoServiceLabel.setHidden(true)
        case .playerTwo?:
            playerOneServiceLabel.setHidden(true)
            playerTwoServiceLabel.setHidden(false)
        default:
            break
        }
        
        if let matchWinner = match.winner {
            workout?.stop()
            
            match.state = .finished
            
            playerOneServiceLabel.setHidden(true)
            playerTwoServiceLabel.setHidden(true)
            
            switch matchWinner {
            case .playerOne:
                playerOneGameScoreLabel.setText("🥇")
                playerTwoGameScoreLabel.setText("🥈")
            case .playerTwo:
                playerOneGameScoreLabel.setText("🥈")
                playerTwoGameScoreLabel.setText("🥇")
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
        
        if match.set.game.isTiebreak == false {
            if match.set.game.score[0] == 4 {
                switch match.set.game.servicePlayer! {
                case .playerOne:
                    playerOneGameScoreLabel.setText(NSLocalizedString("Ad in", tableName: "Interface", comment: ""))
                case .playerTwo:
                    playerOneGameScoreLabel.setText(NSLocalizedString("Ad out", tableName: "Interface", comment: ""))
                }
                
                playerTwoGameScoreLabel.setText(nil)
            }
            
            if match.set.game.score[1] == 4 {
                switch match.set.game.servicePlayer! {
                case .playerOne:
                    playerTwoGameScoreLabel.setText(NSLocalizedString("Ad out", tableName: "Interface", comment: ""))
                case .playerTwo:
                    playerTwoGameScoreLabel.setText(NSLocalizedString("Ad in", tableName: "Interface", comment: ""))
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
        
        if match.set.game.score == [0, 0] {
            if match.set.isOddGameConcluded {
                setTitle(NSLocalizedString("Switch Ends", tableName: "Interface", comment: "Both players switch ends of the court."))
            } else {
                setTitle(nil)
            }
        }
        
        if match.set.game.isTiebreak && match.set.game.isPointAfterSwitchingEnds {
            setTitle(NSLocalizedString("Switch Ends", tableName: "Interface", comment: "Both players switch ends of the court."))
        }
        
        if match.set.game.isBreakPoint() {
            setTitle(NSLocalizedString("Break Point", tableName: "Interface", comment: "Receiving player is one point away from winning the game."))
        }
        
        
        if match.set.isSetPoint() {
            setTitle(NSLocalizedString("Set Point", tableName: "Interface", comment: "A player is one point away from winning the set."))
        }
        
        if match.isMatchPoint() {
            setTitle(NSLocalizedString("Match Point", tableName: "Interface", comment: "A player is one point away from winning the match."))
        }
        
        if match.winner != nil {
            setTitle(nil)
        }
    }
    
    func playHaptic(for match: Match) {
        if match.winner != nil {
            WKInterfaceDevice.current().play(.notification)
        }
        
        switch match.set.game.isTiebreak {
        case true:
            if match.set.game.score == [0, 0] {
                WKInterfaceDevice.current().play(.notification)
            } else if (match.set.game.score[0] + match.set.game.score[1]) % 6 == 0 {
                WKInterfaceDevice.current().play(.stop)
            }
        case false:
            if match.set.game.score == [0, 0] {
                if match.set.isOddGameConcluded || match.set.score == [0, 0] {
                    WKInterfaceDevice.current().play(.stop)
                }
            } else {
                WKInterfaceDevice.current().play(.click)
            }
        }
    }
    
    func updateMenu() {
        clearAllMenuItems()
        
        if match.state == .notStarted {
            let formatsMenuItemTitle = NSLocalizedString("Formats", tableName: "Interface", comment: "Menu item for presenting the formats screen")
            addMenuItem(with: .info, title: formatsMenuItemTitle, action: #selector(presentRulesFormatsController))
        }
        
        if match.state != .notStarted && !undoStack.isEmpty {
            let undoMenuItemTitle = NSLocalizedString("Undo", tableName: "Interface", comment: "Undo the previous point")
            addMenuItem(with: .repeat, title: undoMenuItemTitle, action: #selector(undoPoint))
        }
        
        if match.state == .playing || match.winner != nil {
            let endMatchMenuItemTitle = NSLocalizedString("End Match", tableName: "Interface", comment: "")
            addMenuItem(with: .decline, title: endMatchMenuItemTitle, action: #selector(endMatch))
        }
    }
    
    @objc func presentRulesFormatsController() {
        presentController(withName: "Rules Formats", context: nil)
    }
    
    @objc func startMatch() {
        undoStack = [match]
        workout = Workout()
        workout!.start()
        updateServicePlayer(for: match.set.game)
        match.state = .playing
        
        if UserDefaults.standard.integer(forKey: "minimumSetsToWinMatch") != 0 {
            match.numberOfSetsToWin = UserDefaults.standard.integer(forKey: "minimumSetsToWinMatch")
        }
        
        clearAllMenuItems()
        updateMenu()
    }
    
    @objc func presentCoinToss() {
        let playerTwoBeginService = WKAlertAction(title: NSLocalizedString("Opponent", tableName: "Interface", comment: "Player the watch wearer is playing against"), style: .`default`) {
            self.match.set.game.servicePlayer = .playerTwo
            self.startMatch()
        }
        
        let playerOneBeginService = WKAlertAction(title: NSLocalizedString("You", tableName: "Interface", comment: "Player wearing the watch"), style: .`default`) {
            self.match.set.game.servicePlayer = .playerOne
            self.startMatch()
        }
        
        var coinTossWinnerMessage: String
        
        switch Bool.random() {
        case true:
            coinTossWinnerMessage = "You won the coin toss."
        case false:
            coinTossWinnerMessage = "Your opponent won the coin toss."
        }
        
        let localizedCoinTossWinnerMessage = NSLocalizedString(coinTossWinnerMessage, tableName: "Interface", comment: "Announcement of which player won the coin toss")
        
        let localizedCoinTossQuestion = NSLocalizedString("Who will serve first?", tableName: "Interface", comment: "Question to the user of whether the coin toss winner chose to serve first or receive first")
        
        presentAlert(withTitle: localizedCoinTossWinnerMessage, message: localizedCoinTossQuestion, preferredStyle: .actionSheet, actions: [playerTwoBeginService, playerOneBeginService])
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
}
