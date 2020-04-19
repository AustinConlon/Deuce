//
//  MatchHistoryTableViewCell.swift
//  Deuce
//
//  Created by Austin Conlon on 5/23/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import UIKit

class MatchHistoryTableViewCell: UITableViewCell {
    
    /// The identifier used to register and dequeue cells of this class with a table view.
    static let reuseIdentifier = "MatchHistoryTableViewCell"

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var playerOneNameLabel: UILabel!
    @IBOutlet weak var playerTwoNameLabel: UILabel!
    
    @IBOutlet weak var setOneStackView: UIStackView!
    @IBOutlet weak var setTwoStackView: UIStackView!
    @IBOutlet weak var setThreeStackView: UIStackView!
    @IBOutlet weak var setFourStackView: UIStackView!
    @IBOutlet weak var setFiveStackView: UIStackView!
    
    @IBOutlet weak var playerOneSetOneScoreLabel: UILabel!
    @IBOutlet weak var playerOneSetTwoScoreLabel: UILabel!
    @IBOutlet weak var playerOneSetThreeScoreLabel: UILabel!
    @IBOutlet weak var playerOneSetFourScoreLabel: UILabel!
    @IBOutlet weak var playerOneSetFiveScoreLabel: UILabel!
    
    @IBOutlet weak var playerTwoSetOneScoreLabel: UILabel!
    @IBOutlet weak var playerTwoSetTwoScoreLabel: UILabel!
    @IBOutlet weak var playerTwoSetThreeScoreLabel: UILabel!
    @IBOutlet weak var playerTwoSetFourScoreLabel: UILabel!
    @IBOutlet weak var playerTwoSetFiveScoreLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setOneStackView.isHidden = true
        setTwoStackView.isHidden = true
        setThreeStackView.isHidden = true
        setFourStackView.isHidden = true
        setFiveStackView.isHidden = true
    }

    override func prepareForReuse() {
        setOneStackView.isHidden = true
        setTwoStackView.isHidden = true
        setThreeStackView.isHidden = true
        setFourStackView.isHidden = true
        setFiveStackView.isHidden = true
        
        playerOneNameLabel.font = .preferredFont(forTextStyle: .body)
        playerOneSetOneScoreLabel.font = .preferredFont(forTextStyle: .body)
        playerOneSetTwoScoreLabel.font = .preferredFont(forTextStyle: .body)
        playerOneSetThreeScoreLabel.font = .preferredFont(forTextStyle: .body)
        playerOneSetFourScoreLabel.font = .preferredFont(forTextStyle: .body)
        playerOneSetFiveScoreLabel.font = .preferredFont(forTextStyle: .body)
        
        playerTwoNameLabel.font = .preferredFont(forTextStyle: .body)
        playerTwoSetOneScoreLabel.font = .preferredFont(forTextStyle: .body)
        playerTwoSetTwoScoreLabel.font = .preferredFont(forTextStyle: .body)
        playerTwoSetThreeScoreLabel.font = .preferredFont(forTextStyle: .body)
        playerTwoSetFourScoreLabel.font = .preferredFont(forTextStyle: .body)
        playerTwoSetFiveScoreLabel.font = .preferredFont(forTextStyle: .body)
    }
}
