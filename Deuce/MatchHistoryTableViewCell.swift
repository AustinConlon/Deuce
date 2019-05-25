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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
