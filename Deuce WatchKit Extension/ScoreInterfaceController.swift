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
    
    @IBOutlet weak var playerOneGameScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var playerTwoGameScoreLabel: WKInterfaceLabel!
    
    @IBOutlet weak var playerOneCurrentSetScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var playerTwoCurrentSetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet weak var playerOneColumn4SetScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var playerTwoColumn4SetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet weak var playerOneColumn3SetScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var playerTwoColumn3SetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet weak var playerOneColumn2SetScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var playerTwoColumn2SetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet weak var playerOneColumn1SetScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var playerTwoColumn1SetScoreLabel: WKInterfaceLabel!
    
    override init() {
        super.init()
        undoStack = [match]
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        playerOneServiceLabel.setHidden(true)
        playerTwoServiceLabel.setHidden(true)
        updateMenu()
    }
    
    // MARK: Actions
    
    @IBAction func scorePointForPlayerOne(_ sender: Any) {
        match.scorePoint(for: .playerOne)
        undoStack.append(match)
        
        playHaptic(for: match)
        updateTitle(for: match)
        updateScores(for: match)
        updateServiceSide(for: match.set.game)
        updateServicePlayer(for: match.set.game)
        updateMenu()
    }
    
    @IBAction func scorePointForPlayerTwo(_ sender: Any) {
        match.scorePoint(for: .playerTwo)
        undoStack.append(match)
        
        playHaptic(for: match)
        updateTitle(for: match)
        updateScores(for: match)
        updateServiceSide(for: match.set.game)
        updateServicePlayer(for: match.set.game)
        updateMenu()
    }
    
    @objc func undoPoint() {
        undoStack.removeLast()
        match = undoStack.last!
        
        updateTitle(for: match)
        updateScores(for: match)
        updateServiceSide(for: match.set.game)
        updateServicePlayer(for: match.set.game)
        updateMenu()
        
        playerOneGameScoreLabel.setVerticalAlignment(.center)
        playerTwoGameScoreLabel.setVerticalAlignment(.center)
        
        let numberOfSetsFinished = match.sets.count
        switch numberOfSetsFinished {
        case 0:
            playerOneColumn4SetScoreLabel.setHidden(true)
            playerTwoColumn4SetScoreLabel.setHidden(true)
        case 1:
            playerOneColumn3SetScoreLabel.setHidden(true)
            playerTwoColumn3SetScoreLabel.setHidden(true)
        case 2:
            playerOneColumn2SetScoreLabel.setHidden(true)
            playerTwoColumn2SetScoreLabel.setHidden(true)
        case 3:
            playerOneColumn1SetScoreLabel.setHidden(true)
            playerTwoColumn1SetScoreLabel.setHidden(true)
        default:
            break
        }
    }
    
    @objc func endMatch() {
        workout?.stop()
        match = Match()
        updateTitle(for: match)
        updateScores(for: match)
        playerOneServiceLabel.setHidden(true)
        playerTwoServiceLabel.setHidden(true)
        updateMenu()
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
    
    func updateScores(for match: Match) {
        playerOneGameScoreLabel.setText(match.set.game.getScore(for: .playerOne))
        playerTwoGameScoreLabel.setText(match.set.game.getScore(for: .playerTwo))
        
        if match.set.game.tiebreak == false {
            if match.set.game.score[0] == 4 {
                switch match.set.game.servicePlayer! {
                case .playerOne:
                    playerOneGameScoreLabel.setText("Ad in")
                case .playerTwo:
                    playerOneGameScoreLabel.setText("Ad out")
                }
                
                playerTwoGameScoreLabel.setText(nil)
            }
            
            if match.set.game.score[1] == 4 {
                switch match.set.game.servicePlayer! {
                case .playerOne:
                    playerTwoGameScoreLabel.setText("Ad out")
                case .playerTwo:
                    playerTwoGameScoreLabel.setText("Ad in")
                }
                
                playerOneGameScoreLabel.setText(nil)
            }
        }
        
        playerOneCurrentSetScoreLabel.setText(match.set.getScore(for: .playerOne))
        playerTwoCurrentSetScoreLabel.setText(match.set.getScore(for: .playerTwo))
        
        if match.winner == nil {
            let numberOfSetsFinished = match.sets.count
            switch numberOfSetsFinished {
            case 1:
                playerOneColumn4SetScoreLabel.setHidden(false)
                playerTwoColumn4SetScoreLabel.setHidden(false)
                
                playerOneColumn4SetScoreLabel.setText(match.sets[0].getScore(for: .playerOne))
                playerTwoColumn4SetScoreLabel.setText(match.sets[0].getScore(for: .playerTwo))
            case 2:
                playerOneColumn3SetScoreLabel.setHidden(false)
                playerTwoColumn3SetScoreLabel.setHidden(false)
                
                playerOneColumn3SetScoreLabel.setText(match.sets[0].getScore(for: .playerOne))
                playerTwoColumn3SetScoreLabel.setText(match.sets[0].getScore(for: .playerTwo))
                
                playerOneColumn4SetScoreLabel.setText(match.sets[1].getScore(for: .playerOne))
                playerTwoColumn4SetScoreLabel.setText(match.sets[1].getScore(for: .playerTwo))
            case 3:
                playerOneColumn2SetScoreLabel.setHidden(false)
                playerTwoColumn2SetScoreLabel.setHidden(false)
                
                playerOneColumn2SetScoreLabel.setText(match.sets[0].getScore(for: .playerOne))
                playerTwoColumn2SetScoreLabel.setText(match.sets[0].getScore(for: .playerTwo))
                
                playerOneColumn3SetScoreLabel.setText(match.sets[1].getScore(for: .playerOne))
                playerTwoColumn3SetScoreLabel.setText(match.sets[1].getScore(for: .playerTwo))
                
                playerOneColumn4SetScoreLabel.setText(match.sets[2].getScore(for: .playerOne))
                playerTwoColumn4SetScoreLabel.setText(match.sets[2].getScore(for: .playerTwo))
            case 4:
                playerOneColumn1SetScoreLabel.setHidden(false)
                playerTwoColumn1SetScoreLabel.setHidden(false)
                
                playerOneColumn1SetScoreLabel.setText(match.sets[0].getScore(for: .playerOne))
                playerTwoColumn1SetScoreLabel.setText(match.sets[0].getScore(for: .playerTwo))
                
                playerOneColumn2SetScoreLabel.setText(match.sets[1].getScore(for: .playerOne))
                playerTwoColumn2SetScoreLabel.setText(match.sets[1].getScore(for: .playerTwo))
                
                playerOneColumn3SetScoreLabel.setText(match.sets[2].getScore(for: .playerOne))
                playerTwoColumn3SetScoreLabel.setText(match.sets[2].getScore(for: .playerTwo))
                
                playerOneColumn4SetScoreLabel.setText(match.sets[3].getScore(for: .playerOne))
                playerTwoColumn4SetScoreLabel.setText(match.sets[3].getScore(for: .playerTwo))
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
        
        if match.set.game.isDeuce {
            setTitle("Deuce")
        }
        
        if match.set.game.score == [0, 0] {
            if match.set.isOddGameConcluded || (match.set.score == [0, 0] && match.sets.count > 0) {
                setTitle("Switch Ends")
            } else {
                setTitle(nil)
            }
        }
        
        if match.set.game.isBreakPoint {
            setTitle("Break Point")
        }
        
        if match.set.isSetPoint {
            setTitle("Set Point")
        }
        
        if match.winner != nil {
            setTitle(nil)
        }
    }
    
    func playHaptic(for match: Match) {
        if match.winner != nil {
            WKInterfaceDevice.current().play(.notification)
        }
        
        switch match.set.game.tiebreak {
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
        
        if match.state == .playing {
            addMenuItem(with: .repeat, title: "Undo", action: #selector(undoPoint))
        }
        
        if match.state == .playing && match.winner == nil {
            addMenuItem(with: .decline, title: "End", action: #selector(endMatch))
        }
        
        if match.state == .notStarted {
            addMenuItem(with: .accept, title: "Start", action: #selector(startMatch))
//            addMenuItem(with: .more, title: NSLocalizedString("Number of Sets", tableName: "Interface", comment: "Length of the match, which is a series of sets."), action: #selector(presentNumberOfSetsAlertAction))
//            addMenuItem(with: .more, title: NSLocalizedString("Set Type", tableName: "Interface", comment: "When the set score is 6 games to 6, should a tiebreak game be played or should you continue until someone wins by a margin of 2 games (advantage)"), action: #selector(presentSetTypeAlertAction))
//            addMenuItem(with: .more, title: NSLocalizedString("Game Type", tableName: "Interface", comment: "When the game score is Deuce, players might continue to advantage (standard) or instead win"), action: #selector(presentGameTypeAlertAction))
        }
    }
    
    @objc func presentNumberOfSetsAlertAction() {
        let oneSet = WKAlertAction(title: "1 set", style: .default) {
            self.match.minimumToWin = 1
        }
        
        let bestOfThreeSets = WKAlertAction(title: NSLocalizedString("Best-of 3 sets", tableName: "Interface", comment: "First to win 2 sets wins the series"), style: .default) {
            self.match.minimumToWin = 2
        }
        
        let bestOfFiveSets = WKAlertAction(title: NSLocalizedString("Best-of 5 sets", tableName: "Interface", comment: "First to win 3 sets wins the series"), style: .default) {
            self.match.minimumToWin = 3
        }
        
        let localizedMatchLengthTitle = NSLocalizedString("Match Length", tableName: "Interface", comment: "Length of the best-of series of sets")
        
        presentAlert(withTitle: localizedMatchLengthTitle, message: nil, preferredStyle: .actionSheet, actions: [oneSet, bestOfThreeSets, bestOfFiveSets])
    }
    
    @objc func presentSetTypeAlertAction() {
        let tiebreak = WKAlertAction(title: NSLocalizedString("Tiebreak", tableName: "Interface", comment: "When the set score is 6 games to 6, a tiebreak game will be played"), style: .default) {
            Set.setType = .tiebreak
        }
        
        let superTiebreak = WKAlertAction(title: NSLocalizedString("Super Tiebreak in 3rd Set", tableName: "Interface", comment: "The 3rd set tiebreak would require a minimum of 10 points"), style: .default) {
            Set.setType = .tiebreak
            self.match.minimumToWin = 2
        }
        
        let advantage = WKAlertAction(title: NSLocalizedString("Advantage", tableName: "Interface", comment: "When the set score is 6 games to 6, the set will continue being played until someone wins by a margin of 2 games"), style: .default) {
            Set.setType = .advantage
        }
        
        presentAlert(withTitle: "Type of Set", message: nil, preferredStyle: .actionSheet, actions: [tiebreak, superTiebreak, advantage])
    }
    
    @objc func startMatch() {
        workout = Workout()
        workout!.start()
        updateServicePlayer(for: match.set.game)
        
        clearAllMenuItems()
        addMenuItem(with: .decline, title: "End", action: #selector(endMatch))
    }
}
