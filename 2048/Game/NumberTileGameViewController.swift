//
//  GameViewController.swift
//  2048
//
//  Created by Александр Дергилёв on 12/08/2019.
//  Copyright © 2019 Александр Дергилёв. All rights reserved.
//

import UIKit

class NumberTileGameViewController: UIViewController, GameModelProtocol {
    var dimension: Int
    var threshold: Int
    
    var board: GameboardView?
    var model: GameModel?
    
    var scoreView: ScoreViewProtocol?
    
    let boardWidth: CGFloat = 230.0
    
    let thinPadding: CGFloat = 3.0
    let thickPadding: CGFloat = 6.0
    
    let viewPadding: CGFloat = 10.0
    
    let verticalViewOffset: CGFloat = 0.0
    
    init(dimension d: Int, threshold t: Int) {
        dimension = d > 2 ? d : 2
        threshold = t > 8 ? t : 8
        super.init(nibName: nil, bundle: nil)
        model = GameModel(dimension: dimension, threshold: threshold, delegate: self)
        view.backgroundColor = UIColor.white
        setupSwipeControls()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSwipeControls() {
        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(upCommand(_:)))
        upSwipe.numberOfTouchesRequired = 1
        upSwipe.direction = .up
        view.addGestureRecognizer(upSwipe)
        
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(downCommand(_:)))
        downSwipe.numberOfTouchesRequired = 1
        downSwipe.direction = .down
        view.addGestureRecognizer(downSwipe)
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(leftCommand(_:)))
        leftSwipe.numberOfTouchesRequired = 1
        leftSwipe.direction = .left
        view.addGestureRecognizer(leftSwipe)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(rightCommand(_:)))
        rightSwipe.numberOfTouchesRequired = 1
        rightSwipe.direction = .right
        view.addGestureRecognizer(rightSwipe)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGame()
    }
    
    func reset() {
        assert(board != nil && model != nil)
        let b = board!
        let m = model!
        b.reset()
        m.reset()
        m.insertTileAtRandomLocation(withValue: 2)
        m.insertTileAtRandomLocation(withValue: 2)
    }
    
    func setupGame() {
        let vcHeight = view.bounds.size.height
        let vcWidth = view.bounds.size.width
        
        func xPositionToCenterView(v: UIView) -> CGFloat {
            let viewWidth = v.bounds.size.width
            let tentativeX = 0.5*(vcWidth - viewWidth)
            return tentativeX >= 0 ? tentativeX : 0
        }
        
        func yPositionForViewAtPosition(order: Int, views: [UIView]) -> CGFloat {
            assert(views.count > 0)
            assert(order >= 0 && order < views.count)
            //      let viewHeight = views[order].bounds.size.height
            let totalHeight = CGFloat(views.count - 1)*viewPadding + views.map({ $0.bounds.size.height})
                .reduce(verticalViewOffset, { $0 + $1})
            let viewsTop = 0.5*(vcHeight - totalHeight) >= 0 ? 0.5*(vcHeight - totalHeight) : 0
            
            var acc: CGFloat = 0
            for i in 0..<order {
                acc += viewPadding + views[i].bounds.size.height
            }
            return viewsTop + acc
        }
        
        let scoreView = ScoreView(backgroundColor: .black, textColor: .white, font: .systemFont(ofSize: 16.0), radius: 6)
        scoreView.score = 0
        
        let padding: CGFloat = dimension > 5 ? thinPadding : thickPadding
        let v1 = boardWidth - padding*(CGFloat(dimension + 1))
        let width: CGFloat = CGFloat(v1)/CGFloat(dimension)
        let gameboard = GameboardView(dimension: dimension,
                                      tileWidth: width,
                                      tilePadding: padding,
                                      cornerRadius: 6,
                                      backgroundColor: .black,
                                      foregroundColor: .darkGray)
        
        let views = [scoreView, gameboard]
        
        var f = scoreView.frame
        f.origin.x = xPositionToCenterView(v: scoreView)
        f.origin.y = yPositionForViewAtPosition(order: 0, views: views)
        scoreView.frame = f
        
        f = gameboard.frame
        f.origin.x = xPositionToCenterView(v: gameboard)
        f.origin.y = yPositionForViewAtPosition(order: 1, views: views)
        gameboard.frame = f
        
        view.addSubview(gameboard)
        board = gameboard
        view.addSubview(scoreView)
        self.scoreView = scoreView
        
        assert(model != nil)
        let m = model!
        m.insertTileAtRandomLocation(withValue: 2)
        m.insertTileAtRandomLocation(withValue: 2)
    }
    
    func followUp() {
        assert(model != nil)
        let m = model!
        let (userWon, _) = m.userHasWon()
        if userWon {
            let alertView = UIAlertView()
            alertView.title = "Victory"
            alertView.message = "Youw won!"
            alertView.addButton(withTitle: "Cancel")
            alertView.show()
            return
        }
        
        let randomVal = Int(arc4random_uniform(10))
        m.insertTileAtRandomLocation(withValue: randomVal == 1 ? 4 : 2)
        
        if m.userHasLost() {
            NSLog("You lost...")
            let alertView = UIAlertView()
            alertView.title = "Defeat"
            alertView.message = "You lost..."
            alertView.addButton(withTitle: "Cancel")
            alertView.show()
        }
    }
    
    @objc(up:)
    func upCommand(_ r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(direction: MoveDirection.up, onCompletion: { (changed: Bool) -> () in
            if changed {
                self.followUp()
            }
        })
    }
    
    @objc(down:)
    func downCommand(_ r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(direction: MoveDirection.down, onCompletion: { (changed: Bool) -> () in
            if changed {
                self.followUp()
            }
        })
    }
    
    @objc(left:)
    func leftCommand(_ r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(direction: MoveDirection.left, onCompletion: { (changed: Bool) -> () in
            if changed {
                self.followUp()
            }
        })
    }
    
    @objc(right:)
    func rightCommand(_ r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(direction: MoveDirection.right, onCompletion: { (changed: Bool) -> () in
            if changed {
                self.followUp()
            }
        })
    }
    func scoreChanged(to score: Int) {
        if scoreView == nil {
            return
        }
        let s = scoreView!
        s.scoreChanged(to: score)
    }
    
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int) {
        assert(board != nil)
        let b = board!
        b.moveOneTile(from: from, to: to, value: value)
    }
    
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int) {
        assert(board != nil)
        let b = board!
        b.moveTwoTiles(from: from, to: to, value: value)
    }
    
    func insertTile(at location: (Int, Int), withValue value: Int) {
        assert(board != nil)
        let b = board!
        b.insertTile(at: location, value: value)
    }
}
