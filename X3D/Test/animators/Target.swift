//
//  Target.swift
//  X3DTest
//
//  Created by Douglas McNamara on 9/17/23.
//

import X3D

class Target : Animator {
    
    override func setup(game: Game, scene: Scene, node: Node, inDesign: Bool) throws {
        if inDesign {
            let model = try game.assets.load("ui.obj") as! Node
            
            node.children = [ model.newInstance() ]
            node.children.first!.children.first!.texture = "ui.png"
            
            node.position = scene.camera.target
            node.scale = Vec3(1, 1, 1) * 0.25
        } else {
            node.children = []
        }
    }
    
    override func update(game: Game, scene: Scene, node: Node, inDesign: Bool) throws {
        node.position = scene.camera.target
    }
}
