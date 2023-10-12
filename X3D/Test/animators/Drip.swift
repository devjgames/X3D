//
//  Drip.swift
//  X3DTest
//
//  Created by Douglas McNamara on 9/19/23.
//

import X3D

class Drip : Animator {
    
    private var _sound:Sound?
    private var _player:Node?
    
    override func setup(game: Game, scene: Scene, node: Node, inDesign: Bool) throws {
        if inDesign {
            let model = try game.assets.load("ui.obj") as! Node
            
            node.children = [ model.newInstance() ]
            node.children.first!.children.first!.texture = "ui.png"
            node.scale = Vec3(1, 1, 1) * 0.25
        } else {
            node.children = []
            
            _sound = try game.assets.load("amb.m4a") as? Sound
            _sound = try _sound!.newInstance()
            _sound!.player.volume = 0
            _sound!.player.numberOfLoops = -1
            _sound!.player.play()
            
            scene.root.traverse({ n in
                if n.animator is Player {
                    _player = n
                }
                return true
            })
        }
        try super.setup(game: game, scene: scene, node: node, inDesign: inDesign)
    }
    
    override func update(game: Game, scene: Scene, node: Node, inDesign: Bool) throws {
        if inDesign {
            return
        }
        _sound!.player.volume = 0.2 - min((_player!.position - node.position).length / 1000, 0.2)
        
        try super.update(game: game, scene: scene, node: node, inDesign: inDesign)
    }
}
