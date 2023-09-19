//
//  Log.swift
//  X3D
//
//  Created by Douglas McNamara on 9/14/23.
//

import Foundation

public class Log {
    
    public static var level:Int=2
    
    private static var instance:Log=Log()
    
    public static func put(_ level:Int, _ item:Any) {
        if level <= Log.level {
            instance.put(item)
        }
    }
    
    public init() {
    }
    
    public func activate() {
        Log.instance = self
    }
    
    open func put(_ item:Any) {
        print("\(item)")
    }
}
