//
//  GameViewController.swift
//  CookieCrunch
//
//  Created by Dante on 15/7/30.
//  Copyright (c) 2015年 Futurelab. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

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
    
    var movesLeft = 0
    var score = 0
    
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var movesLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var gameoverPanel: UIImageView!
    @IBOutlet weak var shuffleButton: UIButton!
    
    var tapGestureRecognizer: UITapGestureRecognizer!
    
    lazy var backgroundMusic: AVAudioPlayer = {
        let url = NSBundle.mainBundle().URLForResource("Sounds/Mining by Moonlight", withExtension: "mp3")
        let player = AVAudioPlayer(contentsOfURL: url, error: nil)
        player.numberOfLoops = -1
        return player
    }()


    @IBAction func shuffleButtonPressed(sender: UIButton) {
        shuffle()
        decreaseMoves()
    }
    
    func beginGame() {
        movesLeft = level.maximumMoves
        score = 0
        updateLabels()
        level.resetComboMultipler()
        
        scene.animateBeginGame() {
            self.shuffleButton.hidden = false
        }
        
        shuffle()
    }
    
    func shuffle() {
        scene.removeAllCookieSprites()
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
            
            for chain in chains {
                self.score += chain.score
            }
            
            self.updateLabels()
            
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
        level.resetComboMultipler()
        updateLabels()
        view.userInteractionEnabled = true
        decreaseMoves()
    }
    
    func updateLabels() {
        targetLabel.text = String(format: "%1d", self.level.targetScore)
        movesLabel.text = String(format: "%1d", self.movesLeft)
        scoreLabel.text = String(format: "%1d", self.score)
    }
    
    func decreaseMoves() {
        --movesLeft
        updateLabels()
        
        if score >= level.targetScore {
            gameoverPanel.image = UIImage(named: "LevelComplete")
            showGameover()
        }
        else if movesLeft <= 0{
            gameoverPanel.image = UIImage(named: "GameOver")
            showGameover()
        }
    }
    
    func showGameover() {
        gameoverPanel.hidden = false
        scene.userInteractionEnabled = false
        
        shuffleButton.hidden = true
        
        scene.animateGameOver() {
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "hideGameover")
            self.view.addGestureRecognizer(self.tapGestureRecognizer)
        }
    }
    
    func hideGameover() {
        view.removeGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = nil
        
        gameoverPanel.hidden = true
        scene.userInteractionEnabled = true
        
        beginGame()
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
        
        gameoverPanel.hidden = true
        
        skView.presentScene(scene)
        
        level = Level(filename: "Levels/Level_3")
        scene.level = level
        
        scene.addTiles()

        backgroundMusic.play()
        
        beginGame()
    }
}