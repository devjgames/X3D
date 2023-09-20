//
//  LightMapper.swift
//  X3D
//
//  Created by Douglas McNamara on 9/19/23.
//

import Foundation

open class LightMapper : Animator {
    
    public override var isSingleton: Bool {
        true
    }

    open override func setup(game: Game, scene: Scene, node: Node, inDesign: Bool) throws {
        if node.integers["_WIDTH"] == nil {
            node.integers["_WIDTH"] = 128
        }
        if node.integers["_HEIGHT"] == nil {
            node.integers["_HEIGHT"] = 128
        }
        if node.integers["_SAMPLES"] == nil {
            node.integers["_SAMPLES"] = 16
        }
        if node.reals["_SAMPLE_RADIUS"] == nil {
            node.reals["_SAMPLE_RADIUS"] = 32
        }
        if !scene.file.isEmpty {
            try map(game: game, scene: scene, node:node, rebuild: false)
        }
    }
    
    open override func handleUI(game: Game, scene: Scene, node: Node, ui: UI, reset: Bool) throws {
        var linear = true
        
        scene.root.traverse({ node in
            if !node.texture2.isEmpty && node.lightMapEnabled {
                linear = node.texture2Linear
                return false
            }
            return true
        })
        
        if let result = ui.field(key: "LightMapper.width.field", gap: 0, width: 75, caption: "Width", intValue: node.integers["_WIDTH"]!, reset: reset) {
            node.integers["_WIDTH"] = min(max(64, result), 1204)
        }
        ui.addRow(gap: 5)
        if let result = ui.field(key: "LightMapper.height.field", gap: 0, width: 75, caption: "Height", intValue: node.integers["_HEIGHT"]!, reset: reset) {
            node.integers["_HEIGHT"] = min(max(64, result), 1204)
        }
        ui.addRow(gap: 5)
        if let result = ui.field(key: "LightMapper.samples.field", gap: 0, width: 75, caption: "Samples", intValue: node.integers["_SAMPLES"]!, reset: reset) {
            node.integers["_SAMPLES"] = min(max(1, result), 128)
        }
        ui.addRow(gap: 5)
        if let result = ui.field(key: "LightMapper.sample.radius.field", gap: 0, width: 75, caption: "Sample Radius", realValue: node.reals["_SAMPLE_RADIUS"]!, reset: reset) {
            node.reals["_SAMPLE_RADIUS"] = min(max(1, result), 512)
        }
        ui.addRow(gap: 5)
        if ui.button(key: "LightMapper.linear.button", gap: 0, caption: "Linear", selected: linear) {
            linear.toggle()
            scene.root.traverse({ n in
                n.texture2Linear = linear
                
                return true
            })
        }
        if ui.button(key: "LightMapper.clear.button", gap: 5, caption: "Clear", selected: false) {
            scene.root.traverse({ n in
                n.texture2 = ""
                
                return true
            })
            
            let name = NSString(string: NSString(string: scene.file).lastPathComponent).deletingPathExtension
            let path = "\(name).png"
            let url = game.assets.baseURL.appendingPathComponent(path)
            
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        }
        ui.addRow(gap: 5)
        if ui.button(key: "LightMapper.map.button", gap: 0, caption: "Map", selected: false) {
            try map(game: game, scene: scene, node:node, rebuild: true)
        }
    }
    
    open func map(game: Game, scene: Scene, node: Node, rebuild:Bool) throws {
        let name = NSString(string: NSString(string: scene.file).lastPathComponent).deletingPathExtension
        let path = "\(name).png"
        let url = game.assets.baseURL.appendingPathComponent(path)
        let w = node.integers["_WIDTH"]!
        let h = node.integers["_HEIGHT"]!
        let samples = node.integers["_SAMPLES"]!
        let sradius = node.reals["_SAMPLE_RADIUS"]!
        var rgba:[UInt8]?
        var rb = rebuild
        var lights=[Node]()
        var meshes=[Node]()
        var triangles=[Triangle]()
        var x:Int=0
        var y:Int=0
        var mh:Int=0
        
        if !FileManager.default.fileExists(atPath: url.path) {
            rb = true
        }
        
        if rb {
            Log.put(1, "\(w) x \(h) ...")
            Log.put(1, "...")
            
            rgba = [UInt8].init(repeating: 255, count: w * h * 4)
        }
        
        scene.root.calcModel(parent: nil)
        
        scene.root.traverse({ n in
            if n.isLight {
                lights.append(n)
            }
            if n.lightMapEnabled {
                if n.drawIndices != 0 {
                    meshes.append(n)
                    if n.castsShadow {
                        for i in 0..<n.drawIndices/3 {
                            let p1 = n.vertices[n.indices[i * 3 + 0]].position
                            let p2 = n.vertices[n.indices[i * 3 + 1]].position
                            let p3 = n.vertices[n.indices[i * 3 + 2]].position
                            var triangle = Triangle(p1, p2, p3)
                            
                            triangle.transform(m: n.model)
                            triangles.append(triangle)
                        }
                    }
                }
            }
            return true
        })
        
        for mesh in meshes {
            for f in mesh.faces {
                if f.count == 4 {
                    var v1 = mesh.vertices[f[0]]
                    var v2 = mesh.vertices[f[1]]
                    var v3 = mesh.vertices[f[2]]
                    var v4 = mesh.vertices[f[3]]
                    let p1 = Vec3.transform(mesh.model, v1.position)
                    let p2 = Vec3.transform(mesh.model, v2.position)
                    let p3 = Vec3.transform(mesh.model, v3.position)
                    let p4 = Vec3.transform(mesh.model, v4.position)
                    let e1 = p2 - p1
                    let e2 = p3 - p2
                    var tw:Int = Int(e1.length / 16)
                    var th:Int = Int(e2.length / 16)
                    let error = "failed to allocate light map tile"
                    
                    tw = max(tw, 1)
                    th = max(th, 1)
                    
                    if x + tw >= w {
                        if mh == 0 || y + mh >= h {
                            Log.put(0, error)
                            return
                        }
                        x = 0
                        y = y + mh
                    }
                    if x + tw >= w || y + mh >= h {
                        Log.put(0, error)
                        return
                    }
                    mh = max(th, mh)
                    
                    v1.textureCoordinate2.x = (Float(x) + 0.5) / Float(w)
                    v1.textureCoordinate2.y = (Float(y) + 0.5) / Float(h)
                    
                    v2.textureCoordinate2.x = (Float(x + tw) - 0.5) / Float(w)
                    v2.textureCoordinate2.y = (Float(y) + 0.5) / Float(h)
                    
                    v3.textureCoordinate2.x = (Float(x + tw) - 0.5) / Float(w)
                    v3.textureCoordinate2.y = (Float(y + th) - 0.5) / Float(h)
                    
                    v4.textureCoordinate2.x = (Float(x) + 0.5) / Float(w)
                    v4.textureCoordinate2.y = (Float(y + th) - 0.5) / Float(h)
                    
                    mesh.vertices[f[0]] = v1
                    mesh.vertices[f[1]] = v2
                    mesh.vertices[f[2]] = v3
                    mesh.vertices[f[3]] = v4
                    
                    let n = Vec3.normalize(Vec3.transformNormal(Mat4.transpose(Mat4.invert(mesh.model)), v1.normal))
                    
                    if rb {
                        
                        Log.put(1, "mapping tile \(x), \(y) : \(tw) x \(th) ...")
                        
                        for i in x..<x+tw {
                            for j in y..<y+th {
                                let tx = (Float(i - x) + 0.5) / Float(tw)
                                let ty = (Float(j - y) + 0.5) / Float(th)
                                let a = p1 + tx * (p2 - p1)
                                let b = p4 + tx * (p3 - p4)
                                let p = a + ty * (b - a)
                                var c = mesh.ambientColor
                                
                                for light in lights {
                                    let lightOffset = light.absolutePosition - p
                                    let lightNormal = Vec3.normalize(lightOffset)
                                    let lDotN = min(max(Vec3.dot(lightNormal, n), 0), 1)
                                    let atten = 1 - min(max(lightOffset.length / light.lightRange, 0), 1)
                                    
                                    if atten > 0 && lDotN > 0 {
                                        var s:Float=1
                                        let maxR = 100000
                                        
                                        if mesh.receivesShadow {
                                            s = 0
       
                                            for _ in 0..<samples {
                                                let x = Float(Int.random(in: 0..<maxR)) / Float(maxR)
                                                let y = Float(Int.random(in: 0..<maxR)) / Float(maxR)
                                                let z = Float(Int.random(in: 0..<maxR)) / Float(maxR)
                                                var sample = Vec3(x, y, z)
                                                
                                                if sample.length < 0.0000001 {
                                                    sample = Vec3(0, 1, 0)
                                                }
                                                sample.normalize()
                                                
                                                let origin = p + n
                                                var direction = light.absolutePosition + sample * sradius - origin
                                                var time = direction.length
                                                var hit = false
                                                
                                                direction.normalize()
                                                
                                                for triangle in triangles {
                                                    if triangle.intersects(origin: origin, direction: direction, buffer: 0, time: &time) {
                                                        hit = true
                                                        break
                                                    }
                                                }
                                                if !hit {
                                                    s += 1 / Float(samples)
                                                }
                                            }
                                        }
                                        c = c + lDotN * atten * s * mesh.diffuseColor * light.lightColor
                                    }
                                }
                                
                                let m = max(c.x, max(c.y, c.z))
                                
                                if m > 1 {
                                    c = c / m
                                }
                                
                                let k = j * w * 4 + i * 4
                                
                                rgba![k + 0] = UInt8(c.x * 255)
                                rgba![k + 1] = UInt8(c.y * 255)
                                rgba![k + 2] = UInt8(c.z * 255)
                                rgba![k + 3] = 255
                            }
                        }
                    }
                    
                    x += tw
                } else {
                    Log.put(0, "Light map face is not a quad")
                }
            }
        }
        
        if let rgba = rgba {
            game.assets.save(Data(bytes: rgba, count: rgba.count), width: w, height: h, path: path)
            game.assets.unload(path)
        }
        scene.root.traverse({ n in
            if n.lightMapEnabled {
                n.texture2 = path
            }
            return true
        })
    }
}
