//
//  ViewController.swift
//  Deuce-macOS
//
//  Created by Austin Conlon on 3/3/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    // MARK: Properties
    
    @IBOutlet weak var playerOneGameScoreTextField: NSTextField!
    @IBOutlet weak var playerTwoGameScoreTextField: NSTextField!
    
    var match = Match()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: Actions
    
    @IBAction func scorePointForPlayerOne(_ sender: Any) {
        match.scorePoint(for: .playerOne)
        updateScores(for: match.set.game)
        updateScores(for: match.sets)
    }
    
    @IBAction func scorePointForPlayerTwo(_ sender: Any) {
        match.scorePoint(for: .playerTwo)
        updateScores(for: match.set.game)
    }
    
    // MARK: Private Methods
    
    private func updateScores(for game: Game) {
        playerOneGameScoreTextField.stringValue = game.getScore(for: .playerOne)
        playerTwoGameScoreTextField.stringValue = game.getScore(for: .playerTwo)
    }
    
    private func updateScores(for sets: [Set]) {
        
    }
}

