//
//  NodeLoader.swift
//  X3D
//
//  Created by Douglas McNamara on 9/17/23.
//

import Foundation

public class NodeLoader : AssetLoader {
    
    public override init() {
        super.init()
    }
    
    public override func load(_ url: URL, path: String, assets: AssetManager) throws -> Any? {
        let text=try String(contentsOf: url)
        let lines=text.components(separatedBy: CharacterSet.newlines)
        var vList=[Vec3]()
        var tList=[Vec2]()
        var nList=[Vec3]()
        var textures=[String:String]()
        var nodes=[String:Node]()
        let root=Node()
        var material=""
        
        root.name = NSString(string: url.lastPathComponent).deletingPathExtension
        
        for line in lines {
            let tLine=line.trimmingCharacters(in: CharacterSet.whitespaces)
            let tokens=tLine.components(separatedBy: CharacterSet.whitespaces)
            
            if tLine.hasPrefix("mtllib ") {
                let mURL=url.deletingLastPathComponent().appendingPathComponent(String(tLine[String.Index(utf16Offset: 6, in: tLine)...]).trimmingCharacters(in: CharacterSet.whitespaces))
                let mText=try String(contentsOf: mURL)
                var name:String?=nil
                let mLines=mText.components(separatedBy: CharacterSet.newlines)
                
                for mLine in mLines {
                    let tMLine=mLine.trimmingCharacters(in: CharacterSet.whitespaces)
                    
                    if tMLine.hasPrefix("newmtl ") {
                        name = String(tMLine[String.Index(utf16Offset: 6, in: tMLine)...]).trimmingCharacters(in: CharacterSet.whitespaces)
                    } else if tMLine.hasPrefix("map_Kd ") {
                        textures[name!] = String(tMLine[String.Index(utf16Offset: 6, in: tMLine)...]).trimmingCharacters(in: CharacterSet.whitespaces)
                    }
                }
            } else if tLine.hasPrefix("usemtl ") {
                var node:Node?
                
                material = String(tLine[String.Index(utf16Offset: 6, in: tLine)...]).trimmingCharacters(in: CharacterSet.whitespaces)
                node = nodes[material];
                if node == nil {
                    node = Node()
                    node!.name = ""
                    nodes[material] = node
                    root.children.append(node!)
                }
                if let texture = textures[material] {
                    node!.name = NSString(string: NSString(string: texture).lastPathComponent).deletingPathExtension
                    node!.texture = texture
                }
            } else if tLine.hasPrefix("v ") {
                vList.append(Vec3(Float(tokens[1])!, Float(tokens[2])!, Float(tokens[3])!))
            } else if tLine.hasPrefix("vt ") {
                tList.append(Vec2(Float(tokens[1])!, 1 - Float(tokens[2])!))
            } else if tLine.hasPrefix("vn ") {
                nList.append(Vec3(Float(tokens[1])!, Float(tokens[2])!, Float(tokens[3])!))
            } else if tLine.hasPrefix("f ") {
                var node = nodes[material]
                
                if node == nil {
                    node = Node()
                    node!.name = ""
                    nodes[material] = node
                    root.children.append(node!)
                }
                
                var indices=[Int]()
                let n=tokens.count
                let b=node!.vertices.count
                
                for i in 1..<n {
                    let iTokens=tokens[i].components(separatedBy: CharacterSet(charactersIn: "/"))
                    let vI=Int(iTokens[0])! - 1
                    let tI=Int(iTokens[1])! - 1
                    let nI=Int(iTokens[2])! - 1
                    
                    node!.vertices.append(Vertex(vList[vI], tList[tI], Vec2(), nList[nI], Vec4(1, 1, 1, 1)))
                    indices.append(b + i - 1)
                }
                indices.reverse()
                node!.push(indices)
            }
        }
        for node in root.children {
            node.drawIndices = node.indices.count
            node.calcBounds()
        }
        return root;
    }
}

open class ModelAnimator : Animator {
    
    private static var _models=[Any]()
    
    public static func populateAssets(url:URL) throws {
        let items = try FileManager.default.contentsOfDirectory(atPath: url.path)
        
        for item in items {
            if NSString(string:item).pathExtension == "obj" {
                _models.append(item)
            }
        }
    }
    
    public var scripted=false
    
    open override func setup(game: Game, scene: Scene, node: Node, inDesign: Bool) throws {
        try load(game: game, node: node)
        
        if scripted {
            try super.setup(game: game, scene: scene, node: node, inDesign: inDesign)
        }
    }
    
    open override func update(game: Game, scene: Scene, node: Node, inDesign: Bool) throws {
        if scripted {
            try super.update(game: game, scene: scene, node: node, inDesign: inDesign)
        }
    }
    
    open override func handleUI(game: Game, scene: Scene, node: Node, ui: UI, reset: Bool) throws {
        var selModel = -2
        var resetFields = reset
        
        if reset {
            let n = ModelAnimator._models.count
            
            selModel = -1
            
            for i in 0..<n {
                if ModelAnimator._models[i] as? String == node.strings["_PATH"] {
                    selModel = i
                    break
                }
            }
        }
        if let result = ui.list(key: "ModelAnimator.list", gap: 0, width: 225, height: 100, items: &ModelAnimator._models, selected: selModel) {
            node.strings["_PATH"] = ModelAnimator._models[result] as? String
            
            try load(game: game, node: node)
            
            resetFields = true
        }
        ui.addRow(gap: 5)
        if let result = ui.field(key: "ModelAnimator.ambient.field", gap: 0, width: 150, caption: "Ambient", vec4Value: node.ambientColor, reset: resetFields) {
            node.ambientColor = result
            setAttributes(node: node)
        }
        ui.addRow(gap: 5)
        if let result = ui.field(key: "ModelAnimator.diffuse.field", gap: 0, width: 150, caption: "Diffuse", vec4Value: node.diffuseColor, reset: resetFields) {
            node.diffuseColor = result
            setAttributes(node: node)
        }
        ui.addRow(gap: 5)
        if let result = ui.field(key: "ModelAnimator.color.field", gap: 0, width: 150, caption: "Color", vec4Value: node.color, reset: resetFields) {
            node.color = result
            setAttributes(node: node)
        }
        ui.addRow(gap: 5)
        if ui.button(key: "ModelAnimator.lit.field", gap: 0, caption: "Lit", selected: node.lightingEnabled) {
            node.lightingEnabled.toggle()
            setAttributes(node: node)
        }
        if ui.button(key: "ModelAnimator.mapped.field", gap: 5, caption: "Lit Map", selected: node.lightMapEnabled) {
            node.lightMapEnabled.toggle()
            setAttributes(node: node)
        }
        ui.addRow(gap: 5)
        if ui.button(key: "ModelAnimator.collidable.field", gap: 0, caption: "Collidable", selected: node.collidable) {
            node.collidable.toggle()
            setAttributes(node: node)
        }
        if ui.button(key: "ModelAnimator.dynamic.field", gap: 5, caption: "Dynamic", selected: node.dynamic) {
            node.dynamic.toggle()
            setAttributes(node: node)
        }
    }
    
    private func load(game:Game, node: Node) throws {
        
        node.children = []
        
        if let path = node.strings["_PATH"] {
            if let model = try game.assets.load(path) as? Node {
                node.children = [ model.newInstance() ]
                
                setAttributes(node: node)
            }
        }
    }
    
    private func setAttributes(node:Node) {
        node.traverse({ n in
            n.ambientColor = node.ambientColor
            n.diffuseColor = node.diffuseColor
            n.color = node.color
            n.lightingEnabled = node.lightingEnabled
            n.lightMapEnabled = node.lightMapEnabled
            n.collidable = node.collidable
            n.dynamic = node.dynamic
            n.texture2Linear = node.texture2Linear
            
            return true
        })
    }
}
