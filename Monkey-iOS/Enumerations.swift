//
//  Enumerations.swift
//  Monkey
//
//  Created by Nikolaos Kechagias on 20/08/15.
//  Copyright © 2015 Nikolaos Kechagias. All rights reserved.
//

import SpriteKit

// Game's States
enum GameState: Int {
    case Ready, GameOver, Playing
}

// The drawing order of objects in z-axis (zPosition property)
enum zOrderValue: CGFloat {
    case Background, Clouds, Foreground, Bird, Monkey, Hud, Message
}

// The categories of the game's objects for handling of the collisions
enum ColliderCategory: UInt32 {
    case Monkey = 1
    case Grass = 2
    case Spikes = 4
    case Enemy = 8
    case Banana = 16
}
