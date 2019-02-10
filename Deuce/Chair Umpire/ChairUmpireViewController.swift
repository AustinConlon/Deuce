//
//  ChairUmpireViewController.swift
//  Deuce
//
//  Created by Austin Conlon on 1/21/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import UIKit

class ChairUmpireViewController: UIViewController {
    // Properties
    var match: Match!
    
    
    
    @IBOutlet weak var player1GameScoreLabel: UILabel!
    @IBOutlet weak var player2GameScoreLabel: UILabel!
    
    @IBOutlet weak var player1SetScoreLabel: UILabel!
    @IBOutlet weak var player2SetScoreLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        match = Match()
    }
    
    @IBAction func scorePointForPlayer1(_ sender: Any) {
        match.set.game.scorePoint(for: .player1)
    }
    
    @IBAction func scorePointForPlayer2(_ sender: Any) {
        match.set.game.scorePoint(for: .player2)
    }
    
    func matchDidUpdate(_ match: Match) {
        player1GameScoreLabel.text = Game.pointNames[match.set.game.score[0]]
        player2GameScoreLabel.text = Game.pointNames[match.set.game.score[1]]
        
        player1SetScoreLabel.text = String(match.set.score[0])
        player2SetScoreLabel.text = String(match.set.score[1])
        
        print(match.set.game.score)
    }
}
