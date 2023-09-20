//
//  BoundingBox.swift
//  X3D
//
//  Created by Douglas McNamara on 9/20/23.
//

import Foundation


public struct BoundingBox {
    
    public var lo=Vec3()
    public var hi=Vec3()
    
    public init() {
        clear()
    }
    
    public init(_ lo:Vec3, _ hi:Vec3) {
        self.lo = lo
        self.hi = hi
    }
    
    public var center:Vec3 {
        (hi + lo) / 2
    }
    
    public var size:Vec3 {
        (hi - lo) / 2
    }
    
    public var isEmpty:Bool {
        return lo.x > hi.x || lo.y > hi.y || lo.z > hi.z
    }
    
    public mutating func clear() {
        lo = Vec3(1, 1, 1) * Float.greatestFiniteMagnitude
        hi = Vec3(1, 1, 1) * -Float.greatestFiniteMagnitude
    }
    
    public mutating func buffer(amount:Vec3) {
        if !isEmpty {
            lo = lo - amount
            hi = hi + amount
        }
    }
    
    public func contains(point:Vec3) -> Bool {
        if !isEmpty {
            return (
                point.x >= lo.x && point.x <= hi.x &&
                point.y >= lo.y && point.y <= hi.y &&
                point.z >= lo.z && point.z <= hi.z
                )
        }
        return false
    }
    
    public func touches(b:BoundingBox) -> Bool {
        if !isEmpty && !b.isEmpty {
            return !(
                b.lo.x > hi.x ||
                b.hi.x < lo.x ||
                b.lo.y > hi.y ||
                b.hi.y < lo.y ||
                b.lo.z > hi.z ||
                b.hi.z < lo.z
            )
        }
        return false
    }
    
    public static func transform(m:Mat4, b:BoundingBox) -> BoundingBox {
        var tb = b
        
        if !b.isEmpty {
            let t = Vec3(m.m03, m.m13, m.m23)
            
            tb.lo = t
            tb.hi = t
            
            tb.lo.x += (m.m00 < 0) ? m.m00 * b.hi.x : m.m00 * b.lo.x
            tb.lo.x += (m.m01 < 0) ? m.m01 * b.hi.y : m.m01 * b.lo.y
            tb.lo.x += (m.m02 < 0) ? m.m02 * b.hi.z : m.m02 * b.lo.z
            tb.hi.x += (m.m00 > 0) ? m.m00 * b.hi.x : m.m00 * b.lo.x
            tb.hi.x += (m.m01 > 0) ? m.m01 * b.hi.y : m.m01 * b.lo.y
            tb.hi.x += (m.m02 > 0) ? m.m02 * b.hi.z : m.m02 * b.lo.z
            
            tb.lo.y += (m.m10 < 0) ? m.m10 * b.hi.x : m.m10 * b.lo.x
            tb.lo.y += (m.m11 < 0) ? m.m11 * b.hi.y : m.m11 * b.lo.y
            tb.lo.y += (m.m12 < 0) ? m.m12 * b.hi.z : m.m12 * b.lo.z
            tb.hi.y += (m.m10 > 0) ? m.m10 * b.hi.x : m.m10 * b.lo.x
            tb.hi.y += (m.m11 > 0) ? m.m11 * b.hi.y : m.m11 * b.lo.y
            tb.hi.y += (m.m12 > 0) ? m.m12 * b.hi.z : m.m12 * b.lo.z
            
            tb.lo.z += (m.m20 < 0) ? m.m20 * b.hi.x : m.m20 * b.lo.x
            tb.lo.z += (m.m21 < 0) ? m.m21 * b.hi.y : m.m21 * b.lo.y
            tb.lo.z += (m.m22 < 0) ? m.m22 * b.hi.z : m.m22 * b.lo.z
            tb.hi.z += (m.m20 > 0) ? m.m20 * b.hi.x : m.m20 * b.lo.x
            tb.hi.z += (m.m21 > 0) ? m.m21 * b.hi.y : m.m21 * b.lo.y
            tb.hi.z += (m.m22 > 0) ? m.m22 * b.hi.z : m.m22 * b.lo.z
        }
        return tb
    }
    
    public static func + (lhs:BoundingBox, rhs:Vec3) -> BoundingBox {
        var b = BoundingBox()
        
        b.lo.x = min(lhs.lo.x, rhs.x)
        b.lo.y = min(lhs.lo.y, rhs.y)
        b.lo.z = min(lhs.lo.z, rhs.z)
        b.hi.x = max(lhs.hi.x, rhs.x)
        b.hi.y = max(lhs.hi.y, rhs.y)
        b.hi.z = max(lhs.hi.z, rhs.z)
        
        return b
    }
    
    public static func + (lhs:Vec3, rhs:BoundingBox) -> BoundingBox {
        return rhs + lhs
    }
    
    public static func +(lhs:BoundingBox, rhs:BoundingBox) -> BoundingBox {
        var b = lhs
        
        if !lhs.isEmpty && !rhs.isEmpty {
            b = b + rhs.lo
            b = b + rhs.hi
        } else if lhs.isEmpty {
            b = rhs
        }
        return b
    }
}
