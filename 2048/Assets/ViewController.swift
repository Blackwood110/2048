//
//  ViewController.swift
//  2048
//
//  Created by Александр Дергилёв on 14/06/2019.
//  Copyright © 2019 Александр Дергилёв. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func startGameButtonTapped(sender: UIButton) {
        let game = NumberTileGameViewController(dimension: 4, threshold: 2048)
        self.present(game, animated: true, completion: nil)
    }
}

