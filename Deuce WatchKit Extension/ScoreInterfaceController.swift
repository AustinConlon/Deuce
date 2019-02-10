//
//  ScoreInterfaceController.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 1/31/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation

class ScoreInterfaceController: WKInterfaceController, MatchDelegate {
    var match = Match()
    var workout = Workout()
    
    @IBOutlet weak var player1TapGestureRecognizer: WKTapGestureRecognizer!
    @IBOutlet weak var player2TapGestureRecognizer: WKTapGestureRecognizer!
    
    @IBOutlet weak var player1ServiceLabel: WKInterfaceLabel!
    @IBOutlet weak var player2ServiceLabel: WKInterfaceLabel!
    
    @IBOutlet weak var player1GameScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var player2GameScoreLabel: WKInterfaceLabel!
    
    @IBOutlet weak var player1CurrentSetScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var player2CurrentSetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet weak var player1Column4SetScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var player2Column4SetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet weak var player1Column3SetScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var player2Column3SetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet weak var player1Column2SetScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var player2Column2SetScoreLabel: WKInterfaceLabel!
    
    @IBOutlet weak var player1Column1SetScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var player2Column1SetScoreLabel: WKInterfaceLabel!
    
    override init() {
        super.init()
        match.delegate = self
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        updateServicePlayer(for: match.set.game)
        workout.start()
    }
    
    @IBAction func scorePointForPlayer1(_ sender: Any) {
        match.set.game.scorePoint(for: .player1)
    }
    
    @IBAction func scorePointForPlayer2(_ sender: Any) {
         match.set.game.scorePoint(for: .player2)
    }
    
    @IBAction func endMatch() {
        workout.stop()
    }
    
    func updateServiceSide(for game: Game) {
        switch (match.set.game.servicePlayer, match.set.game.serviceSide) {
        case (.player1?, .deuceCourt):
            player1ServiceLabel.setHorizontalAlignment(.right)
        case (.player1?, .adCourt):
            player1ServiceLabel.setHorizontalAlignment(.left)
        case (.player2?, .deuceCourt):
            player2ServiceLabel.setHorizontalAlignment(.left)
        case (.player2?, .adCourt):
            player2ServiceLabel.setHorizontalAlignment(.right)
        default:
            break
        }
    }
    
    func updateServicePlayer(for game: Game) {
        switch match.set.game.servicePlayer {
        case .player1?:
            player1ServiceLabel.setHidden(false)
            player2ServiceLabel.setHidden(true)
        case .player2?:
            player1ServiceLabel.setHidden(true)
            player2ServiceLabel.setHidden(false)
        default:
            break
        }
    }
    
    func updateScores(for game: Game) {
        player1GameScoreLabel.setText(game.getScore(for: .player1))
        player2GameScoreLabel.setText(game.getScore(for: .player2))
        
        if game.getScore(for: .player1) == "AD" {
            player2GameScoreLabel.setText(nil)
        }
        
        if game.getScore(for: .player2) == "AD" {
            player1GameScoreLabel.setText(nil)
        }
    }
    
    func updateScores(for sets: [Set]) {
        player1CurrentSetScoreLabel.setText(sets.last!.getScore(for: .player1))
        player2CurrentSetScoreLabel.setText(sets.last!.getScore(for: .player2))
        
        switch sets.count {
        case 2:
            player1Column4SetScoreLabel.setHidden(false)
            player2Column4SetScoreLabel.setHidden(false)
            
            player1Column4SetScoreLabel.setText(sets[0].getScore(for: .player1))
            player2Column4SetScoreLabel.setText(sets[0].getScore(for: .player2))
        case 3:
            player1Column3SetScoreLabel.setHidden(false)
            player2Column3SetScoreLabel.setHidden(false)
            
            player1Column3SetScoreLabel.setText(sets[0].getScore(for: .player1))
            player2Column3SetScoreLabel.setText(sets[0].getScore(for: .player2))
            
            player1Column4SetScoreLabel.setText(sets[1].getScore(for: .player1))
            player2Column4SetScoreLabel.setText(sets[1].getScore(for: .player2))
        case 4:
            player1Column2SetScoreLabel.setHidden(false)
            player2Column2SetScoreLabel.setHidden(false)
            
            player1Column2SetScoreLabel.setText(sets[0].getScore(for: .player1))
            player2Column2SetScoreLabel.setText(sets[0].getScore(for: .player2))
            
            player1Column3SetScoreLabel.setText(sets[1].getScore(for: .player1))
            player2Column3SetScoreLabel.setText(sets[1].getScore(for: .player2))
            
            player1Column4SetScoreLabel.setText(sets[2].getScore(for: .player1))
            player2Column4SetScoreLabel.setText(sets[2].getScore(for: .player2))
        case 5:
            player1Column1SetScoreLabel.setHidden(false)
            player2Column1SetScoreLabel.setHidden(false)
            
            player1Column1SetScoreLabel.setText(sets[0].getScore(for: .player1))
            player2Column1SetScoreLabel.setText(sets[0].getScore(for: .player2))
            
            player1Column2SetScoreLabel.setText(sets[1].getScore(for: .player1))
            player2Column2SetScoreLabel.setText(sets[1].getScore(for: .player2))
            
            player1Column3SetScoreLabel.setText(sets[2].getScore(for: .player1))
            player2Column3SetScoreLabel.setText(sets[2].getScore(for: .player2))
            
            player1Column4SetScoreLabel.setText(sets[3].getScore(for: .player1))
            player2Column4SetScoreLabel.setText(sets[3].getScore(for: .player2))
        default:
            break
        }
    }
    
    func updateTitle(for match: Match) {
        if match.set.game.isDeuce {
            setTitle("Deuce")
        } else {
            setTitle(nil)
        }
        
        if match.set.game.score == [0, 0] {
            if match.set.isOddGameConcluded || match.set.score == [0, 0] {
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
    }
    
    func playHaptic(for match: Match) {
        if match.set.game.score == [0, 0] {
            if match.set.isOddGameConcluded || match.set.score == [0, 0] {
                WKInterfaceDevice.current().play(.stop)
            }
            
            if match.set.game.tiebreak == true {
                WKInterfaceDevice.current().play(.notification)
            }
        } else {
            WKInterfaceDevice.current().play(.click)
        }
        
    }
    
    // MARK: MatchDelegate
    func matchDidUpdate(_ match: Match) {
        playHaptic(for: match)
        updateTitle(for: match)
        updateScores(for: match.set.game)
        updateScores(for: match.sets)
        updateServiceSide(for: match.set.game)
        updateServicePlayer(for: match.set.game)
    }
}
