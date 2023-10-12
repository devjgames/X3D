//
//  Game.swift
//  X3D
//
//  Created by Douglas McNamara on 9/14/23.
//

import Foundation
import Metal
import MetalKit

public class Game : MTKView {
    
    public let animatorBase:String
    public var game:JSGame?
    
    private var _commandQueue:MTLCommandQueue?
    private var _library:MTLLibrary?
    private var _assets:AssetManager?
    private var _totalTime:Float=0
    private var _elapsedTime:Float=0
    private var _frameRate:Int=0
    private var _mouseX:Float=0
    private var _mouseY:Float=0
    private var _dX:Float=0
    private var _dY:Float=0
    private var _lastTime:Float=0
    private var _seconds:Float=0
    private var _frames:Int=0
    private var _keyState=[Bool]()
    private var _buttonState:[Bool]=[ false, false ]
    private let _keyCount:Int
    
    public init(frame:NSRect, animatorBase:String) throws {
        for _ in 0..<500 {
            _keyState.append(false)
        }
        _keyCount = _keyState.count
    
        self.animatorBase = animatorBase
        
        super.init(frame: frame, device: MTLCreateSystemDefaultDevice())
        
        self.device = device
        
        wantsLayer = true
        layer!.magnificationFilter = .nearest
        
        autoResizeDrawable = true
        colorPixelFormat = .rgba8Unorm
        depthStencilPixelFormat = .depth32Float

        drawableSize = frame.size
        
        autoresizingMask = .height.union(.width)
        
        _commandQueue = device!.makeCommandQueue()
        
        let url = Bundle(for: Game.self).resourceURL!.appendingPathComponent("default.metallib")
        
        _library =  try device!.makeLibrary(URL: url)
        
        _assets = AssetManager(self)
        
        becomeFirstResponder()
    }

    public required init(coder: NSCoder) {
        for _ in 0..<500 {
            _keyState.append(false)
        }
        _keyCount = _keyState.count
        
        animatorBase = ""
        
        super.init(coder: coder)
    }
    
    public override var canBecomeKeyView: Bool {
        true
    }
    
    public override var acceptsFirstResponder: Bool {
        true
    }
    
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
    
    public var width:Float {
        Float(drawableSize.width)
    }
    
    public var height:Float {
        Float(drawableSize.height)
    }
    
    public var aspectRatio:Float {
        Float(width) / Float(height)
    }
    
    public var commandQueue:MTLCommandQueue {
        _commandQueue!
    }
    
    public var library:MTLLibrary {
        _library!
    }
    
    public var assets:AssetManager {
        _assets!
    }
    
    public var totalTime:Float {
        _totalTime
    }
    
    public var elapsedTime:Float {
        _elapsedTime
    }
    
    public var frameRate:Int {
        _frameRate
    }
    
    public var mouseX:Float {
        _mouseX
    }
    
    public var mouseY:Float {
        _mouseY
    }
    
    public var dX:Float {
        _dX
    }
    
    public var dY:Float {
        _dY
    }
    
    public var keyCount:Int {
        _keyCount
    }
    
    private func handleMouse(event:NSEvent) {
        var p =  convert(event.locationInWindow, from: nil)
        
        p.y = frame.size.height - p.y - 1
        
        _mouseX = Float(p.x)
        _mouseY = Float(p.y)
    }
    
    public override func mouseDown(with event: NSEvent) {
        _buttonState[0] = true
        
        handleMouse(event: event)
    }
    
    public override func mouseUp(with event: NSEvent) {
        _buttonState[0] = false
    }
    
    public override func mouseDragged(with event: NSEvent) {
        _dX = -Float(event.deltaX)
        _dY = Float(event.deltaY)
        
        handleMouse(event: event)
    }
    
    public override func rightMouseDown(with event: NSEvent) {
        _buttonState[1] = true
        
        handleMouse(event: event)
    }
    
    public override func rightMouseUp(with event: NSEvent) {
        _buttonState[1] = false
    }
    
    public override func rightMouseDragged(with event: NSEvent) {
        _dX = Float(event.deltaX)
        _dY = Float(event.deltaY)
        
        handleMouse(event: event)
    }
    
    public override func keyDown(with event: NSEvent) {
        let key = Int(event.keyCode)
        
        if key >= 0 && key < keyCount {
            _keyState[key] = true
        }
    }
    
    public override func keyUp(with event: NSEvent) {
        let key = Int(event.keyCode)
        
        if key >= 0 && key < keyCount {
            _keyState[key] = false
        }
    }
    
    public func isButtonDown(_ button:Int) -> Bool {
        if button >= 0 && button < _buttonState.count {
            return _buttonState[button]
        }
        return false
    }
    
    public func isKeyDown(_ key:Int) -> Bool {
        if key >= 0 && key < keyCount {
            return _keyState[key]
        }
        return false
    }
    
    public func resetTimer() {
        _lastTime = Float(CACurrentMediaTime())
        _seconds = 0
        _frames = 0
        
        _totalTime = 0
        _elapsedTime = 0
        _frameRate = 0
    }
    
    public func tick() {
        let now = Float(CACurrentMediaTime())
        
        _elapsedTime = now - _lastTime
        _lastTime = now
        _totalTime += _elapsedTime
        _seconds += _elapsedTime
        _frames += 1
        
        if _seconds >= 1 {
            _frameRate = _frames
            _frames = 0
            _seconds = 0
        }
        _dX = 0
        _dY = 0
    }
}
