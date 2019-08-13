//
//  AuxModel.swift
//  2048
//
//  Created by Александр Дергилёв on 14/06/2019.
//  Copyright © 2019 Александр Дергилёв. All rights reserved.
//

import Foundation

enum MoveDirection {
    case up, down, left, right
}

struct MoveCommand {
    var direction: MoveDirection
    let completion: (Bool) -> ()
}

enum MoveOrder {
    case singleMoveOrder(source: Int, destination: Int, value: Int, wasMerge: Bool)
    case doubleMoveOrder(firstSource: Int, secondSource: Int, destination: Int, value: Int)
}

enum TileObject {
    case empty
    case tile(Int)
}

enum ActionToken {
    case noAction(source: Int, value: Int)
    case move(source: Int, value: Int)
    case singleCombine(source: Int, value: Int)
    case doubleCombine(source: Int, second: Int, value: Int)
    
    func getValue() -> Int {
        switch self {
        case let .noAction(source: _, value: v): return v
        case let .move(source: _, value: v): return v
        case let .singleCombine(source: _, value: v): return v
        case let .doubleCombine(source: _, second: _, value: v): return v
        }
    }
    
    func getSource() -> Int {
        switch self {
        case let .noAction(source: s, value: _): return s
        case let .move(source: s, value: _): return s
        case let .singleCombine(source: s, value: _): return s
        case let .doubleCombine(source: s, second: _, value: _): return s
        }
    }
}

struct SquareGameboard<T> {
    let dimension: Int
    var boardArray: [T]
    
    init(dimension d: Int, initialValue: T) {
        dimension = d
        boardArray = [T](repeating: initialValue, count: d*d)
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
    
    mutating func setAll(to item: T) {
        for i in 0..<dimension {
            for j in 0..<dimension {
                self[i, j] = item
            }
        }
    }
}
