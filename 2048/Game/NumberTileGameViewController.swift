//
//  GameViewController.swift
//  2048
//
//  Created by Александр Дергилёв on 12/08/2019.
//  Copyright © 2019 Александр Дергилёв. All rights reserved.
//

import UIKit

// Контроллер представления, для связывания модели и вьюшки.
// Поток данных работает следующим образом: пользовательский ввод достигает контроллера и передается в модель.
// расчеты, вычисленные моделью возвращаются в контроллер и перенаправляются в вьюшки для обновления своего состояния
class NumberTileGameViewController: UIViewController, GameModelProtocol {
    // сколько плиток в обоих направлениях содержит игровая доска
    var dimension: Int
    // значение выигршыной плитки
    var threshold: Int
    
    var board: GameboardView?
    var model: GameModel?
    
    var scoreView: ScoreViewProtocol?
    // ширина игрового поля
    let boardWidth: CGFloat = 230.0
    // расстояние между плитками
    let thinPadding: CGFloat = 3.0
    let thickPadding: CGFloat = 6.0
    // Растояние между различными элементами
    let viewPadding: CGFloat = 10.0
    
    let verticalViewOffset: CGFloat = 0.0
    
    init(dimension d: Int, threshold t: Int) {
        dimension = d > 2 ? d : 2
        threshold = t > 8 ? t : 8
        super.init(nibName: nil, bundle: nil)
        model = GameModel(dimension: dimension, threshold: threshold, delegate: self)
        view.backgroundColor = .white
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
        // эта вложенная функция, обеспечивает Х-позицию для вида компонента
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
            
            // Не знаю, как нарезать массив еще
            var acc: CGFloat = 0
            for i in 0..<order {
                acc += viewPadding + views[i].bounds.size.height
            }
            return viewsTop + acc
        }
        // создать представление счета
        let scoreView = ScoreView(backgroundColor: .black, textColor: .white, font: .systemFont(ofSize: 16.0), radius: 6)
        scoreView.score = 0
        // создать игровую доску
        let padding: CGFloat = dimension > 5 ? thinPadding : thickPadding
        let v1 = boardWidth - padding*(CGFloat(dimension + 1))
        let width: CGFloat = CGFloat(v1)/CGFloat(dimension)
        let gameboard = GameboardView(dimension: dimension,
                                      tileWidth: width,
                                      tilePadding: padding,
                                      cornerRadius: 6,
                                      backgroundColor: .black,
                                      foregroundColor: .darkGray)
        //установить рамки
        let views = [scoreView, gameboard]
        
        var f = scoreView.frame
        f.origin.x = xPositionToCenterView(v: scoreView)
        f.origin.y = yPositionForViewAtPosition(order: 0, views: views)
        scoreView.frame = f
        
        f = gameboard.frame
        f.origin.x = xPositionToCenterView(v: gameboard)
        f.origin.y = yPositionForViewAtPosition(order: 1, views: views)
        gameboard.frame = f
        // добавить в состояние игры
        view.addSubview(gameboard)
        board = gameboard
        view.addSubview(scoreView)
        self.scoreView = scoreView
        
        guard let m = model else {
            return
        }
        m.insertTileAtRandomLocation(withValue: 2)
        m.insertTileAtRandomLocation(withValue: 2)
    }
    
    func followUp() {
        guard let m = model else {
            return
        }
        let (userWon, _) = m.userHasWon()
        if userWon {
            // TODO: добавить делегат "вы выиграли"
            let alertView = UIAlertView()
            alertView.title = "Victory"
            alertView.message = "Youw won!"
            alertView.addButton(withTitle: "Cancel")
            alertView.show()
            // TODO: здесь необходимо остановить игру, пока пользователь не нажмет "новая игра"
            return
        }
        
        // вставляем значения плиток
        let randomVal = Int(arc4random_uniform(10))
        m.insertTileAtRandomLocation(withValue: randomVal == 1 ? 4 : 2)
        // в этот момент пользователь может проиграть
        if m.userHasLost() {
            // TODO: алерт делегат вы проиграли
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
        guard let m = model else {
            return
        }
        m.queueMove(direction: MoveDirection.up, onCompletion: { changed in
            if changed {
                self.followUp()
            }
        })
    }
    
    @objc(down:)
    func downCommand(_ r: UIGestureRecognizer!) {
        guard let m = model else {
            return
        }
        m.queueMove(direction: MoveDirection.down, onCompletion: { changed in
            if changed {
                self.followUp()
            }
        })
    }
    
    @objc(left:)
    func leftCommand(_ r: UIGestureRecognizer!) {
        guard let m = model else {
            return
        }
        m.queueMove(direction: MoveDirection.left, onCompletion: { changed in
            if changed {
                self.followUp()
            }
        })
    }
    
    @objc(right:)
    func rightCommand(_ r: UIGestureRecognizer!) {
        guard let m = model else {
            return
        }
        m.queueMove(direction: MoveDirection.right, onCompletion: { changed in
            if changed {
                self.followUp()
            }
        })
    }
    func scoreChanged(to score: Int) {
        guard let s = scoreView else {
            return
        }
        s.scoreChanged(to: score)
    }
    
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int) {
        guard let b = board else {
            return
        }
        b.moveOneTile(from: from, to: to, value: value)
    }
    
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int) {
        guard let b = board else {
            return
        }
        b.moveTwoTiles(from: from, to: to, value: value)
    }
    
    func insertTile(at location: (Int, Int), withValue value: Int) {
        guard let b = board else {
            return
        }
        b.insertTile(at: location, value: value)
    }
}
