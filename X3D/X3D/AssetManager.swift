//
//  AssetManager.swift
//  X3D
//
//  Created by Douglas McNamara on 9/14/23.
//

import Foundation
import MetalKit
import UniformTypeIdentifiers

public class AssetLoader {
    
    public init() {
    }
    
    open func load(_ url:URL, path:String, assets:AssetManager) throws -> Any? {
        return nil
    }
}

public class TextureLoader : AssetLoader {
    
    private var loader:MTKTextureLoader?
    
    public override init() {
    }
    
    public override func load(_ url: URL, path:String, assets:AssetManager) throws -> Any? {
        if loader == nil {
            loader = MTKTextureLoader(device: assets.game.device!)
        }
        let texture = try loader!.newTexture(URL: url, options: [ .SRGB:false, .allocateMipmaps:false, .generateMipmaps:false, .origin:MTKTextureLoader.Origin.topLeft ])
        
        texture.label = path
        
        return texture
    }
}

public class AssetManager {
    
    public var baseURL=Bundle.main.resourceURL!
    
    private var loaders=[String:AssetLoader]()
    private var assets=[String:Any]()
    private weak var _game:Game?
    
    public init(_ game:Game) {
        _game = game
        
        register("png", assetLoader: TextureLoader())
        register("md2", assetLoader: KeyFrameMeshLoader())
        register("obj", assetLoader: NodeLoader())
        register("wav", assetLoader: SoundLoader())
        register("m4a", assetLoader: SoundLoader())
        register("mp3", assetLoader: SoundLoader())
    }
    
    public var game:Game {
        _game!
    }
    
    public func register(_ ext:String, assetLoader:AssetLoader) {
        loaders[ext] = assetLoader
    }
    
    public func load(_ path:String) throws -> Any? {
        if assets[path] == nil {
            Log.put(1, "Loading asset '\(path)' ...")
            
            let ext = NSString(string: path).pathExtension
            
            assets[path] = try loaders[ext]!.load(baseURL.appendingPathComponent(path), path:path, assets:self)
        }
        return assets[path]
    }
    
    public func unload(_ path:String) {
        if assets[path] != nil {
            assets.removeValue(forKey: path)
        }
    }
    
    public func clear() {
        assets.removeAll()
    }
    
    public func save(_ data:Data, width:Int, height:Int, path:String) {
        let url = baseURL.appendingPathComponent(path)
        let context = CIContext()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let image = CIImage(bitmapData: data, bytesPerRow: 4 * width, size: NSSize(width: width, height: height), format: .RGBA8, colorSpace: colorSpace)
        let imageRef = context.createCGImage(image, from: NSRect(origin: NSPoint(x: 0, y: 0), size: NSSize(width: width, height: height)))
        let imageDest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        
        CGImageDestinationAddImage(imageDest!, imageRef!, nil)
        CGImageDestinationFinalize(imageDest!)
    }
}
