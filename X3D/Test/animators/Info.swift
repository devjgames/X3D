//
//  Info.swift
//  X3DTest
//
//  Created by Douglas McNamara on 9/17/23.
//

import X3D

class Info : Animator {
    
    override var isSingleton: Bool {
        true
    }
    
    override func setup(game: Game, scene: Scene, node: Node, inDesign: Bool) throws {
        node.isSprite = true
        node.depthTestEnabled = false
        node.depthWriteEnabled = false
        node.blendEnabled = true
        node.additiveBlend = false
        node.texture = "font.png"
        node.vertexColorEnabled = true
        node.allocQuadFaces(count: 100)
        node.drawIndices = 0
        node.zOrder = 100000
        node.children = []
    }
    
    override func update(game: Game, scene: Scene, node: Node, inDesign: Bool) throws {
        node.vertices.removeAll(keepingCapacity: true)
        node.drawIndices = 0
        if inDesign {
            try node.push(game, text: "FPS = \(game.frameRate)", scale: 1, cw: 8, ch: 12, cols: 100, lineSpacing: 5, pos: Vec2(10, 10), color: Vec4(1, 1, 1, 1))
        } else {
            try node.push(game, text: "FPS = \(game.frameRate)\nESC = Quit", scale: 1, cw: 8, ch: 12, cols: 100, lineSpacing: 5, pos: Vec2(10, 10), color: Vec4(1, 1, 1, 1))
        }
    }
}
