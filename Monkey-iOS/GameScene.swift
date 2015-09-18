//
//  GameScene.swift
//  Monkey
//
//  Created by Nikolaos Kechagias on 20/08/15.
//  Copyright (c) 2015 Nikolaos Kechagias. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    /* 1 */
    let soundGameOver = SKAction.playSoundFileNamed("GameOver.m4a", waitForCompletion: false)
    let soundMessage = SKAction.playSoundFileNamed("Message.m4a", waitForCompletion: false)
    let soundBanana = SKAction.playSoundFileNamed("Banana.m4a", waitForCompletion: false)
    let soundJump = SKAction.playSoundFileNamed("Jump.m4a", waitForCompletion: false)
    
    
    // Helpful variables for the scrolling
    var delta = 0.0
    var lastUpdate = 0.0
    
    var backgroundLayer = SKNode()
    let backgroundSpeed = 50.0    // Speed of the foreground layer
    
    var cloudsLayer = SKNode()
    let cloudsSpeed = 60.0    // Speed of the clouds layer
    
    var foregroundLayer = SKNode()
    let foregroundSpeed = 250.0    // Speed of the foreground layer
    
    var monkey = SKSpriteNode() // Image of the monkey
    
    var isJumping = false
    
    var gameState = GameState.Ready
    
    /* 1 */
    var distanceLabel = LabelNode(fontNamed: "Gill Sans Bold Italic") // See Page 57 in Chapter 3
    /* 2 */
    var distance: Int = 0 {
        didSet {
            /* 3 */
            if distance > best {
                best = distance
            }
            /* 4 */
            distanceLabel.text = "Distance: \(distance)"
        }
    }
    
    /* 5 */
    var bestDistanceLabel = LabelNode(fontNamed: "Gill Sans Bold Italic") // See Page 57 in Chapter 3
    /* 6 */
    var best: Int = 0 {
        didSet {
            /* 7 */
            bestDistanceLabel.text = "Best: \(best)"
        }
    }

    override func didMoveToView(view: SKView) {
        /* Init Physics World */
        initPhysicsWorld()
        
        /* Init Background */
        initBackground()
        
        /* Init Clouds */
        initClouds()
        
        /* Load Level */
        loadLevel("Level1.json")
        
        /* Add Monkey */
        addMonkey()
       
        /* Monkey Run */
       // monkeyRun()
        
        /* Add HUD */
        addHUD()
        
        /* Show Message: Start Game */
        showMessage("StartGame")
    }
    
    
    // MARK: - Init Physics World
    func initPhysicsWorld() {
        /* 1 */
        physicsWorld.gravity = CGVectorMake(0, -20)
        
        /* 2 */
        physicsWorld.contactDelegate = self
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        if gameState != GameState.Playing {
            return
        }
        
        /* 1 */
        let catA = contact.bodyA.categoryBitMask;
        let catB = contact.bodyB.categoryBitMask;
        
        
        if catA == ColliderCategory.Grass.rawValue || catB == ColliderCategory.Grass.rawValue {
            /* 2 */
            monkeyRun()
            isJumping = false
            
        } else if catA == ColliderCategory.Spikes.rawValue || catB == ColliderCategory.Spikes.rawValue {
            /* Game Over */
            runAction(soundGameOver)
            gameOver()
            showMessage("GameOver")
        } else if catA == ColliderCategory.Enemy.rawValue || catB == ColliderCategory.Enemy.rawValue {
            /* Game Over */
            runAction(soundGameOver)
            gameOver()
            showMessage("GameOver")
        } else if catA == ColliderCategory.Banana.rawValue || catB == ColliderCategory.Banana.rawValue {
            /* Level Completed */
            runAction(soundBanana)
            gameOver()
            showMessage("LevelCompleted")
        }
        
    }
    


    // MARK: - Init Background
    func initBackground() {
        /* 1 */
        backgroundLayer.zPosition = zOrderValue.Background.rawValue
        addChild(backgroundLayer)
        
        /* 2 */
        for index in 0 ... 1 {
            let background = SKSpriteNode(imageNamed: "Background")
            background.name = "Background"
            background.anchorPoint = CGPointZero
            background.position = CGPoint(x: CGFloat(index) * background.size.width, y: 0)
            backgroundLayer.addChild(background)
        }
    }
    
    func scrollBackground() {
        /* 1 */
        let stepX = -backgroundSpeed * delta
        /* 2 */
        backgroundLayer.position = CGPoint(x: backgroundLayer.position.x + CGFloat(stepX), y: 0)
        /* 3 */
        backgroundLayer.enumerateChildNodesWithName("Background") { (child, index) in
            /* 4 */
            let backgroundPosition = self.backgroundLayer.convertPoint(child.position, toNode: self)
            /* 5 */
            if backgroundPosition.x <= -child.frame.size.width {
                child.position = CGPoint(x: child.position.x + child.frame.size.width * 2, y: child.position.y)
            }
        }
    }
    
    // MARK: - Init Clouds
    func initClouds() {
        /* 1 */
        cloudsLayer.zPosition = zOrderValue.Clouds.rawValue
        addChild(cloudsLayer)
        
        /* 2 */
        for index in 1 ... 2 {
            let cloud = SKSpriteNode(imageNamed: "Cloud-\(index)")
            cloud.name = "Cloud"
            cloud.anchorPoint = CGPointZero
            cloud.position = CGPoint(x: size.width * 0.50 * CGFloat(index - 1), y: size.height - cloud.size.height)
            cloudsLayer.addChild(cloud)
        }
    }
    
    func scrollClouds() {
        /* 1 */
        let stepX = -cloudsSpeed * delta
        /* 2 */
        cloudsLayer.position = CGPoint(x: cloudsLayer.position.x + CGFloat(stepX), y: 0)
        /* 3 */
        cloudsLayer.enumerateChildNodesWithName("Cloud") { (child, index) in
            /* 4 */
            let cloudsPosition = self.cloudsLayer.convertPoint(child.position, toNode: self)
            /* 45 */
            if cloudsPosition.x <= -child.frame.size.width {
                child.position = CGPoint(x: child.position.x + self.size.width * 2, y: child.position.y)
            }
        }
    }
    
    // MARK: - Load Level
    func loadLevelFromFile(filename: String) -> [String : AnyObject] {
        /* 1 */
        let path = NSBundle.mainBundle().pathForResource(filename, ofType: nil)
        
        /* 2 */
        var data: NSData!
        do {
            data = try NSData(contentsOfFile: path!, options: NSDataReadingOptions())
        } catch {
            print("Error: Invalid file")
        }
        
        /* 3 */
        var dictionary: NSDictionary!
        do {
            dictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions()) as! NSDictionary
        } catch {
            print("Error: Invalid file format")
        }
        
        /* 4 */
        return dictionary["Level"] as! [String : AnyObject]
    }

    func loadLevel(filename: String) {
        /* 1 */
        foregroundLayer.zPosition = zOrderValue.Foreground.rawValue
        addChild(foregroundLayer)
        
        /* 2 */
        let levelData = loadLevelFromFile(filename)
        
        /* 3 */
        for index in 0 ..< levelData.count {
            let section = levelData["Section-\(index + 1)"] as! [String : AnyObject]
            /* 4 */
            let groundData = section["Ground"] as! [Int]
            /* 5 */
            drawGround(groundData, sectionIndex: index, line: 0)
            drawGround(groundData, sectionIndex: index, line: 1)
            
            /* 6 */
            let grassData = section["Grass"] as! [Int]
            /* 7 */
            drawGrass(grassData, sectionIndex: index)
        }
    }
    
    func drawGround(data: [Int], sectionIndex: Int, line: Int) {
        /* 1 */
        let tileSize = CGSize(width: 64, height: 64)
        
        /* 2 */
        for index in 0 ..< data.count {
            let tileID = data[index]
            if tileID > 0 {
                /* 3 */
                let xPos = tileSize.width * CGFloat(index + sectionIndex * data.count) + tileSize.width * 0.50
                let yPos = tileSize.height * 0.50 + tileSize.height * CGFloat(line)
                /* 4 */
                addTile("Ground", location: CGPoint(x: xPos, y: yPos))
            }
        }
    }

    func addTile(imageNamed: String, location: CGPoint) {
        /* 1 */
        let tile = SKSpriteNode(imageNamed: imageNamed)
        tile.position = location
        tile.name = "Foreground"
        foregroundLayer.addChild(tile)
        
        /* 2 */
        tile.physicsBody = SKPhysicsBody(rectangleOfSize: tile.size)
        tile.physicsBody?.dynamic = false
        
        /* 3 */
        tile.physicsBody?.categoryBitMask = ColliderCategory.Grass.rawValue
    }


    func drawGrass(data: [Int], sectionIndex: Int) {
        /* 1 */
        let tileSize = CGSize(width: 64, height: 64)
        
        /* 2 */
        for index in 0 ..< data.count {
            let tileID = data[index]
            if tileID > 0 {
                /* 3 */
                let xPos = tileSize.width * CGFloat(index + sectionIndex * data.count) + tileSize.width * 0.50
                let yPos = tileSize.height * 2 + tileSize.height * 0.50

                /* 4 */
               switch tileID {
                case 2:
                    addTile("Grass", location: CGPoint(x: xPos, y: yPos))
                    break
                case 3:
                    addSpikes("Spikes", location: CGPoint(x: xPos, y: yPos))
                    break
                case 4:
                    /* Add Snake */
                    addSnake("Snake", location: CGPoint(x: xPos, y: yPos + tileSize.height))
                    addTile("Grass", location: CGPoint(x: xPos, y: yPos))
                    break
                case 5:
                    /* Add Banana */
                    addBanana("Banana", location: CGPoint(x: xPos, y: yPos + tileSize.height))
                    addTile("Grass", location: CGPoint(x: xPos, y: yPos))
                    break
                default:
                    ()
                }
            }
        }
    }

    // MARK: - Scroll Foreground
    func scrollForeground() {
        /* 1 */
        let stepX = -foregroundSpeed * delta
        /* 2 */
        foregroundLayer.position = CGPoint(x: foregroundLayer.position.x + CGFloat(stepX), y: 0)
    }
    

    // MARK: - Add Monkey
    func addMonkey() {
        /* 1 */
        monkey = SKSpriteNode(imageNamed: "Monkey-1")
        monkey.name = "Monkey"
        monkey.zPosition = zOrderValue.Monkey.rawValue
        monkey.position = CGPoint(x: size.width * 0.25, y: size.height * 0.50)
        addChild(monkey)
        
        /* 2 */
        monkey.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: monkey.size.width * 0.65, height: monkey.size.height))
        monkey.physicsBody?.restitution = 0.0
        monkey.physicsBody?.allowsRotation = false
        /* 3 */
        monkey.physicsBody?.categoryBitMask = ColliderCategory.Monkey.rawValue
        /* 4 */
        monkey.physicsBody?.collisionBitMask = ColliderCategory.Grass.rawValue
        /* 5 */
        monkey.physicsBody?.contactTestBitMask = ColliderCategory.Grass.rawValue
    }
    
    func monkeyRun() {
        /* 1 */
        if monkey.actionForKey("kMonkeyRun") == nil {
            /* 2 */
            var textures = [SKTexture]()
            for index in 1 ... 7 {
                let texture = SKTexture(imageNamed: "Monkey-\(index)")
                textures.append(texture)
            }
            
            /* 3 */
            let animate = SKAction.animateWithTextures(textures, timePerFrame: 0.10)
            
            /* 4 */
            let forever = SKAction.repeatActionForever(animate)
            
            /* 5 */
            monkey.runAction(forever, withKey: "kMonkeyRun")
        }
    }
    
    func monkeyJump() {
        /* 1 */
        monkey.removeAllActions()
        /* 2 */
        monkey.runAction(SKAction.setTexture(SKTexture(imageNamed: "Monkey-Jump")))
    }
    
    func monkeyStop() {
        /* 1 */
        monkey.removeAllActions()
        /* 2 */
        monkey.runAction(SKAction.setTexture(SKTexture(imageNamed: "Monkey-1")))
    }
    
    // MARK: - Game States
    func startGame() {
        monkeyRun()
    }
    
    func startNewGame() {
        /* 1 */
        let scene = GameScene(size: self.size)
        
        /* 2 */
        self.scene?.view?.presentScene(scene)
    }
    
    
    func gameOver() {
        gameState = .GameOver
        monkeyStop()
        
        /* Resets Game */
        removeActionForKey("kSpawnBirds")
        enumerateChildNodesWithName("Bird") { (child, index) in
            child.removeFromParent()
        }
        
        /* Save Best Score */
        saveBestDistance()
    }

    
    func showMessage(imageNamed: String) {
        /* 1 */
        let panel = SKSpriteNode(imageNamed: imageNamed)
        panel.zPosition = zOrderValue.Message.rawValue
        panel.position = CGPoint(x: size.width * 0.65, y: -size.height)
        panel.name = imageNamed
        addChild(panel)
        
        /* 2 */
        let move = SKAction.moveTo(CGPoint(x: size.width * 0.65, y: size.height * 0.50), duration: 0.5)
        panel.runAction(SKAction.sequence([soundMessage, move]))
    }

    // MARK: - Add HUD
    func addHUD() {
        /* 1 */
        distanceLabel.fontSize = 48
        distanceLabel.zPosition = zOrderValue.Hud.rawValue
        distanceLabel.position = CGPoint(x: size.width * 0.25, y: size.height - 48)
        distanceLabel.text = "Distance: \(distance)"
        distanceLabel.fontColor = SKColor.yellowColor()
        addChild(distanceLabel)
        
        /* 2 */
        bestDistanceLabel.fontSize = 48
        bestDistanceLabel.zPosition = zOrderValue.Hud.rawValue
        bestDistanceLabel.position = CGPoint(x: size.width * 0.75, y: size.height - 48)
        bestDistanceLabel.text = "Best: \(best)"
        bestDistanceLabel.fontColor = SKColor.yellowColor()
        addChild(bestDistanceLabel)
        
        /* 3 */
        best = loadBestDistance()
    }
    
    func updateDistance() {
        distance = Int(abs(foregroundLayer.position.x) / 16)
    }
    
    
    // MARK: - Save/Load Best score
    func saveBestDistance() {
        if distance >= loadBestDistance() {
            NSUserDefaults.standardUserDefaults().setInteger(best, forKey: "kBest")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    func loadBestDistance() -> Int {
        return NSUserDefaults.standardUserDefaults().integerForKey("kBest")
    }
    
    
    // MARK: - Add Spikes
    func addSpikes(imageNamed: String, location: CGPoint) {
        /* 1 */
        let spikes = SKSpriteNode(imageNamed: imageNamed)
        spikes.position = location
        spikes.name = "Foreground"
        foregroundLayer.addChild(spikes)
        
        /* 2 */
        let center = CGPoint(x: 0, y: -spikes.size.height * 0.25)
        spikes.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: spikes.size.width, height: spikes.size.height * 0.50), center: center)
        spikes.physicsBody?.dynamic = false
        
        /* 3 */
        spikes.physicsBody?.categoryBitMask = ColliderCategory.Spikes.rawValue
        /* 4 */
        spikes.physicsBody?.collisionBitMask = ColliderCategory.Monkey.rawValue
        /* 5 */
        spikes.physicsBody?.contactTestBitMask = ColliderCategory.Monkey.rawValue
    }
    
    // MARK: - Add Snake
    func addSnake(imageNamed: String, location: CGPoint) {
        /* 1 */
        let snake = SKSpriteNode(imageNamed: imageNamed)
        snake.position = location
        snake.name = "Foreground"
        foregroundLayer.addChild(snake)
        
        /* 2 */
        snake.physicsBody = SKPhysicsBody(circleOfRadius: snake.size.height * 0.50)
        snake.physicsBody?.dynamic = false
        
        /* 3 */
        snake.physicsBody?.categoryBitMask = ColliderCategory.Enemy.rawValue
        /* 4 */
        snake.physicsBody?.collisionBitMask = ColliderCategory.Monkey.rawValue
        /* 5 */
        snake.physicsBody?.contactTestBitMask = ColliderCategory.Monkey.rawValue
    }

    // MARK: - Add Banana
    func addBanana(imageNamed: String, location: CGPoint) {
        /* 1 */
        let banana = SKSpriteNode(imageNamed: imageNamed)
        banana.position = location
        banana.name = "Foreground"
        foregroundLayer.addChild(banana)
        
        /* 2 */
        banana.physicsBody = SKPhysicsBody(circleOfRadius: banana.size.width * 0.50)
        banana.physicsBody?.dynamic = false
        
        /* 3 */
        banana.physicsBody?.categoryBitMask = ColliderCategory.Banana.rawValue
        
        /* 4 */
        banana.physicsBody?.collisionBitMask = ColliderCategory.Monkey.rawValue
        
        /* 5 */
        banana.physicsBody?.contactTestBitMask = ColliderCategory.Monkey.rawValue
    }


    // MARK: - Update
    override func update(currentTime: CFTimeInterval) {
        if gameState != .Playing {
            return
        }
        /* 1 */
        if lastUpdate == 0.0 {
            delta = 0
        }else{
            delta = currentTime - lastUpdate
        }
        lastUpdate = currentTime
        
        /* 2 */
        
        scrollBackground()
        scrollForeground()
        scrollClouds()
        
        /* 3 */
        monkey.position.x = size.width * 0.25
        
        updateDistance()
        
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* 1 */
        if gameState == .Playing {
            if !isJumping {
                /* 2 */
                runAction(soundJump)
                /* 3 */
                monkeyJump()
                /* 4 */
                monkey.physicsBody?.applyImpulse(CGVectorMake(0, 220))
                /* 5 */
                isJumping = true
            }
        }
        
        /* 2 */
        if gameState == .Ready {
            let startGameMessage = childNodeWithName("StartGame") as! SKSpriteNode
            gameState = .Playing
            startGameMessage.removeFromParent()
            startGame()
        }
        
        /* 3 */
        if gameState == .GameOver {
            startNewGame()
        }
        

    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
   
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
   
    }
    
    
    
    
    
}
