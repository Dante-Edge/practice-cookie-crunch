//
//  GameScene.swift
//  CookieCrunch
//
//  Created by Dante on 15/7/30.
//  Copyright (c) 2015年 Futurelab. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    var level: Level!
    
    let TileWidth: CGFloat = 32.0
    let TileHeight: CGFloat = 36.0
    
    let gameLayer = SKNode()
    let cookieLayer = SKNode()
    let tileLayer = SKNode()
    let selectionSprite = SKSpriteNode()
    let cropLayer = SKCropNode()
    let maskLayper = SKNode()
    
    var swipeFromColumn: Int?
    var swipeFromRow: Int?
    
    var swapHandler: ((Swap) -> ())?
    
    let swapSound = SKAction.playSoundFileNamed("Sounds/Chomp.wav", waitForCompletion: false)
    let invalidSwapSound = SKAction.playSoundFileNamed("Sounds/Error.wav", waitForCompletion: false)
    let matchSound = SKAction.playSoundFileNamed("Sounds/Ka-Ching.wav", waitForCompletion: false)
    let fallingCookieSound = SKAction.playSoundFileNamed("Sounds/Scrape.wav", waitForCompletion: false)
    let addCookieSound = SKAction.playSoundFileNamed("Sounds/Drip.wav", waitForCompletion: false)
    
    // MARK: Initializers
    
    required init?(coder aDecoder: NSCoder){
        fatalError("init(coder) is not used in this app.")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        let background = SKSpriteNode(imageNamed: "Background")
        addChild(background)
        
        addChild(gameLayer)
        let layerPosition = CGPoint(
            x: -TileWidth * CGFloat(NumColumns) / 2,
            y: -TileHeight * CGFloat(NumRows) / 2)
        
        tileLayer.position = layerPosition
        gameLayer.addChild(tileLayer)
        
        gameLayer.addChild(cropLayer)
        maskLayper.position = layerPosition
        cropLayer.maskNode = maskLayper
        
        cookieLayer.position = layerPosition
        cropLayer.addChild(cookieLayer)
        gameLayer.hidden = true
        
        swipeFromColumn = nil
        swipeFromRow = nil
        
        SKLabelNode(fontNamed: "GillSans-BoldItalic")
    }
    
    // MARK: Basic fundation
    func addSpritesForCookies(cookies: Set<Cookie>) {
        for cookie in cookies {
            let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
            sprite.alpha = 0
            sprite.xScale = 0.5
            sprite.yScale = 0.5

            sprite.position = pointForColumn(cookie.column, row: cookie.row)
            cookieLayer.addChild(sprite)
            cookie.sprite = sprite
            
            sprite.runAction(SKAction.sequence([
                SKAction.waitForDuration(0.25, withRange: 0.5),
                SKAction.group([
                    SKAction.fadeInWithDuration(0.25),
                    SKAction.scaleTo(1.0, duration: 0.25)])]))
        }
    }
    
    func pointForColumn(column: Int, row: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(column) * TileWidth + TileWidth / 2,
            y: CGFloat(row) * TileHeight + TileHeight / 2)
    }
    
    func convertPoint(point: CGPoint) -> (success: Bool, column: Int, row: Int) {
        if point.x >= 0 && point.x <= CGFloat(NumColumns) * TileWidth &&
            point.y >= 0 && point.y <= CGFloat(NumRows) * TileHeight {
                return (true, Int(point.x / TileWidth), Int(point.y / TileHeight))
        }
        else {
            return (false, 0, 0)
        }
    }
    
    func addTiles() {
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if let tile = level.tileAtColumn(column, row:row) {
                    let tileNode = SKSpriteNode(imageNamed: "MaskTile")
                    tileNode.position = pointForColumn(column, row: row)
                    maskLayper.addChild(tileNode)
                }
            }
        }
        
        for row in 0...NumRows {
            for column in 0...NumColumns {
                let topLeft = (column > 0 && row < NumRows) && (level.tileAtColumn(column - 1, row: row) != nil)
                let topRight = (column < NumColumns && row < NumRows) && (level.tileAtColumn(column, row: row) != nil)
                let bottomLeft = (column > 0 && row > 0) && (level.tileAtColumn(column - 1, row: row - 1) != nil)
                let bottomRight = (column < NumColumns && row > 0) && (level.tileAtColumn(column, row: row - 1) != nil)
                
                let value = Int(topLeft) | Int(topRight) << 1 | Int(bottomLeft) << 2 | Int(bottomRight) << 3
                
                if value != 0 && value != 6 && value != 9 {
                    let tileNode = SKSpriteNode(imageNamed: String(format: "Tile_%ld", value))
                    var point = pointForColumn(column, row: row)
                    point.x -= TileWidth / 2
                    point.y -= TileHeight / 2
                    tileNode.position = point
                    tileLayer.addChild(tileNode)
                }
            }
        }
    }
    
    func removeAllCookieSprites () {
        cookieLayer.removeAllChildren()
    }
    
    // MARK: Touch event handers
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as! UITouch
        let location = touch.locationInNode(cookieLayer)
        
        let (success, column, row) = convertPoint(location)
        
        if success {
            if let cookie = level.cookieAtColumn(column, row: row) {
                self.swipeFromColumn = column
                self.swipeFromRow = row
                showSelectionIndicatorForCookie(cookie)
            }
        }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        if self.swipeFromColumn == nil { return }
        
        let touch = touches.first as! UITouch
        let location = touch.locationInNode(cookieLayer)
        
        let (success, column, row) = convertPoint(location)
        
        if success {
            var horzDelta = 0, vertDelta = 0
            
            if column < self.swipeFromColumn {
                horzDelta = -1                          // Left
            } else if column > self.swipeFromColumn {
                horzDelta = 1                           // Right
            } else if row < self.swipeFromRow {
                vertDelta = -1                          // Down
            } else if row > self.swipeFromRow {
                vertDelta = 1                           // Up
            }

            if horzDelta != 0 || vertDelta != 0 {
                trySwapHorizontal(horzDelta, vertical: vertDelta)
                hideSelectionIndicator()
                swipeFromColumn = nil
            }
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        if selectionSprite.parent != nil && self.swipeFromColumn != nil {
            hideSelectionIndicator()
        }
        self.swipeFromColumn = nil
        self.swipeFromRow = nil
    }
    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        touchesEnded(touches, withEvent: event)
    }
    
    func trySwapHorizontal(horzDelta: Int, vertical vertDelta: Int) {
        let toColumn = swipeFromColumn! + horzDelta
        let toRow = swipeFromRow! + vertDelta
        
        if toColumn < 0 || toColumn >= NumColumns || toRow < 0 || toRow >= NumRows { return }
        
        if let toCookie = level.cookieAtColumn(toColumn, row: toRow) {
            if let fromCookie = level.cookieAtColumn(swipeFromColumn!, row: swipeFromRow!) {
                
                if let handler = swapHandler {
                    let swap = Swap(cookieA: fromCookie, cookieB: toCookie)
                    handler(swap)
                }

            }
        }
    }
    
    // MARK: Animations
    
    func animateSwap(swap: Swap, completion: () -> ()) {
        let spriteA = swap.cookieA.sprite!
        let spriteB = swap.cookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let Duration: NSTimeInterval = 0.3
        
        let moveA = SKAction.moveTo(spriteB.position, duration: Duration)
        moveA.timingMode = .EaseOut
        spriteA.runAction(moveA, completion: completion)
        
        let moveB = SKAction.moveTo(spriteA.position, duration: Duration)
        moveB.timingMode = .EaseOut
        spriteB.runAction(moveB)
        
        runAction(swapSound)
    }
    
    func animateInvalidSwap(swap: Swap, completion: () -> ()) {
        let spriteA = swap.cookieA.sprite!
        let spriteB = swap.cookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let Duration: NSTimeInterval = 0.2
        
        let moveA = SKAction.moveTo(spriteB.position, duration: Duration)
        moveA.timingMode = .EaseOut
        
        let moveB = SKAction.moveTo(spriteA.position, duration: Duration)
        moveB.timingMode = .EaseOut
        
        spriteA.runAction(SKAction.sequence([moveA, moveB]), completion: completion)
        spriteB.runAction(SKAction.sequence([moveB, moveA]))
        
        runAction(invalidSwapSound)
    }
    
    func showSelectionIndicatorForCookie(cookie: Cookie) {
        if selectionSprite.parent != nil {
            selectionSprite.removeFromParent()
        }
        
        if let sprite = cookie.sprite {
            let texture = SKTexture(imageNamed: cookie.cookieType.hightlightedSpriteName)
            selectionSprite.size = texture.size()
            selectionSprite.runAction(SKAction.setTexture(texture))
            
            sprite.addChild(selectionSprite)
            selectionSprite.alpha = 1.0
        }
    }
    
    func hideSelectionIndicator() {
        selectionSprite.runAction(SKAction.sequence([
            SKAction.fadeOutWithDuration(0.3),
            SKAction.removeFromParent()]))
    }
    
    func animateMatchedCookies(chains: Set<Chain>, completion: () -> ()){
        for chain in chains {
            animateScoreForChain(chain)
            for cookie in chain.cookies {
                if let sprite = cookie.sprite {
                    if sprite.actionForKey("removing") == nil {
                        let scaleAction = SKAction.scaleTo(0.1, duration: 0.3)
                        scaleAction.timingMode = .EaseOut
                        sprite.runAction(SKAction.sequence([scaleAction, SKAction.removeFromParent()]), withKey: "removing")
                    }
                }
            }
        }
        
        runAction(matchSound)
        runAction(SKAction.waitForDuration(0.3), completion: completion)
    }
    
    func animateFallingCookies(cookies: [[Cookie]], completion: () -> ()) {
        var longestDuration: NSTimeInterval = 0
        
        for array in cookies {
            for (idx, cookie) in enumerate(array) {
                let sprite = cookie.sprite!
                let targetPosition = pointForColumn(cookie.column, row: cookie.row)
                let duration = NSTimeInterval((sprite.position.y - targetPosition.y) / TileHeight * 0.1)
                let delay = NSTimeInterval(0.05 + 0.15 * Double(idx))
                
                longestDuration = max(longestDuration, duration + delay)
                
                let moveAction = SKAction.moveTo(targetPosition, duration: duration)
                moveAction.timingMode = .EaseOut
                
                sprite.runAction(
                    SKAction.sequence([
                        SKAction.waitForDuration(delay),
                        SKAction.group([moveAction, fallingCookieSound])]))
            }
        }
        
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }
    
    func animateNewCookies(columns: [[Cookie]],  completion: () -> ()) {
        var longestDuration: NSTimeInterval = 0
        
        for column in columns {
            let startRow = column.first!.row + 1
            for (idx, cookie) in enumerate(column) {
                let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
                sprite.position = pointForColumn(cookie.column, row: startRow)
                sprite.alpha = 0
                cookieLayer.addChild(sprite)
                cookie.sprite = sprite
                
                var delay = NSTimeInterval(0.1 + 0.2 * Double(column.count - idx - 1))
                var duration = NSTimeInterval(startRow - cookie.row) * 0.1
                
                longestDuration = max(longestDuration, duration + delay)
                
                let actionMove = SKAction.moveTo(pointForColumn(cookie.column, row: cookie.row), duration: duration)
                actionMove.timingMode = .EaseOut
                
                sprite.runAction(SKAction.sequence([
                    SKAction.waitForDuration(delay),
                    SKAction.group([actionMove, SKAction.fadeInWithDuration(0.05), addCookieSound])]))
            }
        }
        
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }
    
    func animateScoreForChain(chain: Chain) {
        let firstSprite = chain.firstCookie().sprite!
        let lastSprite = chain.lastCookie().sprite!
        
        let centerPosition = CGPoint(
            x: (firstSprite.position.x + lastSprite.position.x) / 2,
            y: (firstSprite.position.y + lastSprite.position.y) / 2 - 8)
        
        let scoreLabel = SKLabelNode(fontNamed: "GillSans-BoldItalic")
        scoreLabel.fontSize = 16
        scoreLabel.text = String(format: "%1d", chain.score)
        scoreLabel.position = centerPosition
        scoreLabel.zPosition = 300
        cookieLayer.addChild(scoreLabel)
        
        let moveAction = SKAction.moveBy(CGVector(dx: 0, dy: 3), duration: 0.7)
        moveAction.timingMode = .EaseOut
        
        scoreLabel.runAction(SKAction.sequence([moveAction, SKAction.fadeOutWithDuration(0.3),  SKAction.removeFromParent()]))
    }
    
    func animateGameOver(completion: () -> ()) {
        let action = SKAction.moveBy(CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .EaseIn
        gameLayer.runAction(action, completion: completion)
    }
    
    func animateBeginGame(completion: () -> ()) {
        gameLayer.hidden = false
        gameLayer.position = CGPoint(x: 0, y: size.height)
        
        let action = SKAction.moveBy(CGVector(dx:0, dy: -size.height), duration: 0.3)
        action.timingMode = .EaseOut
        gameLayer.runAction(action, completion: completion)
    }
}