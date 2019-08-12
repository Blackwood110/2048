//
//  AuxModel.swift
//  2048
//
//  Created by Александр Дергилёв on 14/06/2019.
//  Copyright © 2019 Александр Дергилёв. All rights reserved.
//

import Foundation
enum MoveDirection {
    case Up
    case Down
    case Left
    case Right
}

struct MoveCommand {
    var direction: MoveDirection
    var completion: (Bool) -> ()
    init(d: MoveDirection, c: @escaping (Bool) -> ()) {
        direction = d
        completion = c
    }
}

enum MoveOrder {
    case SingleMoveOrder(source: Int, destination: Int, value: Int, wasMerge: Bool)
    case DoubleMoveOrder(firstSource: Int, secondSource: Int, destination: Int, value: Int)
}

enum TileObject {
    case Empty
    case Tile(Int)
}

enum ActionToken {
    case NoAction(source: Int, value: Int)
    case Move(source: Int, value: Int)
    case SingleCombine(source: Int, value: Int)
    case DoubleCombine(source: Int, second: Int, value: Int)
    
    func getValue() -> Int {
        switch self {
        case let .NoAction(source: _, value: v):
            return v
        case let .Move(source: _, value: v):
            return v
        case let.SingleCombine(source: _, value: v):
            return v
        case let .DoubleCombine(source: _, second: _, value: v):
            return v
        }
    }
    
    func getSource() -> Int {
        switch self {
        case let .NoAction(source: s, value: _):
            return s
        case let .Move(source: s, value: _):
            return s
        case let.SingleCombine(source: s, value: _):
            return s
        case let .DoubleCombine(source: s, second: _, value: _):
            return s
        }
    }
}

struct SquareGameBoard<T> {
    let dimension: Int
    var boardArray: [T]
    
    init(dimension d: Int, initialValue: T) {
        dimension = d
        boardArray = [T](count:d*d, repeatedValue: initialValue)
    }
    
    subscript(row: Int, col: Int) -> T {
        get {
            assert(row >= 0 && row < dimension)
            assert(col >= 0 && col < dimension)
            return boardArray[row*dimension + col]
        }
        set {
            assert(row >= 0 && row < dimension)
            assert(col >= 0 && col < dimension)
            boardArray[row*dimension + col] = newValue
        }
    }
    
    mutating func setAll(item: T) {
        for i in 0..<dimension {
            for j in 0..<dimension {
                self[i, j] = item
            }
        }
    }
}
