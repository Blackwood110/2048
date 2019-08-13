//
//  Accessory.swift
//  2048
//
//  Created by Александр Дергилёв on 14/06/2019.
//  Copyright © 2019 Александр Дергилёв. All rights reserved.
//

import UIKit

protocol ScoreViewProtocol {
    func scoreChanged(to s: Int)
}

class ScoreView: UIView, ScoreViewProtocol {
    var score: Int = 0 {
        didSet {
            label.text = "SCORE: \(score)"
        }
    }
    
    let defaultFrame = CGRect(x: 0, y: 0, width: 140, height: 40)
    var label: UILabel
    
    init(backgroundColor bgColor: UIColor, textColor tColor: UIColor, font: UIFont, radius r: CGFloat) {
        label = UILabel(frame: defaultFrame)
        label.textAlignment = NSTextAlignment.center
        super.init(frame: defaultFrame)
        backgroundColor = bgColor
        label.textColor = tColor
        label.font = font
        layer.cornerRadius = r
        self.addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scoreChanged(to s: Int) {
        score = s
    }
}

class ControlView {
    let defaultFrame = CGRect(x: 0, y: 0, width: 140, height: 40)
}
