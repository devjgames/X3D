//
//  KeyFrameMesh.swift
//  X3D
//
//  Created by Douglas McNamara on 9/14/23.
//

import Foundation

fileprivate struct MD2Header {
    var magic:Int32=0
    var version:Int32=0
    var skinW:Int32=0
    var skinH:Int32=0
    var frameSize:Int32=0
    var numSkins:Int32=0
    var numVertices:Int32=0
    var numTexCoords:Int32=0
    var numTris:Int32=0
    var numGLCmds:Int32=0
    var numFrames:Int32=0
    var offSkins:Int32=0
    var offTexCoords:Int32=0
    var offTris:Int32=0
    var offFrames:Int32=0
    var offGLCmds:Int32=0
    var offEnd:Int32=0
}

fileprivate struct MD2Vertex {
    var x:UInt8=0
    var y:UInt8=0
    var z:UInt8=0
    var n:UInt8=0
}

fileprivate struct MD2Frame {
    var scale:Vec3=Vec3()
    var translation:Vec3=Vec3()
    var name1:UInt8=0
    var name2:UInt8=0
    var name3:UInt8=0
    var name4:UInt8=0
    var name5:UInt8=0
    var name6:UInt8=0
    var name7:UInt8=0
    var name8:UInt8=0
    var name9:UInt8=0
    var name10:UInt8=0
    var name11:UInt8=0
    var name12:UInt8=0
    var name13:UInt8=0
    var name14:UInt8=0
    var name15:UInt8=0
    var name16:UInt8=0
}

fileprivate struct MD2Triangle {
    var v1:UInt16=0
    var v2:UInt16=0
    var v3:UInt16=0
    var t1:UInt16=0
    var t2:UInt16=0
    var t3:UInt16=0
}

fileprivate struct MD2TextureCoordinate {
    var s:Int16=0
    var t:Int16=0
}

public struct KeyFrameVertex {
    
    public var position:Vec3
    public var textureCoordinate:Vec2
    public var normal:Vec3
    
    public init() {
        position = Vec3()
        textureCoordinate = Vec2()
        normal = Vec3()
    }
    
    public init(position: Vec3, textureCoordinate: Vec2, normal: Vec3) {
        self.position = position
        self.textureCoordinate = textureCoordinate
        self.normal = normal
    }
}

public class KeyFrame {
    
    public var vertices=[KeyFrameVertex]()
    
    private var _bounds=BoundingBox()
    
    public init() {
    }
    
    public var bounds:BoundingBox {
        _bounds
    }
    
    public func calcBounds() {
        _bounds.clear()
        for v in vertices {
            _bounds = _bounds + v.position
        }
    }
}

public class KeyFrames {
    
    public var frames=[KeyFrame]()
    
    public init() {
    }
}

public class KeyFrameMesh {
    
    public var frames=KeyFrames()
    
    private var _start:Int=0
    private var _end:Int=0
    private var _speed:Int=0
    private var _looping:Bool=false
    private var _done:Bool=true
    private var _frame:Int=0
    private var _amount:Float=0
    fileprivate var _bounds=BoundingBox()

    public init() {
    }
    
    public var bounds:BoundingBox {
        _bounds
    }

    public var done:Bool {
        _done
    }
    
    public var start:Int {
        _start
    }
    
    public var end:Int {
        _end
    }
    
    public var speed:Int {
        _speed
    }
    
    public var looping:Bool {
        _looping
    }
    
    public var frame:Int {
        _frame
    }
    
    public var amount:Float {
        _amount
    }
    
    public func reset() {
        _frame = _start
        _amount = 0
        _done = _start == _end
        
        _bounds = frames.frames[_frame].bounds
    }
    
    public func setSequence(start:Int, end:Int, speed:Int, looping:Bool) {
        if start != _start || end != _end || speed != _speed || looping != _looping {
            if start >= 0 && start < frames.frames.count && end >= 0 && end < frames.frames.count && start <= end && speed >= 0 {
                _start = start
                _end = end
                _speed = speed
                _looping = looping
                
                reset()
            }
        }
    }
    
    public func update(game:Game) {
        if done {
            return
        }
        
        _amount += Float(speed) * game.elapsedTime
        
        if amount >= 1 {
            if looping {
                if frame == end {
                    _frame = start
                } else {
                    _frame += 1
                }
                _amount = 0
            } else {
                if frame == end - 1 {
                    _amount = 1
                    _done = true
                } else {
                    _frame += 1
                    _amount = 0
                }
            }
        }
        
        let f1 = _frame
        var f2 = _frame + 1
        
        if f1 == end {
            f2 = _start
        }
        
        let b1 = frames.frames[f1].bounds
        let b2 = frames.frames[f2].bounds
        
        _bounds.lo = b1.lo + amount * (b2.lo - b1.lo)
        _bounds.hi = b1.hi + amount * (b2.hi - b1.hi)
    }
    
    public func buffer(node:Node) {
        let f1 = _frame
        var f2 = _frame + 1
        
        if f1 == end {
            f2 = _start
        }
        
        node.drawIndices = frames.frames.first!.vertices.count
        
        if node.faces.isEmpty {
            node.allocTriFaces(count: node.drawIndices / 3)
        }
        
        node.vertices.removeAll(keepingCapacity: true)
        
        for i in 0..<node.drawIndices {
            let v1 = frames.frames[f1].vertices[i]
            let v2 = frames.frames[f2].vertices[i]
            
    
            node.vertices.append(Vertex(v1.position + amount * (v2.position - v1.position), v1.textureCoordinate, Vec2(), v1.normal + amount * (v2.normal - v1.normal), Vec4(1, 1, 1, 1)))
        }
    }
    
    public func newInstance() -> KeyFrameMesh {
        let mesh = KeyFrameMesh()
        
        mesh.frames = frames
        mesh._bounds = mesh.frames.frames.last!.bounds
        
        return mesh
    }
}

open class KeyFrameMeshAnimator : Animator {
    
    private static var _meshNames=[Any]()
    
    public static func populateAssets(url:URL) throws {
        let items = try FileManager.default.contentsOfDirectory(atPath: url.path)
        
        _meshNames.removeAll()
        for item in items {
            if NSString(string: item).pathExtension == "md2" {
                _meshNames.append(item)
            }
        }
    }
    
    private var _mesh:KeyFrameMesh?

    public var scripted=false
    
    public var mesh:KeyFrameMesh? {
        _mesh
    }
    
    open override func setup(game: Game, scene: Scene, node: Node, inDesign: Bool) throws {
        try loadMesh(game: game, node: node)
        
        if scripted {
            try super.setup(game: game, scene: scene, node: node, inDesign: inDesign)
        }
    }
    
    open override func update(game: Game, scene: Scene, node: Node, inDesign: Bool) throws {
        if let mesh = _mesh, let child = node.children.first {
            mesh.update(game: game)
            mesh.buffer(node: child)
        }
        
        if scripted {
            try super.update(game: game, scene: scene, node: node, inDesign: inDesign)
        }
    }
    
    open override func handleUI(game: Game, scene: Scene, node: Node, ui: UI, reset: Bool) throws {
        var sel = -2
        var resetFields = reset
        
        if reset {
            sel = -1
            if let path = node.strings["_PATH"] {
                let n = KeyFrameMeshAnimator._meshNames.count
                
                for i in 0..<n {
                    let name = KeyFrameMeshAnimator._meshNames[i]
                    
                    if name as? String == path {
                        sel = i
                        break
                    }
                }
            }
        }
        if let result = ui.list(key: "KeyFrameMeshAnimator.mesh.list", gap: 0, width: 225, height: 100, items: &KeyFrameMeshAnimator._meshNames, selected: sel) {
            let name = KeyFrameMeshAnimator._meshNames[result] as? String
            
            if name != node.strings["_PATH"] {
                
                node.strings["_PATH"] = name
                
                try loadMesh(game: game, node: node)
                
                resetFields = true
            }
        }
        
        if let mesh = _mesh, let child = node.children.first {
            let start = mesh.start
            let end = mesh.end
            let speed = mesh.speed
            
            ui.addRow(gap: 5)
            if let result = ui.field(key: "KeyFrameMeshAnimator.sequence.field", gap: 0, width: 150, caption: "Sequence", text: "\(start) \(end) \(speed)", reset: resetFields) {
                let tokens = result.components(separatedBy: CharacterSet.whitespaces)
                
                if tokens.count >= 3 {
                    if let start = Int(tokens[0]),
                       let end = Int(tokens[1]),
                       let speed = Int(tokens[2]) {
                        
                        mesh.setSequence(start: start, end: end, speed: speed, looping: true)
                        
                        node.integers["_START"] = start
                        node.integers["_END"] = end
                        node.integers["_SPEED"] = speed
                    }
                }
            }
            
            ui.addRow(gap: 5)
            if let result = ui.field(key: "KeyFrameMeshAnimator.sequence.ambient.field", gap: 0, width: 150, caption: "Ambient", vec4Value: child.ambientColor, reset: resetFields) {
                child.ambientColor = result
            }
            
            ui.addRow(gap: 5)
            if let result = ui.field(key: "KeyFrameMeshAnimator.sequence.diffuse.field", gap: 0, width: 150, caption: "Diffuse", vec4Value: child.diffuseColor, reset: resetFields) {
                child.diffuseColor = result
            }
        }
    }
    
    private func loadMesh(game: Game, node: Node) throws {
        if let path = node.strings["_PATH"] {
            var child = Node()
            let tex = "\(NSString(string: path).deletingPathExtension).png"
            
            _mesh = try game.assets.load(path) as? KeyFrameMesh
            _mesh = _mesh!.newInstance()
            
            if let c = node.children.first {
                child = c
            } else {
                node.children = [ child ]
            }
            
            if FileManager.default.fileExists(atPath: game.assets.baseURL.appendingPathComponent(tex).path) {
                child.texture = tex
            }
            child.lightingEnabled = true
            child.rotation = Mat4.rotation(-90, Vec3(1, 0, 0))
            
            if let start = node.integers["_START"],
               let end = node.integers["_END"],
               let speed = node.integers["_SPEED"] {
                
                _mesh!.setSequence(start: start, end: end, speed: speed, looping: true)
                
            } else {
                _mesh!.setSequence(start: 0, end: 0, speed: 0, looping: false)
                
                node.integers["_START"] = 0
                node.integers["_END"] = 0
                node.integers["_SPEED"] = 0
            }
        } else {
            node.children = []
        }
    }
}

public class KeyFrameMeshLoader : AssetLoader {
    
    public override init() {
    }
    
    public override func load(_ url: URL, path: String, assets: AssetManager) throws -> Any? {
        let data = NSData(contentsOf: url)
        var tris=[MD2Triangle]()
        var texCoords=[MD2TextureCoordinate]()
        var header=[ MD2Header() ]
        
        memmove(&header, data!.bytes, MemoryLayout<MD2Header>.size)
        
        tris = [MD2Triangle].init(repeating: MD2Triangle(), count: Int(header.first!.numTris))
        memmove(&tris, data!.bytes + Int(header.first!.offTris), MemoryLayout<MD2Triangle>.stride * Int(header.first!.numTris))
        
        texCoords = [MD2TextureCoordinate].init(repeating: MD2TextureCoordinate(), count: Int(header.first!.numTexCoords))
        memmove(&texCoords, data!.bytes + Int(header.first!.offTexCoords), MemoryLayout<MD2TextureCoordinate>.stride * Int(header.first!.numTexCoords))
        
        let mesh = KeyFrameMesh()
        
        for i in 0..<Int(header.first!.numFrames) {
            var frame=[MD2Frame].init(repeating: MD2Frame(), count: 1)
            var vertices=[MD2Vertex].init(repeating: MD2Vertex(), count: Int(header.first!.numVertices))
            
            memmove(&frame, data!.bytes + Int(header.first!.offFrames) + Int(header.first!.frameSize) * i, MemoryLayout<MD2Frame>.size)
            memmove(&vertices, data!.bytes + Int(header.first!.offFrames) + Int(header.first!.frameSize) * i + MemoryLayout<MD2Frame>.size, MemoryLayout<MD2Vertex>.stride * Int(header.first!.numVertices))
            
            mesh.frames.frames.append(KeyFrame())
            mesh.frames.frames.last!.vertices = [KeyFrameVertex].init(repeating: KeyFrameVertex(), count: Int(header.first!.numTris) * 3)
            
            for i in 0..<tris.count {
                let v1 = vertices[Int(tris[i].v1)]
                let v2 = vertices[Int(tris[i].v2)]
                let v3 = vertices[Int(tris[i].v3)]
                let t1 = texCoords[Int(tris[i].t1)]
                let t2 = texCoords[Int(tris[i].t2)]
                let t3 = texCoords[Int(tris[i].t3)]
                let p1 = Vec3(Float(v1.x), Float(v1.y), Float(v1.z)) * frame.first!.scale + frame.first!.translation
                let p2 = Vec3(Float(v2.x), Float(v2.y), Float(v2.z)) * frame.first!.scale + frame.first!.translation
                let p3 = Vec3(Float(v3.x), Float(v3.y), Float(v3.z)) * frame.first!.scale + frame.first!.translation
                let u1 = Vec2(Float(t1.s), Float(t1.t)) / Vec2(Float(header.first!.skinW), Float(header.first!.skinH))
                let u2 = Vec2(Float(t2.s), Float(t2.t)) / Vec2(Float(header.first!.skinW), Float(header.first!.skinH))
                let u3 = Vec2(Float(t3.s), Float(t3.t)) / Vec2(Float(header.first!.skinW), Float(header.first!.skinH))
                let n1 = normals[Int(v1.n)]
                let n2 = normals[Int(v2.n)]
                let n3 = normals[Int(v3.n)]
                
                mesh.frames.frames.last!.vertices[i * 3 + 0] = KeyFrameVertex(position: p1, textureCoordinate: u1, normal: n1)
                mesh.frames.frames.last!.vertices[i * 3 + 1] = KeyFrameVertex(position: p2, textureCoordinate: u2, normal: n2)
                mesh.frames.frames.last!.vertices[i * 3 + 2] = KeyFrameVertex(position: p3, textureCoordinate: u3, normal: n3)
            }
            mesh.frames.frames.last!.calcBounds()
        }
        mesh._bounds = mesh.frames.frames.first!.bounds
        
        return mesh
    }
}

fileprivate var normals:[Vec3] = [
    Vec3(-0.525731, 0.000000, 0.850651),
        Vec3(-0.442863, 0.238856, 0.864188),
        Vec3(-0.295242, 0.000000, 0.955423),
        Vec3(-0.309017, 0.500000, 0.809017),
        Vec3(-0.162460, 0.262866, 0.951056),
        Vec3(0.000000, 0.000000, 1.000000),
        Vec3(0.000000, 0.850651, 0.525731),
        Vec3(-0.147621, 0.716567, 0.681718),
        Vec3(0.147621, 0.716567, 0.681718),
        Vec3(0.000000, 0.525731, 0.850651),
        Vec3(0.309017, 0.500000, 0.809017),
        Vec3(0.525731, 0.000000, 0.850651),
        Vec3(0.295242, 0.000000, 0.955423),
        Vec3(0.442863, 0.238856, 0.864188),
        Vec3(0.162460, 0.262866, 0.951056),
        Vec3(-0.681718, 0.147621, 0.716567),
        Vec3(-0.809017, 0.309017, 0.500000),
        Vec3(-0.587785, 0.425325, 0.688191),
        Vec3(-0.850651, 0.525731, 0.000000),
        Vec3(-0.864188, 0.442863, 0.238856),
        Vec3(-0.716567, 0.681718, 0.147621),
        Vec3(-0.688191, 0.587785, 0.425325),
        Vec3(-0.500000, 0.809017, 0.309017),
        Vec3(-0.238856, 0.864188, 0.442863),
        Vec3(-0.425325, 0.688191, 0.587785),
        Vec3(-0.716567, 0.681718, -0.147621),
        Vec3(-0.500000, 0.809017, -0.309017),
        Vec3(-0.525731, 0.850651, 0.000000),
        Vec3(0.000000, 0.850651, -0.525731),
        Vec3(-0.238856, 0.864188, -0.442863),
        Vec3(0.000000, 0.955423, -0.295242),
        Vec3(-0.262866, 0.951056, -0.162460),
        Vec3(0.000000, 1.000000, 0.000000),
        Vec3(0.000000, 0.955423, 0.295242),
        Vec3(-0.262866, 0.951056, 0.162460),
        Vec3(0.238856, 0.864188, 0.442863),
        Vec3(0.262866, 0.951056, 0.162460),
        Vec3(0.500000, 0.809017, 0.309017),
        Vec3(0.238856, 0.864188, -0.442863),
        Vec3(0.262866, 0.951056, -0.162460),
        Vec3(0.500000, 0.809017, -0.309017),
        Vec3(0.850651, 0.525731, 0.000000),
        Vec3(0.716567, 0.681718, 0.147621),
        Vec3(0.716567, 0.681718, -0.147621),
        Vec3(0.525731, 0.850651, 0.000000),
        Vec3(0.425325, 0.688191, 0.587785),
        Vec3(0.864188, 0.442863, 0.238856),
        Vec3(0.688191, 0.587785, 0.425325),
        Vec3(0.809017, 0.309017, 0.500000),
        Vec3(0.681718, 0.147621, 0.716567),
        Vec3(0.587785, 0.425325, 0.688191),
        Vec3(0.955423, 0.295242, 0.000000),
        Vec3(1.000000, 0.000000, 0.000000),
        Vec3(0.951056, 0.162460, 0.262866),
        Vec3(0.850651, -0.525731, 0.000000),
        Vec3(0.955423, -0.295242, 0.000000),
        Vec3(0.864188, -0.442863, 0.238856),
        Vec3(0.951056, -0.162460, 0.262866),
        Vec3(0.809017, -0.309017, 0.500000),
        Vec3(0.681718, -0.147621, 0.716567),
        Vec3(0.850651, 0.000000, 0.525731),
        Vec3(0.864188, 0.442863, -0.238856),
        Vec3(0.809017, 0.309017, -0.500000),
        Vec3(0.951056, 0.162460, -0.262866),
        Vec3(0.525731, 0.000000, -0.850651),
        Vec3(0.681718, 0.147621, -0.716567),
        Vec3(0.681718, -0.147621, -0.716567),
        Vec3(0.850651, 0.000000, -0.525731),
        Vec3(0.809017, -0.309017, -0.500000),
        Vec3(0.864188, -0.442863, -0.238856),
        Vec3(0.951056, -0.162460, -0.262866),
        Vec3(0.147621, 0.716567, -0.681718),
        Vec3(0.309017, 0.500000, -0.809017),
        Vec3(0.425325, 0.688191, -0.587785),
        Vec3(0.442863, 0.238856, -0.864188),
        Vec3(0.587785, 0.425325, -0.688191),
        Vec3(0.688191, 0.587785, -0.425325),
        Vec3(-0.147621, 0.716567, -0.681718),
        Vec3(-0.309017, 0.500000, -0.809017),
        Vec3(0.000000, 0.525731, -0.850651),
        Vec3(-0.525731, 0.000000, -0.850651),
        Vec3(-0.442863, 0.238856, -0.864188),
        Vec3(-0.295242, 0.000000, -0.955423),
        Vec3(-0.162460, 0.262866, -0.951056),
        Vec3(0.000000, 0.000000, -1.000000),
        Vec3(0.295242, 0.000000, -0.955423),
        Vec3(0.162460, 0.262866, -0.951056),
        Vec3(-0.442863, -0.238856, -0.864188),
        Vec3(-0.309017, -0.500000, -0.809017),
        Vec3(-0.162460, -0.262866, -0.951056),
        Vec3(0.000000, -0.850651, -0.525731),
        Vec3(-0.147621, -0.716567, -0.681718),
        Vec3(0.147621, -0.716567, -0.681718),
        Vec3(0.000000, -0.525731, -0.850651),
        Vec3(0.309017, -0.500000, -0.809017),
        Vec3(0.442863, -0.238856, -0.864188),
        Vec3(0.162460, -0.262866, -0.951056),
        Vec3(0.238856, -0.864188, -0.442863),
        Vec3(0.500000, -0.809017, -0.309017),
        Vec3(0.425325, -0.688191, -0.587785),
        Vec3(0.716567, -0.681718, -0.147621),
        Vec3(0.688191, -0.587785, -0.425325),
        Vec3(0.587785, -0.425325, -0.688191),
        Vec3(0.000000, -0.955423, -0.295242),
        Vec3(0.000000, -1.000000, 0.000000),
        Vec3(0.262866, -0.951056, -0.162460),
        Vec3(0.000000, -0.850651, 0.525731),
        Vec3(0.000000, -0.955423, 0.295242),
        Vec3(0.238856, -0.864188, 0.442863),
        Vec3(0.262866, -0.951056, 0.162460),
        Vec3(0.500000, -0.809017, 0.309017),
        Vec3(0.716567, -0.681718, 0.147621),
        Vec3(0.525731, -0.850651, 0.000000),
        Vec3(-0.238856, -0.864188, -0.442863),
        Vec3(-0.500000, -0.809017, -0.309017),
        Vec3(-0.262866, -0.951056, -0.162460),
        Vec3(-0.850651, -0.525731, 0.000000),
        Vec3(-0.716567, -0.681718, -0.147621),
        Vec3(-0.716567, -0.681718, 0.147621),
        Vec3(-0.525731, -0.850651, 0.000000),
        Vec3(-0.500000, -0.809017, 0.309017),
        Vec3(-0.238856, -0.864188, 0.442863),
        Vec3(-0.262866, -0.951056, 0.162460),
        Vec3(-0.864188, -0.442863, 0.238856),
        Vec3(-0.809017, -0.309017, 0.500000),
        Vec3(-0.688191, -0.587785, 0.425325),
        Vec3(-0.681718, -0.147621, 0.716567),
        Vec3(-0.442863, -0.238856, 0.864188),
        Vec3(-0.587785, -0.425325, 0.688191),
        Vec3(-0.309017, -0.500000, 0.809017),
        Vec3(-0.147621, -0.716567, 0.681718),
        Vec3(-0.425325, -0.688191, 0.587785),
        Vec3(-0.162460, -0.262866, 0.951056),
        Vec3(0.442863, -0.238856, 0.864188),
        Vec3(0.162460, -0.262866, 0.951056),
        Vec3(0.309017, -0.500000, 0.809017),
        Vec3(0.147621, -0.716567, 0.681718),
        Vec3(0.000000, -0.525731, 0.850651),
        Vec3(0.425325, -0.688191, 0.587785),
        Vec3(0.587785, -0.425325, 0.688191),
        Vec3(0.688191, -0.587785, 0.425325),
        Vec3(-0.955423, 0.295242, 0.000000),
        Vec3(-0.951056, 0.162460, 0.262866),
        Vec3(-1.000000, 0.000000, 0.000000),
        Vec3(-0.850651, 0.000000, 0.525731),
        Vec3(-0.955423, -0.295242, 0.000000),
        Vec3(-0.951056, -0.162460, 0.262866),
        Vec3(-0.864188, 0.442863, -0.238856),
        Vec3(-0.951056, 0.162460, -0.262866),
        Vec3(-0.809017, 0.309017, -0.500000),
        Vec3(-0.864188, -0.442863, -0.238856),
        Vec3(-0.951056, -0.162460, -0.262866),
        Vec3(-0.809017, -0.309017, -0.500000),
        Vec3(-0.681718, 0.147621, -0.716567),
        Vec3(-0.681718, -0.147621, -0.716567),
        Vec3(-0.850651, 0.000000, -0.525731),
        Vec3(-0.688191, 0.587785, -0.425325),
        Vec3(-0.587785, 0.425325, -0.688191),
        Vec3(-0.425325, 0.688191, -0.587785),
        Vec3(-0.425325, -0.688191, -0.587785),
        Vec3(-0.587785, -0.425325, -0.688191),
        Vec3(-0.688191, -0.587785, -0.425325)
];
