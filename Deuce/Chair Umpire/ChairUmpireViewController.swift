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
        match.scorePoint(for: .playerOne)
    }
    
    @IBAction func scorePointForPlayer2(_ sender: Any) {
        match.scorePoint(for: .playerTwo)
    }
}
