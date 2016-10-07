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
    case ready, gameOver, playing
}

// The drawing order of objects in z-axis (zPosition property)
enum zOrderValue: CGFloat {
    case background, clouds, foreground, bird, monkey, hud, message
}

// The categories of the game's objects for handling of the collisions
enum ColliderCategory: UInt32 {
    case monkey = 1
    case grass = 2
    case spikes = 4
    case enemy = 8
    case banana = 16
}
