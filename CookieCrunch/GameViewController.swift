//
//  GameViewController.swift
//  CookieCrunch
//
//  Created by Dante on 15/7/30.
//  Copyright (c) 2015年 Futurelab. All rights reserved.
//

import UIKit
import SpriteKit

extension SKNode {
    class func unarchiveFromFile(file : String) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController {
    
    var scene: GameScene!
    var level: Level!
    
    func beginGame() {
        shuffle()
    }
    
    func shuffle() {
        var newCookies = level.shuffle()
        scene.addSpritesForCookies(newCookies)
    }
    
    func handleSwap(swap: Swap) {
        view.userInteractionEnabled = false
        
        if level.isPossibleSwap(swap) {
            level.performSwap(swap)
            scene.animateSwap(swap, completion: handleMatches)
        }
        else{
            scene.animateInvalidSwap(swap, completion: {
                self.view.userInteractionEnabled = true
            })
        }
    }
    
    func handleMatches() {
        let chains = level.removeMatches()
        
        if chains.isEmpty {
            beginNextTurn()
            return
        }
        
        scene.animateMatchedCookies(chains) {
            let cookies = self.level.fillHoles()
            self.scene.animateFallingCookies(cookies) {
                let columns = self.level.topUpCookies()
                self.scene.animateNewCookies(columns) {
                    self.handleMatches()
                }
            }
        }
    }
    
    func beginNextTurn() {
        level.detectPossibleSwaps()
        view.userInteractionEnabled = true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view.
        let skView = self.view as! SKView
        skView.multipleTouchEnabled = false
        
        // Create and configure the scene
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        scene.swapHandler = handleSwap
        
        skView.presentScene(scene)
        
        level = Level(filename: "Levels/Level_3")
        scene.level = level
        
        scene.addTiles()
        
        beginGame()
    }
}
