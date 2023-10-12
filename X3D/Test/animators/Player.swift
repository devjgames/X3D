//
//  Player.swift
//  X3DTest
//
//  Created by Douglas McNamara on 9/19/23.
//

import X3D

public class Player : KeyFrameMeshAnimator {
    
    private var _triangles=[Triangle]()
    private var _velocity=Vec3()
    private var _groundMatrix=Mat4.identity
    private var _onGround=false
    private let _radius:Float=16
    
    public required init() {
        super.init()
        
        scripted = true
    }
    
    public override var isSingleton: Bool {
        true
    }
    
    public override func setup(game: Game, scene: Scene, node: Node, inDesign: Bool) throws {
        try super.setup(game: game, scene: scene, node: node, inDesign: inDesign)
        
        if node.reals["_OFFSET"] == nil {
            node.reals["_OFFSET"] = 100
        }
        if node.reals["_SPEED"] == nil {
            node.reals["_SPEED"] = 100
        }
        
        scene.root.calcModel(parent: nil)
        
        if let child = node.children.first, let mesh = mesh {
            if !inDesign {
                
                child.position.y = -_radius - mesh.frames.frames[0].bounds.lo.z
                
                scene.root.traverse({ n in
                    if n.collidable {
                        for i in 0..<n.drawIndices/3 {
                            let p1 = n.vertices[n.indices[i * 3 + 0]].position
                            let p2 = n.vertices[n.indices[i * 3 + 1]].position
                            let p3 = n.vertices[n.indices[i * 3 + 2]].position
                            var triangle = Triangle(p1, p2, p3)
                            
                            triangle.transform(m: n.model)

                            _triangles.append(triangle)
                        }
                    }
                    return true
                })
                
                let offset = scene.camera.eye - scene.camera.target
                
                scene.camera.eye = scene.camera.target + Vec3.normalize(offset) * node.reals["_OFFSET"]!
            }
        }
    }
    
    public override func update(game: Game, scene: Scene, node: Node, inDesign: Bool) throws {
        try super.update(game: game, scene: scene, node: node, inDesign: inDesign)
        
        if inDesign {
            return
        }
    
        if mesh == nil {
            return
        }
        
        if game.isButtonDown(1) {
            scene.camera.rotate(dX: -game.dX, dY: game.dY)
        }
        
        let x = node.reals["_OFFSET"]!
        let speed = node.reals["_SPEED"]!
        let dX = game.mouseX - game.width / 2
        let dY = game.mouseY - game.height / 2
        let dL = sqrtf(dX * dX + dY * dY)
        let offset = scene.camera.eye - scene.camera.target
        var f = offset * Vec3(-1, 0, -1)
        var moving = false
        
        _velocity = _velocity * Vec3(0, 1, 0)
        if game.isButtonDown(0) && f.length > 0.0000001 && dL > 0.01 && _onGround {
            f.normalize()
            f = f * dY / -dL + Vec3.normalize(Vec3.cross(f, Vec3(0, 1, 0))) * dX / dL
            f = Vec3.normalize(f) * speed
            _velocity = _velocity + f
            f.normalize()
            
            var degrees = acosf(max(-0.999, min(0.999, f.x))) * 180 / Float.pi
            
            if f.z > 0 {
                degrees = 360 - degrees
            }
            node.rotation = Mat4.rotation(degrees, Vec3(0, 1, 0))
            
            moving = true
        }
        _velocity.y = _velocity.y - 20000 * game.elapsedTime
        if _onGround {
            var set = mesh!.start != 66
            
            if !set {
                set = mesh!.done
            }
            if set {
                if moving {
                    mesh!.setSequence(start: 40, end: 45, speed: 6, looping: true)
                } else {
                    mesh!.setSequence(start: 0, end: 39, speed: 9, looping: true)
                }
            }
        } else {
            mesh!.setSequence(start: 66, end: 68, speed: 8, looping: false)
        }
        
        var delta = Vec3.transformNormal(_groundMatrix, _velocity * game.elapsedTime)
        var groundNormal = Vec3()
        
        _groundMatrix = Mat4.identity
        _onGround = false
        
        if delta.length > 0.0000001 {
            if delta.length > _radius / 2 {
                delta = Vec3.normalize(delta) * (_radius / 2)
            }
            
            node.position = node.position + delta
            
            for _ in 0..<3 {
                var resolvedPosition = Vec3()
                var resolvedNormal = Vec3()
                var time = _radius
                var hit = false
                
                for triangle in _triangles {
                    if triangle.resolve(position: node.position, radius: _radius, resolvedPosition: &resolvedPosition, resolvedNormal: &resolvedNormal, time: &time) {
                        hit = true
                    }
                }
                if hit {
                    if acosf(max(-0.999, min(0.999, Vec3.dot(resolvedNormal, Vec3(0, 1, 0))))) * 180 / Float.pi < 60 {
                        groundNormal = groundNormal + resolvedNormal
                        _onGround = true
                    }
                    node.position = resolvedPosition
                } else {
                    break
                }
            }
        }
        if _onGround {
            let u = Vec3.normalize(groundNormal)
            var r = Vec3(1, 0, 0)
            let f = Vec3.normalize(Vec3.cross(r, u))
            
            r = Vec3.normalize(Vec3.cross(u, f))
            
            _groundMatrix = Mat4(r.x, u.x, f.x, 0,
                                 r.y, u.y, f.y, 0,
                                 r.z, u.z, f.z, 0,
                                 0, 0, 0, 1
            )
            _velocity.y = 0
        }
        
        scene.camera.target = node.position
        
        let origin = node.position
        let direction = Vec3.normalize(offset)
        var length = x
        var time = x + (_radius - 2)
        var hit = false
        
        for triangle in _triangles {
            if triangle.intersects(origin: origin, direction: direction, buffer: 1, time: &time) {
                hit = true
            }
        }
        if hit {
            length = min(x, time) - _radius - 2
        }
        scene.camera.eye = node.position + direction * length
    }
    
    public override func handleUI(game: Game, scene: Scene, node: Node, ui: UI, reset: Bool) throws {
        try super.handleUI(game: game, scene: scene, node: node, ui: ui, reset: reset)
        
        ui.addRow(gap: 5)
        if let result = ui.field(key: "Player.offset.field", gap: 0, width: 125, caption: "Offset", realValue: node.reals["_OFFSET"]!, reset: reset) {
            node.reals["_OFFSET"] = result
        }
        ui.addRow(gap: 5)
        if let result = ui.field(key: "Player.speed.field", gap: 0, width: 125, caption: "Speed", realValue: node.reals["_SPEED"]!, reset: reset) {
            node.reals["_SPEED"] = result
        }
    }
}
