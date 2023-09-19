//
//  Light.swift
//  X3DTest
//
//  Created by Douglas McNamara on 9/17/23.
//

import X3D

class Light : Animator {
    
    override func setup(game: Game, scene: Scene, node: Node, inDesign: Bool) throws {
        if inDesign {
            let model = try game.assets.load("ui.obj") as! Node
            
            node.children = [ model.newInstance() ]
            node.children.first!.children.first!.texture = "ui.png"
            node.scale = Vec3(1, 1, 1) * 0.25
        } else {
            node.children = []
        }
        node.isLight = true
    }
    
    override func handleUI(game: Game, scene: Scene, node: Node, ui: UI, reset: Bool) throws {
        if let color = ui.field(key: "Light.color.field", gap: 0, width: 125, caption: "Color", vec4Value: node.lightColor, reset: reset) {
            node.lightColor = color
        }
        ui.addRow(gap: 5)
        if let range = ui.field(key: "Light.range.field", gap: 0, width: 125, caption: "Range", realValue: node.lightRange, reset: reset) {
            node.lightRange = range
        }
    }
}

