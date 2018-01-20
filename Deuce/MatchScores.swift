//
//  MatchScores.swift
//  Deuce
//
//  Created by Bijan Massoumi on 1/18/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import UIKit

class MatchScores: UIStackView {
    
    private var setScores = [UILabel]()
//    var numGames: Int8 = 0 {
//        didSet {
//            addSetScore(Score: 40)
//        }
//    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    //MARK: public methods
    func addSetScore(Score: Int8) {
        let newLabel: UILabel = UILabel()
        
        newLabel.backgroundColor = UIColor.black
        newLabel.textColor = UIColor.green
        
        // Add constraints
        newLabel.translatesAutoresizingMaskIntoConstraints = false
        newLabel.heightAnchor.constraint(equalToConstant: 21.0).isActive = true
        //newLabel.widthAnchor.constraint(equalToConstant: 21.0).isActive = true
        newLabel.text = String(Score)
        
        addArrangedSubview(newLabel)
        setScores.append(newLabel)
    }
    
    
    
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
