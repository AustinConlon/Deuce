//
//  MatchHistoryTableViewCell.swift
//  Deuce
//
//  Created by Austin Conlon on 1/8/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import UIKit

class MatchHistoryTableViewCell: UITableViewCell{

    @IBOutlet weak var playerName: UILabel!
    @IBOutlet weak var opponentName: UILabel!
    
    @IBOutlet weak var playerSetScores: MatchScores!
    @IBOutlet weak var opponentSetScores: MatchScores!
    
    @IBOutlet weak var dateLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
