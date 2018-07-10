//
//  MatchHistoryTableViewCell.swift
//  Deuce
//
//  Created by Austin Conlon on 7/3/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import UIKit

class MatchHistoryTableViewCell: UITableViewCell {
    // MARK: Properties
    @IBOutlet weak var matchStateLabel: UILabel!
    
    @IBOutlet weak var columnOneSetLabel: UILabel! {
        didSet {
            self.isHidden = false
        }
    }
    @IBOutlet weak var columnTwoSetLabel: UILabel! {
        didSet {
            self.isHidden = false
        }
    }
    @IBOutlet weak var columnThreeSetLabel: UILabel! {
        didSet {
            self.isHidden = false
        }
    }
    @IBOutlet weak var columnFourSetLabel: UILabel! {
        didSet {
            self.isHidden = false
        }
    }
    @IBOutlet weak var columnFiveSetLabel: UILabel! {
        didSet {
            self.isHidden = false
        }
    }
    
    // Opponent
    @IBOutlet weak var playerTwoNameLabel: UILabel!
    @IBOutlet weak var columnOnePlayerTwoSetScoreLabel: UILabel! {
        didSet {
            self.isHidden = false
        }
    }
    @IBOutlet weak var columnTwoPlayerTwoSetScoreLabel: UILabel! {
        didSet {
            self.isHidden = false
        }
    }
    @IBOutlet weak var columnThreePlayerTwoSetScoreLabel: UILabel! {
        didSet {
            self.isHidden = false
        }
    }
    @IBOutlet weak var columnFourPlayerTwoSetScoreLabel: UILabel! {
        didSet {
            self.isHidden = false
        }
    }
    @IBOutlet weak var columnFivePlayerTwoSetScoreLabel: UILabel! {
        didSet {
            self.isHidden = false
        }
    }
    
    // You
    @IBOutlet weak var playerOneNameLabel: UILabel!
    @IBOutlet weak var columnOnePlayerOneSetScoreLabel: UILabel! {
        didSet {
            self.isHidden = false
        }
    }
    @IBOutlet weak var columnTwoPlayerOneSetScoreLabel: UILabel! {
        didSet {
            self.isHidden = false
        }
    }
    @IBOutlet weak var columnThreePlayerOneSetScoreLabel: UILabel! {
        didSet {
            self.isHidden = false
        }
    }
    @IBOutlet weak var columnFourPlayerOneSetScoreLabel: UILabel! {
        didSet {
            self.isHidden = false
        }
    }
    @IBOutlet weak var columnFivePlayerOneSetScoreLabel: UILabel! {
        didSet {
            self.isHidden = false
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        matchStateLabel.isHidden = true
        columnOneSetLabel.isHidden = true
        columnTwoSetLabel.isHidden = true
        columnThreeSetLabel.isHidden = true
        columnFourSetLabel.isHidden = true
        columnFiveSetLabel.isHidden = true
        columnOnePlayerOneSetScoreLabel.isHidden = true
        columnOnePlayerTwoSetScoreLabel.isHidden = true
        columnTwoPlayerOneSetScoreLabel.isHidden = true
        columnTwoPlayerTwoSetScoreLabel.isHidden = true
        columnThreePlayerOneSetScoreLabel.isHidden = true
        columnThreePlayerTwoSetScoreLabel.isHidden = true
        columnFourPlayerOneSetScoreLabel.isHidden = true
        columnFourPlayerTwoSetScoreLabel.isHidden = true
        columnFivePlayerOneSetScoreLabel.isHidden = true
        columnFivePlayerTwoSetScoreLabel.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
