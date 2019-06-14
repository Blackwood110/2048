//
//  GameModel.swift
//  2048
//
//  Created by Александр Дергилёв on 14/06/2019.
//  Copyright © 2019 Александр Дергилёв. All rights reserved.
//

import UIKit

protocol GameModelProtocol: class {
    func scoreChange(score:Int)
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int)
    func moveTwoTile(from: (Int, Int), to: (Int, Int), value: Int)
    func isertTile(location: (Int, Int), value: Int)
}

class GameModel: NSObject {
    let dimension: Int
    let threshold: Int
    
    var score: Int = 0 {
        didSet {
            delegate.scoreChanged(score)
        }
    }
    var gameBoard: SquareGameBoard<TileObject>
    
    let delegate: GameModelProtocol
    
    var queue: [MoveCommand]
    var timer: Timer
    
    let maxCommands = 100
    let queueDelay = 0.3
    
    init(dimension d: Int, threshold t: Int, delegate: GameModelProtocol) {
        dimension = d
        threshold = t
        self.delegate = delegate
        queue = [MoveCommand]()
        timer = Timer()
        gameBoard = SquareGameBoard(dimension: d, initialValue: .Empty)
        super.init()
    }
    
    func reset() {
        score = 0
        gameBoard.setAll(.Empty)
        queue.removeAll(keepCapacity: true)
        timer.invalidate()
    }
    func queueMove(direction: MoveDirection, completion: (Bool) -> ()) {
        if queue.count > maxCommands {
            return
        }
        
        let command = MoveCommand(d: direction, c: completion)
        queue.append(command)
        if (!timer.isValid) {
            timerFired(timer)
        }
    }
    
    func timerFired(timer: Timer) {
        if queue.count == 0 {
            return
        }
        
        var changed = false
        while queue.count > 0 {
            let command = queue[0]
            queue.removeAtIndex(0)
            changed = preformMove(command.direction)
            command.completion(changed)
            if changed {
                break
            }
        }
        
        if changed {
            self.timer = Timer.scheduledTimer(timeInterval: queueDelay, target: self, selector: Selector("timerFired"), userInfo: nil, repeats: false)
        }
    }
}
