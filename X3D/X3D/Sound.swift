//
//  Sound.swift
//  X3D
//
//  Created by Douglas McNamara on 9/19/23.
//

import Foundation
import AVFoundation

public class Sound {
    
    public let player:AVAudioPlayer
    
    public init(data:Data) throws {
        player = try AVAudioPlayer(data: data)
    }
    
    public func newInstance() throws -> Sound {
        try Sound(data: player.data!)
    }
}

public class SoundLoader : AssetLoader {
    
    public override init() {
        super.init()
    }
    
    public override func load(_ url: URL, path: String, assets: AssetManager) throws -> Any? {
        try Sound(data: Data(contentsOf: url))
    }
}
