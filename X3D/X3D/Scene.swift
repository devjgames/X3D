//
//  Scene.swift
//  X3D
//
//  Created by Douglas McNamara on 9/14/23.
//

import Foundation
import Metal

public let MaxLights:Int=16

fileprivate var Lights=[Light](repeating: Light(position: Vec3().simd, color: Vec4().simd, range: 100), count: MaxLights)

public class Camera : Codable {
    
    public var eye=Vec3(100, 100, 100)
    public var target=Vec3()
    public var up=Vec3(0, 1, 0)
    public var fieldOfView:Float=60
    public var zNear:Float=0.2
    public var zFar:Float=10000
    public var projection=Mat4()
    public var view=Mat4()
    
    public init() {
    }
    
    public func move(point: Vec3, dX:Float, dY:Float, transform:Mat4) -> Vec3 {
        let offset = eye - target
        var f = offset * Vec3(-1, 0, -1)
        
        if f.length > 0.0000001 {
            f = Vec3.normalize(f)
            f = f * dY + Vec3.normalize(Vec3.cross(f, Vec3(0, 1, 0))) * dX
            f = Vec3.transformNormal(transform, f)
            
            return point + f
        }
        return point
    }

    public func move(dX:Float, dY:Float) {
        let offset = eye - target
        var f = offset * Vec3(-1, 0, -1)
        
        if f.length > 0.0000001 {
            f = Vec3.normalize(f)
            f = f * dY + Vec3.normalize(Vec3.cross(f, Vec3(0, 1, 0))) * dX
            
            target = target + f
        }
        eye = target + offset
    }
    
    public func move(point: Vec3, dY:Float, transform:Mat4) -> Vec3 {
        let f = Vec3.transformNormal(transform, Vec3(0, dY, 0))
    
        return point + f
    }
    
    public func move(dY:Float) {
        let offset = eye - target
        
        target = target + Vec3(0, dY, 0)
        
        eye = target + offset
    }
    
    public func zoom(amount:Float) {
        let offset = eye - target
        
        eye = target + Vec3.normalize(offset) * (offset.length + amount)
    }
    
    public func rotate(dX:Float, dY:Float) {
        var m = Mat4.rotation(dX, Vec3(0, 1, 0))
        var offset = eye - target
        let r = Vec3.normalize(Vec3.transformNormal(m, Vec3.cross(offset, up)))
        
        offset = Vec3.transformNormal(m, offset)
        m = Mat4.rotation(dY, r)
        up = Vec3.normalize(Vec3.transformNormal(m, Vec3.cross(r, offset)))
        
        eye = target + Vec3.transformNormal(m, offset)
    }
    
    public func calcTransforms(aspectRatio:Float) {
        projection = Mat4.perspective(fieldOfView, aspectRatio, zNear, zFar)
        view = Mat4.lookAt(eye, target, up)
    }
}

public struct Vertex : Codable {
    public var position=Vec3()
    public var textureCoordinate=Vec2()
    public var textureCoordinate2=Vec2()
    public var normal=Vec3()
    public var color=Vec4(1, 1, 1, 1)
    
    public init() {
    }
    
    public init(_ position:Vec3, _ textureCoordinate:Vec2, _ textureCoordinate2:Vec2, _ normal:Vec3, _ color:Vec4) {
        self.position = position
        self.textureCoordinate = textureCoordinate
        self.textureCoordinate2 = textureCoordinate2
        self.normal = normal
        self.color = color
    }
    
    fileprivate var simd:ShaderVertex {
        ShaderVertex(position: position.simd, textureCoordinate: textureCoordinate.simd, textureCoordinate2: textureCoordinate2.simd, normal: normal.simd, color: color.simd)
    }
}

fileprivate struct ShaderVertex {
    var position:simd_float3
    var textureCoordinate:simd_float2
    var textureCoordinate2:simd_float2
    var normal:simd_float3
    var color:simd_float4
}

fileprivate struct Light {
    var position:simd_float3
    var color:simd_float4
    var range:Float
}

fileprivate struct VertexData {
    var projection:simd_float4x4
    var view:simd_float4x4
    var model:simd_float4x4
    var modelIT:simd_float4x4
    var ambientColor:simd_float4
    var diffuseColor:simd_float4
    var color:simd_float4
    var vertexColorEnabled:UInt8
    var lightingEnabled:UInt8
    var lightCount:UInt8

    init() {
        projection = Mat4.identity.simd
        view = Mat4.identity.simd
        model = Mat4.identity.simd
        modelIT = Mat4.identity.simd
        ambientColor = Vec4().simd
        diffuseColor = Vec4().simd
        color = Vec4().simd
        vertexColorEnabled = 0
        lightingEnabled = 0
        lightCount = 0
    }
}

fileprivate struct FragmentData {
    var textureEnabled:UInt8
    var texture2Enabled:UInt8
    var texture2Linear:UInt8
}

fileprivate class VertexStack {
    
    public var vertices=[ShaderVertex]()
    public var vertexBuffer:MTLBuffer?
    
    private var _game:Game?
    
    init(_ game:Game, maxStack:Int) {
        Log.put(1, "Creating vertex stack \(maxStack) ...")
        
        vertexBuffer = game.device!.makeBuffer(length: maxStack * MemoryLayout<ShaderVertex>.stride, options: .storageModeManaged)
        
        _game = game
    }
    
    func buffer() {
        if vertices.count > 0 && vertices.count <= vertexBuffer!.length / MemoryLayout<ShaderVertex>.stride {
            memmove(vertexBuffer!.contents(), vertices, vertices.count * MemoryLayout<ShaderVertex>.stride)
            vertexBuffer!.didModifyRange(0..<vertices.count * MemoryLayout<ShaderVertex>.stride)
            
            let commandBuffer = _game!.commandQueue.makeCommandBuffer()!
            let encoder = commandBuffer.makeBlitCommandEncoder()!
            
            encoder.synchronize(resource: vertexBuffer!)
            encoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
        vertices.removeAll(keepingCapacity: true)
    }
}

open class Animator : Identifiable {
    
    public var id=UUID()
    
    public required init() {
    }
    
    open var isSingleton:Bool {
        false
    }
    
    open func setup(game:Game, scene:Scene, node:Node, inDesign:Bool) throws {
        if let jsGame = game.game, !inDesign {
            jsGame.activeNode = node
            jsGame.setup(game: game, scene: scene, node: node)
        }
    }
    
    open func update(game:Game, scene:Scene, node:Node, inDesign:Bool) throws {
        if let jsGame = game.game, !inDesign {
            jsGame.activeNode = node
            jsGame.update(game: game, scene: scene, node: node)
        }
    }
    
    open func handleUI(game:Game, scene:Scene, node:Node, ui:UI, reset:Bool) throws {
    }
}

public class Node : Codable, Identifiable, Hashable, Equatable, CustomStringConvertible {
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case visible
        case position
        case absolutePosition
        case rotation
        case scale
        case model
        case isLight
        case lightColor
        case lightRange
        case ambientColor
        case diffuseColor
        case color
        case lightingEnabled
        case vertexColorEnabled
        case lightMapEnabled
        case castsShadow
        case receivesShadow
        case collidable
        case dynamic
        case texture
        case texture2
        case texture2Linear
        case zOrder
        case cullEnabled
        case cullBack
        case blendEnabled
        case additiveBlend
        case depthTestEnabled
        case depthWriteEnabled
        case strings
        case integers
        case reals
        case bools
        case vec2
        case vec3
        case vec4
        case children
        case isSprite
        case animatorName
    }
    
    public var id=UUID()
    public var name="Node"
    public var visible=true
    public var position=Vec3()
    public var absolutePosition=Vec3()
    public var rotation=Mat4()
    public var scale=Vec3(1, 1, 1)
    public var model=Mat4()
    public var isLight=false
    public var lightColor=Vec4(1, 1, 1, 1)
    public var lightRange:Float=300
    public var ambientColor=Vec4(0, 0, 0, 1)
    public var diffuseColor=Vec4(1, 1, 1, 1)
    public var color=Vec4(1, 1, 1, 1)
    public var lightingEnabled=false
    public var vertexColorEnabled=false
    public var lightMapEnabled=false
    public var castsShadow=true
    public var receivesShadow=true
    public var collidable=false
    public var dynamic=false
    public var texture=""
    public var texture2=""
    public var texture2Linear=true
    public var zOrder:Int=0
    public var cullEnabled=true
    public var cullBack=true
    public var blendEnabled=false
    public var additiveBlend=true
    public var depthTestEnabled=true
    public var depthWriteEnabled=true
    public var strings=[String:String]()
    public var integers=[String:Int]()
    public var reals=[String:Float]()
    public var bools=[String:Bool]()
    public var vec2=[String:Vec2]()
    public var vec3=[String:Vec3]()
    public var vec4=[String:Vec4]()
    public var children=[Node]()
    public var isSprite=false
    public var animatorName=""
    public var animator:Animator?
    public var vertices=[Vertex]()
    public var indices=[Int]()
    public var faces=[[Int]]()
    public var drawIndices:Int=0
    
    private var _depthStencilState:MTLDepthStencilState?
    private var _renderPipelineState:MTLRenderPipelineState?
    private var _vertexStack:VertexStack?
    private var _bounds=BoundingBox()
    private var _localBounds=BoundingBox()
    
    public init() {
    }
    
    public var description: String {
        name
    }
    
    public var bounds:BoundingBox {
        _bounds
    }
    
    public var localBounds:BoundingBox {
        _localBounds
    }
    
    public func newInstance() -> Node {
        let node = Node()
        
        node.name = name
        node.visible = visible
        node.position = position
        node.absolutePosition = absolutePosition
        node.rotation = rotation
        node.scale = scale
        node.model = model
        node.isLight = isLight
        node.lightColor = lightColor
        node.lightRange = lightRange
        node.ambientColor = ambientColor
        node.diffuseColor = diffuseColor
        node.color = color
        node.lightingEnabled = lightingEnabled
        node.lightMapEnabled = lightMapEnabled
        node.vertexColorEnabled = vertexColorEnabled
        node.lightMapEnabled = lightMapEnabled
        node.castsShadow = castsShadow
        node.receivesShadow = receivesShadow
        node.collidable = collidable
        node.dynamic = dynamic
        node.texture = texture
        node.texture2 = texture2
        node.texture2Linear = texture2Linear
        node.zOrder = zOrder
        node.cullEnabled = cullEnabled
        node.cullBack = cullBack
        node.blendEnabled = blendEnabled
        node.additiveBlend = additiveBlend
        node.depthTestEnabled = depthTestEnabled
        node.depthWriteEnabled = depthWriteEnabled
        node.strings = strings
        node.integers = integers
        node.reals = reals
        node.bools = bools
        node.vec2 = vec2
        node.vec3 = vec3
        node.vec4 = vec4
        node.isSprite = isSprite
        node.animatorName = animatorName
        node.vertices = vertices
        node.indices = indices
        node.faces = faces
        node.drawIndices = drawIndices
        node._bounds = _bounds
        
        for child in children {
            node.children.append(child.newInstance())
        }
        return node
    }
    
    public func calcBounds() {
        _localBounds.clear()
        for i in 0..<drawIndices {
            _localBounds = _localBounds + vertices[indices[i]].position
        }
        _bounds = _localBounds
    }
    
    public func traverse(_ visit:(Node) -> Bool) {
        if visit(self) {
            for child in children {
                child.traverse(visit)
            }
        }
    }
    
    public func calcModel(parent:Node?) {
        model = Mat4.translation(position) * rotation * Mat4.scaling(scale)
        if let parent = parent {
            model = parent.model * model
        }
        absolutePosition = Vec3.transform(model, Vec3())
        _bounds = BoundingBox.transform(m: model, b: _localBounds)
        
        for child in children {
            child.calcModel(parent: self)
        }
    }
    
    public func setAnimator(game:Game, scene:Scene, inDesign:Bool, name:String) {
        animator = nil
        if !name.isEmpty {
            if let cls = Bundle.main.classNamed("\(game.animatorBase).\(name)") {
                if cls.isSubclass(of: Animator.self) {
                    let instance = (cls as! Animator.Type).init()
                    
                    do {
                        try instance.setup(game: game, scene: scene, node: self, inDesign: inDesign)
                        
                        animator = instance
                        animatorName = name
                        self.name = name
                    } catch {
                        animatorName = ""
                        animator = nil
                        Log.put(0, error)
                    }
                }
            }
        }
    }
    
    public func setup(game:Game, scene:Scene, inDesign:Bool) {
        setAnimator(game: game, scene: scene, inDesign: inDesign, name: animatorName)
        for child in children {
            child.setup(game: game, scene: scene, inDesign: inDesign)
        }
    }
    
    public func update(game:Game, scene:Scene, inDesign:Bool) {
        if let animator = animator {
            do {
                try animator.update(game: game, scene: scene, node: self, inDesign: inDesign)
            } catch {
                self.animator = nil
                Log.put(0, error)
            }
        }
        for child in children {
            child.update(game: game, scene: scene, inDesign: inDesign)
        }
    }
    
    public func handleUI(game:Game, scene:Scene, ui:UI, reset:Bool) {
        if let animator = animator {
            do {
                try animator.handleUI(game: game, scene: scene, node: self, ui: ui, reset: reset)
            } catch {
                self.animator = nil
                Log.put(0, error)
            }
        }
    }
    
    public func clearState() {
        _depthStencilState = nil
        _renderPipelineState = nil
    }
    
    public func push(_ face:[Int]) {
        let tris = face.count - 2
        
        for i in 0..<tris {
            indices.append(face[0])
            indices.append(face[i + 1])
            indices.append(face[i + 2])
        }
        faces.append(face)
    }
    
    public func allocQuadFaces(count:Int) {
        var i = 0
        
        faces.removeAll()
        indices.removeAll()
        vertices.removeAll()
        
        for _ in 0..<count {
            push([i, i + 1, i + 2, i + 3])
            i += 4
        }
    }
    
    public func allocTriFaces(count:Int) {
        var i = 0
        
        faces.removeAll()
        indices.removeAll()
        vertices.removeAll()
        
        for _ in 0..<count {
            push([i, i + 1, i + 2])
            i += 3
        }
    }
    
    public func push(_ game:Game, _ sx:Float, _ sy:Float, _ sw:Float, _ sh:Float, _ dx:Float, _ dy:Float, _ dw:Float, _ dh:Float, _ color:Vec4) throws {
        if texture.isEmpty || vertices.count / 4 == faces.count {
            return
        }
        let tex:MTLTexture = try game.assets.load(texture) as! MTLTexture
        let tw = Float(tex.width)
        let th = Float(tex.height)
        let sx1 = sx / tw
        let sy1 = sy / th
        let sx2 = (sx + sw) / tw
        let sy2 = (sy + sh) / th
        
        vertices.append(Vertex(Vec3(dx, dy, 0), Vec2(sx1, sy1), Vec2(), Vec3(), color))
        vertices.append(Vertex(Vec3(dx + dw, dy, 0), Vec2(sx2, sy1), Vec2(), Vec3(), color))
        vertices.append(Vertex(Vec3(dx + dw, dy + dh, 0), Vec2(sx2, sy2), Vec2(), Vec3(), color))
        vertices.append(Vertex(Vec3(dx, dy + dh, 0), Vec2(sx1, sy2), Vec2(), Vec3(), color))
        
        drawIndices += 6
    }
    
    public func push(_ game:Game, text:String, scale:Float, cw:Float, ch:Float, cols:Int, lineSpacing:Float, pos:Vec2, color:Vec4) throws {
        var x = pos.x
        var y = pos.y
        let sx = pos.x
        var s:Int = 0
        
        for c in " " {
            s = Int(c.asciiValue!)
        }
        
        for c in text {
            if c == "\n" {
                x = sx
                y = y + lineSpacing * scale + ch * scale
            } else {
                let i = Int(c.asciiValue!) - s
                
                if i >= 0 && i < 100 {
                    let row = i / cols
                    let col = i % cols
                    
                    try push(game, Float(col) * cw, Float(row) * ch, cw, ch, x, y, cw * scale, ch * scale, color)
                    x += cw * scale
                }
            }
        }
    }
    
    private func createState(game:Game) throws {
        if _depthStencilState == nil {
            Log.put(1, "Creating depth stencil state ...")
            
            let descriptor = MTLDepthStencilDescriptor()
            
            descriptor.isDepthWriteEnabled = depthWriteEnabled
            descriptor.depthCompareFunction = (depthTestEnabled) ? .less : .always
            
            _depthStencilState = game.device!.makeDepthStencilState(descriptor: descriptor)
        }
        if _renderPipelineState == nil {
            Log.put(1, "Creating render pipeline state ...")
            
            let descriptor = MTLRenderPipelineDescriptor()
            
            descriptor.vertexFunction = game.library.makeFunction(name: "vertexShader")
            descriptor.fragmentFunction = game.library.makeFunction(name: "fragmentShader")
            descriptor.colorAttachments[0].pixelFormat = game.colorPixelFormat
            descriptor.colorAttachments[0].isBlendingEnabled = blendEnabled
            descriptor.depthAttachmentPixelFormat = game.depthStencilPixelFormat
            if blendEnabled {
                descriptor.colorAttachments[0].rgbBlendOperation = .add
                descriptor.colorAttachments[0].alphaBlendOperation = .add
                if additiveBlend {
                    descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
                    descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
                    descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
                    descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
                } else {
                    descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                    descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
                    descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                    descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
                }
            }
            _renderPipelineState = try game.device!.makeRenderPipelineState(descriptor: descriptor)
        }
    }
    
    fileprivate func buffer(game:Game) {
        drawIndices = min(indices.count, drawIndices / 3 * 3)
        
        if drawIndices == 0 {
            return
        }
        
        if let stack = _vertexStack {
            if indices.count > stack.vertexBuffer!.length / MemoryLayout<ShaderVertex>.stride {
                _vertexStack = VertexStack(game, maxStack:indices.count)
            }
        } else {
            _vertexStack = VertexStack(game, maxStack: indices.count)
        }
        
        for i in 0..<drawIndices {
            _vertexStack!.vertices.append(vertices[indices[i]].simd)
        }
        _vertexStack!.buffer()
    }
    
    fileprivate func encode(game:Game, orthoProjection:Mat4, camera:Camera, lights:[Node], encoder:MTLRenderCommandEncoder) throws {
        
        if drawIndices == 0 {
            return
        }
        
        var vertexData = VertexData()
        let fragmentData = FragmentData(textureEnabled: (texture.isEmpty) ? 0 : 1, texture2Enabled: (texture2.isEmpty) ? 0  : 1, texture2Linear: (texture2Linear) ? 1 : 0)
        
        vertexData.projection = (isSprite) ? orthoProjection.simd : camera.projection.simd
        vertexData.view = (isSprite) ? Mat4.identity.simd : camera.view.simd
        vertexData.model = model.simd
        vertexData.modelIT = Mat4.transpose(Mat4.invert(model)).simd
        vertexData.lightCount = UInt8(min(MaxLights, lights.count))
        vertexData.vertexColorEnabled = (vertexColorEnabled) ? 1 : 0
        vertexData.lightingEnabled = (lightingEnabled) ? 1 : 0
        vertexData.ambientColor = ambientColor.simd
        vertexData.diffuseColor = diffuseColor.simd
        vertexData.color = color.simd
        
        for i in 0..<Int(vertexData.lightCount) {
            var light = Lights[i]
            
            light.position = lights[i].absolutePosition.simd
            light.color = lights[i].lightColor.simd
            light.range = lights[i].lightRange
            
            Lights[i] = light
        }
        
        try createState(game: game)
        
        if cullEnabled {
            if cullBack {
                encoder.setCullMode(.back)
            } else {
                encoder.setCullMode(.front)
            }
        } else {
            encoder.setCullMode(.none)
        }
        encoder.setDepthStencilState(_depthStencilState!)
        encoder.setRenderPipelineState(_renderPipelineState!)
        encoder.setVertexBuffer(_vertexStack!.vertexBuffer!, offset: 0, index: 0)
        encoder.setVertexBytes([ vertexData ], length: MemoryLayout<VertexData>.stride, index: 1)
        encoder.setVertexBytes(Lights, length: MemoryLayout<Light>.stride * MaxLights, index: 2)
        
        if fragmentData.textureEnabled != 0 {
            encoder.setFragmentTexture(try game.assets.load(texture) as? MTLTexture, index: 0)
        }
        if fragmentData.texture2Enabled != 0 {
            encoder.setFragmentTexture(try game.assets.load(texture2) as? MTLTexture, index: 1)
        }
        encoder.setFragmentBytes([ fragmentData ], length: MemoryLayout<FragmentData>.stride, index: 0)
        
        encoder.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: drawIndices)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func ==(lhs:Node, rhs:Node) -> Bool {
        lhs.id == rhs.id
    }
}

public class Scene : Codable {
    
    enum CodingKeys: CodingKey {
        case root
        case camera
        case backgroundColor
    }
    
    public var root=Node()
    public var camera=Camera()
    public var backgroundColor=Vec4(0.2, 0.2, 0.2, 1)
    
    private var _lights=[Node]()
    private var _encodables=[Node]()
    private var _file=""
    
    public init() {
    }
    
    public var file:String {
        _file
    }
    
    public func buffer(game:Game, aspectRatio:Float) {
        
        game.clearColor = MTLClearColor(red: Double(backgroundColor.x), green: Double(backgroundColor.y), blue: Double(backgroundColor.z), alpha: Double(backgroundColor.w))
        
        camera.calcTransforms(aspectRatio: aspectRatio)
        
        root.calcModel(parent: nil)
        
        root.traverse { node in
            if node.visible {
                if node.drawIndices != 0 {
                    node.buffer(game: game)
                    _encodables.append(node)
                }
                if node.isLight {
                    _lights.append(node)
                }
                return true
            }
            return false
        }
        
        _encodables.sort { a, b in
            if a.zOrder == b.zOrder {
                let dA = (a.absolutePosition - camera.eye).length
                let dB = (b.absolutePosition - camera.eye).length
                
                return dB < dA
            } else {
                return a.zOrder < b.zOrder
            }
        }
        _lights.sort { a, b in
            let dA = (a.absolutePosition - camera.eye).length
            let dB = (b.absolutePosition - camera.eye).length
            
            return dA < dB
        }
    }
    
    public func encode(game:Game, width:Float, height:Float, encoder:MTLRenderCommandEncoder) throws {
        let orthoProjection = Mat4.ortho(0, width, height, 0, -1, 1)
        
        for encodable in _encodables {
            try encodable.encode(game: game, orthoProjection: orthoProjection, camera: camera, lights: _lights, encoder: encoder)
        }
    }
    
    public func clear() {
        _lights.removeAll(keepingCapacity: true)
        _encodables.removeAll(keepingCapacity: true)
    }
    
    public func encode(game:Game, inDesign:Bool) throws {
        root.update(game: game, scene: self, inDesign: inDesign)
        
        buffer(game: game, aspectRatio: game.aspectRatio)
        
        if let drawable = game.currentDrawable {
            game.currentRenderPassDescriptor!.colorAttachments[0].texture = drawable.texture
            
            let commandBuffer = game.commandQueue.makeCommandBuffer()!
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: game.currentRenderPassDescriptor!)!
            
            encoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(game.width), height: Double(game.height), znear: 0, zfar: 1))
            
            try encode(game: game, width: game.width, height: game.height, encoder: encoder)
            
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
        clear()
    }
    
    public func save(_ baseUrl:URL, path:String) throws {
        try JSONEncoder().encode(self).write(to: baseUrl.appendingPathComponent(path))
    }
    
    public static func load(game:Game, inDesign:Bool, path:String) throws -> Scene {
        let scene = try JSONDecoder().decode(Scene.self, from: try Data(contentsOf: game.assets.baseURL.appendingPathComponent(path)))
        
        scene._file = path
        
        if let jsGame = game.game, !inDesign {
            scene.root.traverse({ node in
                if node.animatorName == "Player" {
                    jsGame.player = node
                    return false
                }
                return true
            })
        }
        
        scene.root.setup(game: game, scene: scene, inDesign: inDesign)
        
        return scene
    }
}
