//
//  GameEditor.swift
//  X3D
//
//  Created by Douglas McNamara on 9/17/23.
//

import Foundation

fileprivate enum EditorType {
    case none
    case node
    case addScene
    case loadScene
    case map
}

fileprivate enum EditorMode : String, CaseIterable {
    case zoom = "Zoom"
    case rot = "Rot"
    case panXZ = "PanXZ"
    case panY = "PanY"
    case movXZ = "MovXZ"
    case movY = "MovY"
    case rotY = "RotY"
    case scale = "Scale"
}

public class GameEditor : NSObject, MTKViewDelegate {
    
    private weak var _window:NSWindow?
    private var _game:Game
    private var _uiN:UI
    private var _uiS:UI
    private var _uiE:UI
    private var _uiW:UI
    private var _resetEditor=false
    private var _playing=false
    private var _nodes=[Any]()
    private var _scenes=[Any]()
    private var _animators=[Any]()
    private var _scene=Scene()
    private var _editScene:String?
    private var _editorType=EditorType.none
    private var _selection:Node?
    private var _clipboard:Node?
    private var _selScene:Int = -2
    private var _selNode:Int = -2
    private var _animator:Int=0
    private var _selAnimator:Int=0
    private var _mode=EditorMode.zoom
    private var _snap:Int=1
    private var _addScenePath:String?
    private var _down=false
    private var _dark=true
    
    public init(window: NSWindow, assetRoot:URL, animatorBase:String, animators:[String]) throws {
        _game = try Game(frame: window.contentView!.frame, animatorBase: animatorBase)
        _game.assets.baseURL = assetRoot
        
        window.backgroundColor = NSColor.darkGray
        window.contentView!.addSubview(_game)
        
        _uiN = UI()
        _uiS = UI()
        _uiE = UI()
        _uiW = UI()
        
        _animators.append(contentsOf: animators)
        
        _window = window
        
        super.init()
        
        _game.delegate = self
        
        listScenes()
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    public func draw(in view: MTKView) {
        do {
            try _scene.encode(game: _game, inDesign: !_playing)
        } catch {
            Log.put(0, error)
        }
        
        if _playing {
            _uiN.panel.removeFromSuperview()
            _uiS.panel.removeFromSuperview()
            _uiE.panel.removeFromSuperview()
            _uiW.panel.removeFromSuperview()
            
            UI.layout(gap: 0, center: _game, north: nil, south: nil, east: nil, west: nil)
            
            if _game.isKeyDown(53) {
                _playing = false

                _scene = Scene()
            }
        } else {
            _uiN.begin()
            if _uiN.button(key: "GameEditor.add.scene.button", gap: 0, caption: "+Scene", selected: _editorType == EditorType.addScene) {
                _editorType = EditorType.addScene
            }
            if _uiN.button(key: "GameEditor.load.scene.button", gap: 5, caption: "Load", selected: _editorType == EditorType.loadScene) {
                _editorType = EditorType.loadScene
                _selScene = -1
            }
            if let name = _editScene {
                if _uiN.button(key: "GameEditor.save.scene.button", gap: 5, caption: "Save", selected: false) {
                    do {
                        try _scene.save(_game.assets.baseURL, path: name)
                    } catch {
                        Log.put(0, error)
                    }
                }
                if _uiN.button(key: "GameEditor.play.button", gap: 5, caption: "Play", selected: false) {
                    _playing = true
                    _editScene = nil
                    _selection = nil
                    _editorType = EditorType.none
                    
                    do {
                        _game.assets.clear()
                        _scene = try Scene.load(game: _game, inDesign: false, path: name)
                        _game.resetTimer()
                    } catch {
                        Log.put(0, error)
                    }
                }
                if _uiN.button(key: "GameEditor.add.node.button", gap: 5, caption: "+Node", selected: false) {
                    _selection = Node()
                    _selection!.setAnimator(game: _game, scene: _scene, inDesign: true, name: _animators[_animator] as! String)
                    _scene.root.children.append(_selection!)
                    _nodes.removeAll()
                    _nodes.append(contentsOf: _scene.root.children)
                    _selNode = _nodes.count - 1
                    _editorType = EditorType.node
                    _resetEditor = true
                }
                if let clipboard = _clipboard {
                    if _uiN.button(key: "GameEditor.paste.button", gap: 5, caption: "Paste", selected: false) {
                        _selection = clipboard.newInstance()
                        _selection!.setup(game: _game, scene: _scene, inDesign: true)
                        _scene.root.children.append(_selection!)
                        _nodes.removeAll()
                        _nodes.append(contentsOf: _scene.root.children)
                        _selNode = _nodes.count - 1
                        _editorType = EditorType.node
                        _resetEditor = true
                    }
                }
                if _uiN.button(key: "GameEditor.map.scene.button", gap: 5, caption: "Map", selected: _editorType == EditorType.map) {
                    _editorType = EditorType.map
                    _resetEditor = true
                }
                for mode in EditorMode.allCases {
                    if _uiN.button(key: "Game.mode.\(mode).scene.button", gap: 5, caption: mode.rawValue, selected: _mode == mode) {
                        _mode = mode
                    }
                }
            }
            if _uiN.button(key: "GameEditor.dark.button", gap: 5, caption: "Dark", selected: _dark) {
                _dark.toggle()
                if _dark {
                    UIButtonColor = NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
                    _window!.backgroundColor = NSColor.darkGray
                } else {
                    UIButtonColor = NSColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1)
                    _window!.backgroundColor = NSColor.gray
                }
            }
            _uiN.end()
            
            _uiW.begin()
            if let _ = _editScene {
                if let result = _uiW.list(key: "GameEditor.node.list", gap: 0, width: 200, height: _game.frame.height - 205, items: &_nodes, selected: _selNode) {
                    _selection = _scene.root.children[result]
                    _editorType = EditorType.node
                    _resetEditor = true
                }
                _uiW.addRow(gap: 5)
                if let result = _uiW.list(key: "GameEditor.animator.list", gap: 0, width: 200, height: 200, items: &_animators, selected: _selAnimator) {
                    _animator = result
                }
                _selAnimator = -2
                _selNode = -2
            }
            _uiW.end()
            
            _uiE.begin()
            if let selection = _selection, _editorType == EditorType.node {
                selection.handleUI(game: _game, scene: _scene, ui: _uiE, reset: _resetEditor)
                _resetEditor = false
            } else if _editorType == EditorType.addScene {
                if let result = _uiE.field(key: "GameEditor.add.scene.name.field", gap: 0, width: 100, caption: "Name", text: "", reset: false) {
                    _addScenePath = "\(result.trimmingCharacters(in: CharacterSet.whitespaces)).json"
                }
                if let path = _addScenePath {
                    if path != ".json" {
                        let url = _game.assets.baseURL.appendingPathComponent(path)
                        
                        if !FileManager.default.fileExists(atPath: url.path) {
                            _uiE.addRow(gap: 5)
                            if _uiE.button(key: "GameEditor.save.add.scene.button", gap: 0, caption: "Save", selected: false) {
                                let scene=Scene()
                                
                                do {
                                    try scene.save(_game.assets.baseURL, path: path)
                                    
                                    _editorType = EditorType.none
                                    
                                    listScenes()
                                    
                                    _selScene = -1
                                } catch {
                                    Log.put(0, error)
                                }
                            }
                        }
                    }
                }
            } else if _editorType == EditorType.loadScene {
                if let result = _uiE.list(key: "GameEditor.scene.list", gap: 0, width: 200, height: 200, items: &_scenes, selected: _selScene) {
                    do {
                        _editScene = "\(_scenes[result]).json"
                        _game.assets.clear()
                        _scene = try Scene.load(game: _game, inDesign: true, path: _editScene!)
                        _nodes.removeAll()
                        _nodes.append(contentsOf: _scene.root.children)
                        _selNode = -1
                        _selection = nil
                        _editorType = EditorType.none
                    } catch {
                        Log.put(0, error)
                    }
                }
                _selScene = -2
            } else if _editorType == EditorType.map {
                if let _ = _uiE.field(key: "GameEditor.map.width.button", gap: 0, width: 75, caption: "Width", intValue: 128, reset: _resetEditor) {
                    // TODO
                }
                _uiE.addRow(gap: 5)
                if let _ = _uiE.field(key: "GameEditor.map.height.button", gap: 0, width: 75, caption: "Height", intValue: 128, reset: _resetEditor) {
                    // TODO
                }
                _uiE.addRow(gap: 5)
                if let _ = _uiE.field(key: "GameEditor.map.samples.button", gap: 0, width: 75, caption: "Samples", intValue: 32, reset: _resetEditor) {
                    // TODO
                }
                _uiE.addRow(gap: 5)
                if let _ = _uiE.field(key: "GameEditor.map.sample.radius.button", gap: 0, width: 75, caption: "Radius", realValue: 32, reset: _resetEditor) {
                    // TODO
                }
                _uiE.addRow(gap: 5)
                if _uiE.button(key: "GameEditor.map.linear.button", gap: 0, caption: "Linear", selected: false) {
                    // TODO
                }
                if _uiE.button(key: "GameEditor.map.clear.button", gap: 5, caption: "Clear", selected: false) {
                    // TODO
                }
                _uiE.addRow(gap: 5)
                if _uiE.button(key: "GameEditor.map.button", gap: 0, caption: "Map", selected: false) {
                    // TODO
                }
                _resetEditor = false
            }
            _uiE.end()
            
            _uiS.begin()
            if let selection = _selection {
                if let snap = _uiS.field(key: "GameEditor.snap.button", gap: 0, width: 50, caption: "Snap", intValue: _snap, reset: _resetEditor) {
                    _snap = snap
                }
                if _uiS.button(key: "GameEditor.copy.button", gap: 5, caption: "Copy", selected: false) {
                    _clipboard = selection.newInstance()
                }
                if _uiS.button(key: "GameEditor.zero.pos.button", gap: 5, caption: "ZPos", selected: false) {
                    selection.position = Vec3()
                }
                if _uiS.button(key: "GameEditor.pos.to.target.button", gap: 5, caption: "Pos2Targ", selected: false) {
                    selection.position = _scene.camera.target
                }
                if _uiS.button(key: "GameEditor.target.to.pos.button", gap: 5, caption: "Targ2Pos", selected: false) {
                    let offset = _scene.camera.eye - _scene.camera.target
                    
                    _scene.camera.target = selection.position
                    _scene.camera.eye = _scene.camera.target + offset
                }
                if _uiS.button(key: "GameEditor.unit.scale.button", gap: 5, caption: "UScale", selected: false) {
                    selection.scale = Vec3(1, 1, 1)
                }
                if _uiS.button(key: "GameEditor.zero.rot.button", gap: 5, caption: "ZRot", selected: false) {
                    selection.rotation = Mat4.identity
                }
                if _uiS.button(key: "GameEditor.rot.45.button", gap: 5, caption: "Rot45", selected: false) {
                    selection.rotation = selection.rotation * Mat4.rotation(45, Vec3(0, 1, 0))
                }
                if _uiS.button(key: "GameEditor.clear.selection.button", gap: 5, caption: "CLR", selected: false) {
                    _selection = nil
                    _editorType = EditorType.none
                    _selNode = -1
                }
                if _selection != nil {
                    if _uiS.button(key: "GameEditor.delete.selection.button", gap: 5, caption: "-", selected: false) {
                        _scene.root.children.removeAll { n in n == selection }
                        _nodes.removeAll()
                        _nodes.append(contentsOf: _scene.root.children)
                        _selection = nil
                        _editorType = EditorType.none
                        _selNode = -1
                    }
                }
            }
            _uiS.end()
            
            UI.layout(gap: 5, center: _game, north: _uiN.panel, south: _uiS.panel, east: _uiE.panel, west: _uiW.panel)
            
            if let _ = _editScene {
                if _game.isButtonDown(0) {
                    if _mode == EditorMode.zoom {
                        _scene.camera.zoom(amount: _game.dY)
                    } else if _mode == EditorMode.rot {
                        _scene.camera.rotate(dX: _game.dX, dY: _game.dY)
                    } else if _mode == EditorMode.panXZ {
                        _scene.camera.move(dX: _game.dX, dY: _game.dY)
                    } else if _mode == EditorMode.panY {
                        _scene.camera.move(dY: _game.dY)
                    } else if let selection = _selection {
                        if _mode == EditorMode.movXZ {
                            selection.position = _scene.camera.move(point: selection.position, dX: -_game.dX, dY: -_game.dY, transform: Mat4.identity)
                        } else if _mode == EditorMode.movY {
                            selection.position = _scene.camera.move(point: selection.position, dY: -_game.dY, transform: Mat4.identity)
                        } else if _mode == EditorMode.rotY {
                            selection.rotation = selection.rotation * Mat4.rotation(-_game.dX, Vec3(0, 1, 0))
                        } else if _mode == EditorMode.scale {
                            if _game.dY < 0 {
                                selection.scale = selection.scale * 0.99
                            } else if _game.dY > 0 {
                                selection.scale = selection.scale * 1.01
                            }
                        }
                    }
                    _down = true
                } else {
                    if let selection = _selection, (_down && _mode == EditorMode.movXZ || _mode == EditorMode.movY) && _snap > 0 {
                        var position = selection.position
                        let s = Float(_snap)
                        
                        position.x = roundf(position.x / s) * s
                        position.y = roundf(position.y / s) * s
                        position.z = roundf(position.z / s) * s
                        
                        selection.position = position
                    }
                    _down = false
                }
            }
        }
        _game.tick()
    }
    
    private func listScenes() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: _game.assets.baseURL.path)
            
            _scenes.removeAll()
            for item in contents {
                if NSString(string: item).pathExtension == "json" {
                    _scenes.append(NSString(string: NSString(string: item).lastPathComponent).deletingPathExtension)
                }
            }
            _scenes.sort(by: { a, b in (a as! String) < (b as! String) })
            
        } catch {
            Log.put(0, error)
        }
    }
}
