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
    
    var gameState = GameState.ready
    
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

    override func didMove(to view: SKView) {
        /* Init Physics World */
        initPhysicsWorld()
        
        /* Init Background */
        initBackground()
        
        /* Init Clouds */
        initClouds()
        
        /* Load Level */
        loadLevel(filename: "Level1.json")
        
        /* Add Monkey */
        addMonkey()
       
        /* Monkey Run */
       // monkeyRun()
        
        /* Add HUD */
        addHUD()
        
        /* Show Message: Start Game */
        showMessage(imageNamed: "StartGame")
    }
    
    
    // MARK: - Init Physics World
    func initPhysicsWorld() {
        /* 1 */
        physicsWorld.gravity = CGVector(dx: 0, dy: -20)
        
        /* 2 */
        physicsWorld.contactDelegate = self
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if gameState != GameState.playing {
            return
        }
        
        /* 1 */
        let catA = contact.bodyA.categoryBitMask;
        let catB = contact.bodyB.categoryBitMask;
        
        
        if catA == ColliderCategory.grass.rawValue || catB == ColliderCategory.grass.rawValue {
            /* 2 */
            monkeyRun()
            isJumping = false
            
        } else if catA == ColliderCategory.spikes.rawValue || catB == ColliderCategory.spikes.rawValue {
            /* Game Over */
            run(soundGameOver)
            gameOver()
            showMessage(imageNamed: "GameOver")
        } else if catA == ColliderCategory.enemy.rawValue || catB == ColliderCategory.enemy.rawValue {
            /* Game Over */
            run(soundGameOver)
            gameOver()
            showMessage(imageNamed: "GameOver")
        } else if catA == ColliderCategory.banana.rawValue || catB == ColliderCategory.banana.rawValue {
            /* Level Completed */
            run(soundBanana)
            gameOver()
            showMessage(imageNamed: "LevelCompleted")
        }
        
    }
    


    // MARK: - Init Background
    func initBackground() {
        /* 1 */
        backgroundLayer.zPosition = zOrderValue.background.rawValue
        addChild(backgroundLayer)
        
        /* 2 */
        for index in 0 ... 1 {
            let background = SKSpriteNode(imageNamed: "Background")
            background.name = "Background"
            background.anchorPoint = CGPoint.zero
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
        backgroundLayer.enumerateChildNodes(withName: "Background") { (child, index) in
            /* 4 */
            let backgroundPosition = self.backgroundLayer.convert(child.position, to: self)
            /* 5 */
            if backgroundPosition.x <= -child.frame.size.width {
                child.position = CGPoint(x: child.position.x + child.frame.size.width * 2, y: child.position.y)
            }
        }
    }
    
    // MARK: - Init Clouds
    func initClouds() {
        /* 1 */
        cloudsLayer.zPosition = zOrderValue.clouds.rawValue
        addChild(cloudsLayer)
        
        /* 2 */
        for index in 1 ... 2 {
            let cloud = SKSpriteNode(imageNamed: "Cloud-\(index)")
            cloud.name = "Cloud"
            cloud.anchorPoint = CGPoint.zero
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
        cloudsLayer.enumerateChildNodes(withName: "Cloud") { (child, index) in
            /* 4 */
            let cloudsPosition = self.cloudsLayer.convert(child.position, to: self)
            /* 45 */
            if cloudsPosition.x <= -child.frame.size.width {
                child.position = CGPoint(x: child.position.x + self.size.width * 2, y: child.position.y)
            }
        }
    }
    
    // MARK: - Load Level
    func loadLevelFromFile(filename: String) -> [String : Any] {
        /* 1 */
        let path = Bundle.main.path(forResource: filename, ofType: nil)
        
        /* 2 */
        var data: Data!
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: path!), options: NSData.ReadingOptions())
        } catch {
            print("Error: Invalid file")
        }
        
        /* 3 */
        var dictionary: NSDictionary!
        do {
            dictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions()) as! NSDictionary
        } catch {
            print("Error: Invalid file format")
        }
        
        /* 4 */
        return dictionary["Level"] as! [String : Any]
    }

    func loadLevel(filename: String) {
        /* 1 */
        foregroundLayer.zPosition = zOrderValue.foreground.rawValue
        addChild(foregroundLayer)
        
        /* 2 */
        let levelData = loadLevelFromFile(filename: filename)
        
        /* 3 */
        for index in 0 ..< levelData.count {
            let section = levelData["Section-\(index + 1)"] as! [String : Any]
            /* 4 */
            let groundData = section["Ground"] as! [Int]
            /* 5 */
            drawGround(data: groundData, sectionIndex: index, line: 0)
            drawGround(data: groundData, sectionIndex: index, line: 1)
            
            /* 6 */
            let grassData = section["Grass"] as! [Int]
            /* 7 */
            drawGrass(data: grassData, sectionIndex: index)
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
                addTile(imageNamed: "Ground", location: CGPoint(x: xPos, y: yPos))
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
        tile.physicsBody = SKPhysicsBody(rectangleOf: tile.size)
        tile.physicsBody?.isDynamic = false
        
        /* 3 */
        tile.physicsBody?.categoryBitMask = ColliderCategory.grass.rawValue
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
                    addTile(imageNamed: "Grass", location: CGPoint(x: xPos, y: yPos))
                    break
                case 3:
                    addSpikes(imageNamed: "Spikes", location: CGPoint(x: xPos, y: yPos))
                    break
                case 4:
                    /* Add Snake */
                    addSnake(imageNamed: "Snake", location: CGPoint(x: xPos, y: yPos + tileSize.height))
                    addTile(imageNamed: "Grass", location: CGPoint(x: xPos, y: yPos))
                    break
                case 5:
                    /* Add Banana */
                    addBanana(imageNamed: "Banana", location: CGPoint(x: xPos, y: yPos + tileSize.height))
                    addTile(imageNamed: "Grass", location: CGPoint(x: xPos, y: yPos))
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
        monkey.zPosition = zOrderValue.monkey.rawValue
        monkey.position = CGPoint(x: size.width * 0.25, y: size.height * 0.50)
        addChild(monkey)
        
        /* 2 */
        monkey.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: monkey.size.width * 0.65, height: monkey.size.height))
        monkey.physicsBody?.restitution = 0.0
        monkey.physicsBody?.allowsRotation = false
        /* 3 */
        monkey.physicsBody?.categoryBitMask = ColliderCategory.monkey.rawValue
        /* 4 */
        monkey.physicsBody?.collisionBitMask = ColliderCategory.grass.rawValue
        /* 5 */
        monkey.physicsBody?.contactTestBitMask = ColliderCategory.grass.rawValue
    }
    
    func monkeyRun() {
        /* 1 */
        if monkey.action(forKey: "kMonkeyRun") == nil {
            /* 2 */
            var textures = [SKTexture]()
            for index in 1 ... 7 {
                let texture = SKTexture(imageNamed: "Monkey-\(index)")
                textures.append(texture)
            }
            
            /* 3 */
            let animate = SKAction.animate(with: textures, timePerFrame: 0.10)
            
            /* 4 */
            let forever = SKAction.repeatForever(animate)
            
            /* 5 */
            monkey.run(forever, withKey: "kMonkeyRun")
        }
    }
    
    func monkeyJump() {
        /* 1 */
        monkey.removeAllActions()
        /* 2 */
        monkey.run(SKAction.setTexture(SKTexture(imageNamed: "Monkey-Jump")))
    }
    
    func monkeyStop() {
        /* 1 */
        monkey.removeAllActions()
        /* 2 */
        monkey.run(SKAction.setTexture(SKTexture(imageNamed: "Monkey-1")))
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
        gameState = .gameOver
        monkeyStop()
        
        /* Resets Game */
        removeAction(forKey: "kSpawnBirds")
        enumerateChildNodes(withName: "Bird") { (child, index) in
            child.removeFromParent()
        }
        
        /* Save Best Score */
        saveBestDistance()
    }

    
    func showMessage(imageNamed: String) {
        /* 1 */
        let panel = SKSpriteNode(imageNamed: imageNamed)
        panel.zPosition = zOrderValue.message.rawValue
        panel.position = CGPoint(x: size.width * 0.65, y: -size.height)
        panel.name = imageNamed
        addChild(panel)
        
        /* 2 */
        let move = SKAction.move(to: CGPoint(x: size.width * 0.65, y: size.height * 0.50), duration: 0.5)
        panel.run(SKAction.sequence([soundMessage, move]))
    }

    // MARK: - Add HUD
    func addHUD() {
        /* 1 */
        distanceLabel.fontSize = 48
        distanceLabel.zPosition = zOrderValue.hud.rawValue
        distanceLabel.position = CGPoint(x: size.width * 0.25, y: size.height - 48)
        distanceLabel.text = "Distance: \(distance)"
        distanceLabel.fontColor = SKColor.yellow
        addChild(distanceLabel)
        
        /* 2 */
        bestDistanceLabel.fontSize = 48
        bestDistanceLabel.zPosition = zOrderValue.hud.rawValue
        bestDistanceLabel.position = CGPoint(x: size.width * 0.75, y: size.height - 48)
        bestDistanceLabel.text = "Best: \(best)"
        bestDistanceLabel.fontColor = SKColor.yellow
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
            UserDefaults.standard.set(distance, forKey: "kBest")
            UserDefaults.standard.synchronize()
        }
    }
    
    func loadBestDistance() -> Int {
        return UserDefaults.standard.integer(forKey: "kBest")
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
        spikes.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: spikes.size.width, height: spikes.size.height * 0.50), center: center)
        spikes.physicsBody?.isDynamic = false
        
        /* 3 */
        spikes.physicsBody?.categoryBitMask = ColliderCategory.spikes.rawValue
        /* 4 */
        spikes.physicsBody?.collisionBitMask = ColliderCategory.monkey.rawValue
        /* 5 */
        spikes.physicsBody?.contactTestBitMask = ColliderCategory.monkey.rawValue
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
        snake.physicsBody?.isDynamic = false
        
        /* 3 */
        snake.physicsBody?.categoryBitMask = ColliderCategory.enemy.rawValue
        /* 4 */
        snake.physicsBody?.collisionBitMask = ColliderCategory.monkey.rawValue
        /* 5 */
        snake.physicsBody?.contactTestBitMask = ColliderCategory.monkey.rawValue
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
        banana.physicsBody?.isDynamic = false
        
        /* 3 */
        banana.physicsBody?.categoryBitMask = ColliderCategory.banana.rawValue
        
        /* 4 */
        banana.physicsBody?.collisionBitMask = ColliderCategory.monkey.rawValue
        
        /* 5 */
        banana.physicsBody?.contactTestBitMask = ColliderCategory.monkey.rawValue
    }


    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        if gameState != .playing {
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
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* 1 */
        if gameState == .playing {
            if !isJumping {
                /* 2 */
                run(soundJump)
                /* 3 */
                monkeyJump()
                /* 4 */
                monkey.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 220))
                /* 5 */
                isJumping = true
            }
        }
        
        /* 2 */
        if gameState == .ready {
            let startGameMessage = childNode(withName: "StartGame") as! SKSpriteNode
            gameState = .playing
            startGameMessage.removeFromParent()
            startGame()
        }
        
        /* 3 */
        if gameState == .gameOver {
            startNewGame()
        }
        

    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
   
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
   
    }
    
    
    
    
    
}
