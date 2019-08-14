//
//  GameModel.swift
//  2048
//
//  Created by Александр Дергилёв on 14/06/2019.
//  Copyright © 2019 Александр Дергилёв. All rights reserved.
//

import UIKit

// Протокол, устанавливающий взаимодействие игровой модели со своим контроллером
protocol GameModelProtocol: class {
    func scoreChanged(to score: Int)
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int)
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int)
    func insertTile(at location: (Int, Int), withValue value: Int)
}

// Класс, представляющий игровое состояние и логику 2048. Он пренадлежит контроллеру представления NumberTileGame
class GameModel: NSObject {
    let dimension: Int
    let threshold: Int
    
    var score: Int = 0 {
        didSet {
            delegate.scoreChanged(to: score)
        }
    }
    var gameboard: SquareGameboard<TileObject>
    
    unowned let delegate: GameModelProtocol
    
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
        gameboard = SquareGameboard(dimension: d, initialValue: .empty)
        super.init()
    }
    
    // Сбросить состояние игры
    func reset() {
        score = 0
        gameboard.setAll(to: .empty)
        queue.removeAll(keepingCapacity: true)
        timer.invalidate()
    }
    
    // Очередь вызывает задержку в несколько миллисекунд перед каждым свайпом
    func queueMove(direction: MoveDirection, onCompletion: @escaping (Bool) -> ()) {
        guard queue.count <= maxCommands else {
            // Очередь заклинена. Такого не должно быть на практике.
            return
        }
        queue.append(MoveCommand(direction: direction, completion: onCompletion))
        if !timer.isValid {
            // Таймер не работает, поэтому надо его запустить
            timerFired(timer)
        }
    }
    
    // Сообщает игровой модели, что таймер задержки хода сработал. Как только таймер срабатывает, игра пытается выполнить ход, меняющий состояние игры
    @objc
    func timerFired(_: Timer) {
        if queue.count == 0 {
            return
        }
        // Пройти очередь, пока не будет выполнена правильная команда или очередь не будет пустой
        var changed = false
        while queue.count > 0 {
            let command = queue[0]
            queue.remove(at: 0)
            changed = performMove(direction: command.direction)
            command.completion(changed)
            if changed {
                // если команда ничего не меняет, мы запускаем следующую
                break
            }
        }
        if changed {
            timer = Timer.scheduledTimer(timeInterval: queueDelay, target: self, selector: #selector(GameModel.timerFired(_:)), userInfo: nil, repeats: false)
        }
    }
    
    // Вставить плитку с заданым значением в заданную позицию
    func insertTile(at location: (Int, Int), value: Int) {
        let (x, y) = location
        if case .empty = gameboard[x, y] {
            gameboard[x, y] = TileObject.tile(value)
            delegate.insertTile(at: location, withValue: value)
        }
    }
    // Вставить плитку с заданым значением в случайную свободную позицию
    func insertTileAtRandomLocation(withValue value: Int) {
        let openSpots = gameboardEmptySpots()
        if openSpots.isEmpty {
            // Больше нет свободных мест на поле
            return
        }
        // Случайный выбор свободной позиции и помещение туда новой плитки
        let idx = Int(arc4random_uniform(UInt32(openSpots.count-1)))
        let (x, y) = openSpots[idx]
        insertTile(at: (x, y), value: value)
    }
    
    // Возвращает список кортежей пустых мест на доске.
    func gameboardEmptySpots() -> [(Int, Int)] {
        var buffer: [(Int, Int)] = []
        for i in 0..<dimension {
            for j in 0..<dimension {
                if case .empty = gameboard[i, j] {
                    buffer += [(i, j)]
                }
            }
        }
        return buffer
    }
    
    func tileBelowHasSameValue(location: (Int, Int), value: Int) -> Bool {
        let (x,y) = location
        guard y != dimension - 1 else {
            return false
        }
        if case let .tile(v) = gameboard[x, y+1] {
            return v == value
        }
        return false
    }
    
    func tileToRightHasSameValue(location: (Int,Int), value: Int) -> Bool {
        let (x,y) = location
        guard x != dimension - 1 else {
            return false
        }
        if case let .tile(v) = gameboard[x+1, y] {
            return v == value
        }
        return false
    }
    
    func userHasLost() -> Bool {
        guard gameboardEmptySpots().isEmpty else {
            // Пользователь не может проиграть прежде, чем заполнит все поля
            return false
        }
        // Пробежать все плитки и проверить возможные ходы
        for i in 0..<dimension {
            for j in 0..<dimension {
                switch gameboard[i,j] {
                case .empty:
                    assert(false, "Доска сообщила, что заполнена, но мы нашли пустую клетку.")
                case let .tile(v):
                    if tileBelowHasSameValue(location: (i,j), value: v) || tileToRightHasSameValue(location: (i,j), value: v) {
                        return false
                    }
                }
            }
        }
        return true
    }
    
    func userHasWon() -> (Bool, (Int, Int)?) {
        for i in 0..<dimension {
            for j in 0..<dimension {
                // Поиск клетки с победным счетом или более
                if case let .tile(v) = gameboard[i, j], v >= threshold {
                    return (true, (i, j))
                }
            }
        }
        return (false, nil)
    }
    
    // Выполнить все расчеты и обновить состояние за один ход
    func performMove(direction: MoveDirection) -> Bool {
        // Подготовить закрытие генератора. Это закрытие отличается по поведению в зависимости от направления движения
        // Это используется методом для генерации списка ячеек, которые нужно изменить.
        // В зависимости от этого направления можем предоставлять одну строку или один столбец в любом направлении.
        let coordinateGenerator: (Int) -> [(Int, Int)] = { (iteration: Int) -> [(Int, Int)] in
            var buffer = Array<(Int, Int)>(repeating: (0, 0), count: self.dimension)
            for i in 0..<self.dimension {
                switch direction {
                case .up: buffer[i] = (i, iteration)
                case .down: buffer[i] = (self.dimension-i-1, iteration)
                case .left: buffer[i] = (iteration,i)
                case .right: buffer[i] = (iteration, self.dimension-i-1)
                }
            }
            return buffer
        }
        
        var atLeastOneMove = false
        for i in 0..<dimension {
            // Получить список координат
            let coords = coordinateGenerator(i)
            // Получить соотсветсвующий список ячеек.
            let tiles = coords.map() { (c: (Int, Int)) -> TileObject in
                let (x,y) = c
                return self.gameboard[x,y]
            }
            // Выполнить операцию
            let orders = merge(tiles)
            atLeastOneMove = orders.count > 0 ? true : atLeastOneMove
            // Вывести результаты
            for object in orders {
                switch object {
                case let MoveOrder.singleMoveOrder(s, d, v, wasMerge):
                    // выполнить движение одной ячейки
                    let (sx, sy) = coords[s]
                    let (dx,dy) = coords[d]
                    if wasMerge {
                        score += v
                    }
                    gameboard[sx,sy] = TileObject.empty
                    gameboard[dx, dy] = TileObject.tile(v)
                    delegate.moveOneTile(from: coords[s], to: coords[d], value: v)
                case let MoveOrder.doubleMoveOrder(s1, s2, d, v):
                    // выполнить одновременное движение двух плиток
                    let (s1x, s1y) = coords[s1]
                    let (s2x, s2y) = coords[s2]
                    let (dx,dy) = coords[d]
                    score += v
                    gameboard[s1x,s1y] = TileObject.empty
                    gameboard[s2x,s2y] = TileObject.empty
                    gameboard[dx, dy] = TileObject.tile(v)
                    delegate.moveTwoTiles(from: (coords[s1], coords[s2]), to: coords[d], value: v)
                }
            }
        }
        return atLeastOneMove
    }
    
    // при вычислении эффектов от перемещения по ряду плиток, рассчитать и вернуть список действий,
    // необхоодимых для удаления пустого пространстава между ячейками
    func condense(_ group: [TileObject]) -> [ActionToken] {
        var tokenBuffer = [ActionToken]()
        for (idx, tile) in group.enumerated() {
            // Пройти все плитки в группе. Когда видишь плитку не на своем месте, создать соответсвующее действие
            switch tile {
            case let .tile(value) where tokenBuffer.count == idx:
                tokenBuffer.append(ActionToken.noAction(source: idx, value: value))
            case let .tile(value):
                tokenBuffer.append(ActionToken.move(source: idx, value: value))
            default:
                break
            }
        }
        return tokenBuffer
    }
    
    class func quiescentTileStillQuiescent(inputPosition: Int, outputLength: Int, originalPosition: Int) -> Bool {
        // Вернуть представляет ли действие неподвижную ячейку
        return (inputPosition == outputLength) && (originalPosition == inputPosition)
    }
    
    // При вычислении эффектов перемещения плиток рассчитать и вернуть обновленный список действий, соответсвующий любым слияниям
    // Ётот метод соединяет плитки одинакового значения, но каждая плитка может быть использована лишь раз
    func collapse(_ group: [ActionToken]) -> [ActionToken] {
        var tokenBuffer = [ActionToken]()
        var skipNext = false
        for (idx, token) in group.enumerated() {
            if skipNext {
                // Предыдущая операция обработала слияние, так что пропустить эту операцию
                skipNext = false
                continue
            }
            switch token {
            case .singleCombine:
                assert(false, "Cannot have single combine token in input")
            case .doubleCombine:
                assert(false, "Cannot have double combine token in input")
            case let .noAction(s,v)
                where (idx < group.count-1
                    && v == group[idx+1].getValue()
                    && GameModel.quiescentTileStillQuiescent(inputPosition: idx, outputLength: tokenBuffer.count, originalPosition: s)):
                // это плитка еще не перемещена, но соответствует следующей плитке. Э то единственное слияниен
                let next = group[idx+1]
                let nv = v + group[idx+1].getValue()
                skipNext = true
                tokenBuffer.append(ActionToken.singleCombine(source: next.getSource(), value: nv))
            case let t where (idx < group.count-1 && t.getValue() == group[idx+1].getValue()):
                // эта плитка перемещена и соответствует следующей плитке, это двойное слияние.
                let next = group[idx+1]
                let nv = t.getValue() + group[idx+1].getValue()
                skipNext = true
                tokenBuffer.append(ActionToken.doubleCombine(source: t.getSource(), second: next.getSource(), value: nv))
            case let .noAction(s,v) where !GameModel.quiescentTileStillQuiescent(inputPosition: idx, outputLength: tokenBuffer.count, originalPosition: s):
                // Плитка, которая не двигалась раньше, переместилась( первое условие) или произошло двойное слияние( второе условие)
                tokenBuffer.append(ActionToken.move(source: s, value:v))
            case let .noAction(s,v):
                // Плитка, которая раньше не двигалась, еще не сдвинулась
                tokenBuffer.append(ActionToken.noAction(source: s, value: v))
            case let .move(s,v):
                // распространять ход
                tokenBuffer.append(ActionToken.move(source: s, value:v))
            default:
                break
            }
        }
        return tokenBuffer
    }
    
    // преобразование результатов выполения двух методов, для возвращения их делегату
    func convert(_ group: [ActionToken]) -> [MoveOrder] {
        var moveBuffer = [MoveOrder]()
        for (idx, t) in group.enumerated() {
            switch t {
            case let .move(s,v):
                moveBuffer.append(MoveOrder.singleMoveOrder(source: s, destination: idx, value: v, wasMerge: false))
            case let .singleCombine(s,v):
                moveBuffer.append(MoveOrder.singleMoveOrder(source:s, destination:idx, value:v, wasMerge: true))
            case let .doubleCombine(s1,s2,v):
                moveBuffer.append(MoveOrder.doubleMoveOrder(firstSource:s1, secondSource:s2, destination: idx, value: v))
            default:
                break
            }
        }
        return moveBuffer
    }
    
    // Используя массив TileObject выполнить свертывание и созать массив порядков перемещения
    func merge(_ group: [TileObject]) -> [MoveOrder] {
        // Расчет происходит в три этапа
        // 1. Рассчитать ходы, необходимые для создания тех же плиток, но без какого-либо пространства между ними.
        // 2. Рассчитать ходы, необходимые для соединения одинаковых плиток.
        // 3. Преобразовать всю информацию о действиях для делегата
        return convert(collapse(condense(group)))
    }
}
