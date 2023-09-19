//
//  Triangle.swift
//  X3D
//
//  Created by Douglas McNamara on 9/19/23.
//

import Foundation

public struct Triangle {
    
    public var p1=Vec3()
    public var p2=Vec3()
    public var p3=Vec3()
    public var normal=Vec3()
    public var d:Float=0
    public var tag:Int=0
    
    public init() {
    }
    
    public init(_ p1:Vec3, _ p2:Vec3, _ p3:Vec3) {
        self.p1 = p1
        self.p2 = p2
        self.p3 = p3
        calcPlane()
    }
    
    public subscript(i:Int) -> Vec3 {
        if i == 1 {
            return p2
        } else if i == 2 {
            return p3
        } else {
            return p1
        }
    }
    
    public mutating func calcPlane() {
        normal = Vec3.normalize(Vec3.cross(p3 - p2, p2 - p1))
        d = -Vec3.dot(normal, p1)
    }
    
    public mutating func transform(m:Mat4) {
        p1 = Vec3.transform(m, p1)
        p2 = Vec3.transform(m, p2)
        p3 = Vec3.transform(m, p3)
        calcPlane()
    }
    
    public func contains(point:Vec3, buffer:Float) -> Bool {
        for i in 0..<3 {
            let a = self[i]
            let b = self[i + 1]
            let n = Vec3.normalize(Vec3.cross(normal, a - b))
            let d2 = -Vec3.dot(a - buffer * n, n)
            let s = Vec3.dot(n, point) + d2
            
            if s < 0 {
                return false
            }
        }
        return true
    }
    
    public func intersectsPlane(origin:Vec3, direction:Vec3, time:inout Float) -> Bool {
        var t = Vec3.dot(normal, direction)
        
        if fabsf(t) > 0.0000001 {
            t = (-d - Vec3.dot(normal, origin)) / t
            if t >= 0 && t < time {
                time = t
                return true
            }
        }
        return false
    }
    
    public func intersects(origin:Vec3, direction:Vec3, buffer:Float, time:inout Float) -> Bool {
        var t = time
        
        if intersectsPlane(origin: origin, direction: direction, time: &t) {
            let ip = origin + t * direction
            
            if contains(point: ip, buffer: buffer) {
                time = t
                return true
            }
        }
        return false
    }
    
    public func closestEdgePoint(point:Vec3) -> Vec3 {
        var min = Float.greatestFiniteMagnitude
        var cp = p1
        
        for i in 0..<3 {
            let a = self[i]
            let b = self[i + 1]
            let ab = b - a
            let ap = point - a
            var c = a
            var s = Vec3.dot(ab, ap)
            
            if s > 0 {
                s /= ab.lengthSquared
                if s < 1 {
                    c = a + ab * s
                } else {
                    c = b
                }
            }
            
            let d = point - c
            
            if d.length < min {
                min = d.length
                cp = c
            }
        }
        return cp
    }
    
    public func resolve(position:Vec3, radius:Float, resolvedPosition:inout Vec3, resolvedNormal:inout Vec3, time:inout Float) -> Bool {
        var t = time
        var resolved = false
        
        if intersectsPlane(origin: position, direction: -normal, time: &t) {
            let ip = position - normal * t
            
            if contains(point: ip, buffer: 0) {
                time = t
                resolvedNormal = normal
                resolvedPosition = ip + resolvedNormal * radius
                resolved = true
            } else {
                let cp = closestEdgePoint(point: position)
                let d = position - cp
                
                if d.length > 0.0000001 && d.length < time {
                    time = d.length
                    resolvedNormal = Vec3.normalize(d)
                    resolvedPosition = cp + resolvedNormal * radius
                    resolved = true
                }
            }
        }
        return resolved
    }
}
