//
//  JSGame.swift
//  X3D
//
//  Created by Douglas McNamara on 9/20/23.
//

import Foundation
import JavaScriptCore

public class JSGame {
    
    public weak var game:Game?
    public weak var scene:Scene?
    public weak var node:Node?
    public weak var player:Node?
    public weak var activeNode:Node?
    
    public var context:JSContext
    
    public init(url:URL, setup: @escaping (JSGame) -> Void) throws {
        context = JSContext()
        context.exceptionHandler = { context, exp in
            if let e = exp {
                if let s = e.toString() {
                    Log.put(0, "JS Error: \(s)")
                }
            }
        }
        
        setup(self)
        
        context.evaluateScript(try String(contentsOf: url))
    }
    
    public func setup(game:Game, scene:Scene, node:Node) {
        self.game = game
        self.scene = scene
        self.node = node
        if let f = context.objectForKeyedSubscript("setup") {
            f.call(withArguments: [])
        }
    }
    
    public func update(game:Game, scene:Scene, node:Node) {
        self.game = game
        self.scene = scene
        self.node = node
        if let f = context.objectForKeyedSubscript("update") {
            f.call(withArguments: [])
        }
    }
    
    public func addBasicFuncs() {
        let log: @convention(block) (String) -> Void = { s in
            Log.put(0, s)
        }
        let logOBJ = unsafeBitCast(log, to: AnyObject.self)
        
        //? X3DLog("")
        context.setObject(logOBJ, forKeyedSubscript: "X3DLog" as (NSCopying & NSObjectProtocol))
        
        let nodeName: @convention(block) () -> String? = {
            if let node = self.activeNode {
                return node.animatorName
            }
            return nil
        }
        let nodeNameOBJ = unsafeBitCast(nodeName, to: AnyObject.self)
        
        //? X3DNodeName()
        context.setObject(nodeNameOBJ, forKeyedSubscript: "X3DNodeName" as (NSCopying & NSObjectProtocol))

        let nodePosition: @convention(block) () -> [Float]? = {
            if let node = self.activeNode {
                return [ node.position.x, node.position.y, node.position.z ]
            }
            return nil
        }
        let nodePositionOBJ = unsafeBitCast(nodePosition, to: AnyObject.self)
        
        //? X3DNodePosition()
        context.setObject(nodePositionOBJ, forKeyedSubscript: "X3DNodePosition" as (NSCopying & NSObjectProtocol))
        
        let setNodePosition: @convention(block) (Float,Float,Float) -> Void = { x,y,z in
            if let node = self.activeNode, let scene = self.scene {
                let offset = scene.camera.eye - scene.camera.target
                node.position = Vec3(x, y, z)
                if self.player == node {
                    scene.camera.target = node.position
                    scene.camera.eye = node.position + offset
                }
            }
        }
        let setNodePositionOBJ = unsafeBitCast(setNodePosition, to: AnyObject.self)
        
        //? X3DSetNodePosition(0, 0, 0)
        context.setObject(setNodePositionOBJ, forKeyedSubscript: "X3DSetNodePosition" as (NSCopying & NSObjectProtocol))
        
        let nodeID: @convention(block) () -> String? = {
            if let node = self.node {
                return node.id.uuidString
            }
            return nil
        }
        let nodeIDOBJ = unsafeBitCast(nodeID, to: AnyObject.self)
        
        //? X3DNodeID()
        context.setObject(nodeIDOBJ, forKeyedSubscript: "X3DNodeID" as (NSCopying & NSObjectProtocol))
        
        let activateNode: @convention(block) (String) -> Void = { id in
            let uuid=UUID(uuidString: id)
            
            if let scene = self.scene {
                for n in scene.root.children {
                    if n.id == uuid {
                        self.activeNode = n
                        break
                    }
                }
            }
        }
        let activateNodeOBJ = unsafeBitCast(activateNode, to: AnyObject.self)
        
        //? X3DActivateNode()
        context.setObject(activateNodeOBJ, forKeyedSubscript: "X3DActivateNode" as (NSCopying & NSObjectProtocol))
        
        let playerID: @convention(block) () -> String? = {
            if let player = self.player {
                return player.id.uuidString
            }
            return nil
        }
        let playerIDOBJ = unsafeBitCast(playerID, to: AnyObject.self)
        
        //? X3DPlayerID()
        context.setObject(playerIDOBJ, forKeyedSubscript: "X3DPlayerID" as (NSCopying & NSObjectProtocol))
    }
}
