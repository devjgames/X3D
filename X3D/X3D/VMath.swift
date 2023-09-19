//
//  VMath.swift
//  X3D
//
//  Created by Douglas McNamara on 9/14/23.
//

import Foundation
import simd

public struct Vec2 : Codable, CustomStringConvertible {
    
    public var x:Float=0
    public var y:Float=0
    
    public init() {
    }
    
    public init(_ x:Float, _ y:Float) {
        self.x = x
        self.y = y
    }
    
    public init(_ v:simd_float2) {
        x = v.x
        y = v.y
    }
    
    public var description:String {
        "\(x) \(y)"
    }
    
    public var simd:simd_float2 {
        simd_float2(x, y)
    }
    
    public var length:Float {
        sqrtf(Vec2.dot(self, self))
    }
    
    public var lengthSquared:Float {
        Vec2.dot(self, self)
    }
    
    public mutating func normalize() {
        self = Vec2.normalize(self)
    }
    
    public static func normalize(_ v:Vec2) -> Vec2 {
        Vec2(simd_normalize(v.simd))
    }
    
    public static func dot(_ lhs:Vec2, _ rhs:Vec2) -> Float {
        simd_dot(lhs.simd, rhs.simd)
    }
    
    public static func + (lhs:Vec2, rhs:Vec2) -> Vec2 {
        Vec2(lhs.simd + rhs.simd)
    }
    
    public static func - (lhs:Vec2, rhs:Vec2) -> Vec2 {
        Vec2(lhs.simd - rhs.simd)
    }
    
    public static prefix func - (rhs:Vec2) -> Vec2 {
        Vec2(-rhs.simd)
    }
    
    public static func * (lhs:Vec2, rhs:Vec2) -> Vec2 {
        Vec2(lhs.simd * rhs.simd)
    }
    
    public static func * (lhs:Vec2, rhs:Float) -> Vec2 {
        Vec2(lhs.simd * rhs)
    }
    
    public static func * (lhs:Float, rhs:Vec2) -> Vec2 {
        Vec2(lhs * rhs.simd)
    }
    
    public static func / (lhs:Vec2, rhs:Vec2) -> Vec2 {
        Vec2(lhs.simd / rhs.simd)
    }
    
    public static func / (lhs:Vec2, rhs:Float) -> Vec2 {
        Vec2(lhs.simd / rhs)
    }
    
    public static func transform(_ m:Mat4, _ v:Vec2) -> Vec2 {
        Vec2(m.m00 * v.x + m.m01 * v.y + m.m03,
             m.m10 * v.x + m.m11 * v.y + m.m13
        )
    }
    
    public static func transformNormal(_ m:Mat4, _ v:Vec2) -> Vec2 {
        Vec2(m.m00 * v.x + m.m01 * v.y,
             m.m10 * v.x + m.m11 * v.y
        )
    }
}

public struct Vec3 : Codable, CustomStringConvertible {
    
    public var x:Float=0
    public var y:Float=0
    public var z:Float=0
    
    public init() {
    }
    
    public init(_ x:Float, _ y:Float, _ z:Float) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public init(_ v:simd_float3) {
        x = v.x
        y = v.y
        z = v.z
    }
    
    public var description:String {
        "\(x) \(y) \(z)"
    }
    
    public var simd:simd_float3 {
        simd_float3(x, y, z)
    }
    
    public var length:Float {
        sqrtf(Vec3.dot(self, self))
    }
    
    public var lengthSquared:Float {
        Vec3.dot(self, self)
    }
    
    public mutating func normalize() {
        self = Vec3.normalize(self)
    }
    
    public static func normalize(_ v:Vec3) -> Vec3 {
        Vec3(simd_normalize(v.simd))
    }
    
    public static func cross(_ lhs:Vec3, _ rhs:Vec3) -> Vec3 {
        Vec3(simd_cross(lhs.simd, rhs.simd))
    }
    
    public static func dot(_ lhs:Vec3, _ rhs:Vec3) -> Float {
        simd_dot(lhs.simd, rhs.simd)
    }
    
    public static func + (lhs:Vec3, rhs:Vec3) -> Vec3 {
        Vec3(lhs.simd + rhs.simd)
    }
    
    public static func - (lhs:Vec3, rhs:Vec3) -> Vec3 {
        Vec3(lhs.simd - rhs.simd)
    }
    
    public static prefix func - (rhs:Vec3) -> Vec3 {
        Vec3(-rhs.simd)
    }
    
    public static func * (lhs:Vec3, rhs:Vec3) -> Vec3 {
        Vec3(lhs.simd * rhs.simd)
    }
    
    public static func * (lhs:Vec3, rhs:Float) -> Vec3 {
        Vec3(lhs.simd * rhs)
    }
    
    public static func * (lhs:Float, rhs:Vec3) -> Vec3 {
        Vec3(lhs * rhs.simd)
    }
    
    public static func / (lhs:Vec3, rhs:Vec3) -> Vec3 {
        Vec3(lhs.simd / rhs.simd)
    }
    
    public static func / (lhs:Vec3, rhs:Float) -> Vec3 {
        Vec3(lhs.simd / rhs)
    }
    
    public static func transform(_ m:Mat4, _ v:Vec3) -> Vec3 {
        Vec3(m.m00 * v.x + m.m01 * v.y + m.m02 * v.z + m.m03,
             m.m10 * v.x + m.m11 * v.y + m.m12 * v.z + m.m13,
             m.m20 * v.x + m.m21 * v.y + m.m22 * v.z + m.m23
        )
    }
    
    public static func transformNormal(_ m:Mat4, _ v:Vec3) -> Vec3 {
        Vec3(m.m00 * v.x + m.m01 * v.y + m.m02 * v.z,
             m.m10 * v.x + m.m11 * v.y + m.m12 * v.z,
             m.m20 * v.x + m.m21 * v.y + m.m22 * v.z
        )
    }
}

public struct Vec4 : Codable, CustomStringConvertible {
    
    public var x:Float=0
    public var y:Float=0
    public var z:Float=0
    public var w:Float=0
    
    public init() {
    }
    
    public init(_ x:Float, _ y:Float, _ z:Float, _ w:Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    public init(_ v:simd_float4) {
        x = v.x
        y = v.y
        z = v.z
        w = v.w
    }
    
    public var description:String {
        "\(x) \(y) \(z) \(w)"
    }
    
    public var simd:simd_float4 {
        simd_float4(x, y, z, w)
    }
    
    public var length:Float {
        sqrtf(Vec4.dot(self, self))
    }
    
    public var lengthSquared:Float {
        Vec4.dot(self, self)
    }
    
    public mutating func normalize() {
        self = Vec4.normalize(self)
    }
    
    public static func normalize(_ v:Vec4) -> Vec4 {
        Vec4(simd_normalize(v.simd))
    }
    
    public static func dot(_ lhs:Vec4, _ rhs:Vec4) -> Float {
        simd_dot(lhs.simd, rhs.simd)
    }
    
    public static func + (lhs:Vec4, rhs:Vec4) -> Vec4 {
        Vec4(lhs.simd + rhs.simd)
    }
    
    public static func - (lhs:Vec4, rhs:Vec4) -> Vec4 {
        Vec4(lhs.simd - rhs.simd)
    }
    
    public static prefix func - (rhs:Vec4) -> Vec4 {
        Vec4(-rhs.simd)
    }
    
    public static func * (lhs:Vec4, rhs:Vec4) -> Vec4 {
        Vec4(lhs.simd * rhs.simd)
    }
    
    public static func * (lhs:Vec4, rhs:Float) -> Vec4 {
        Vec4(lhs.simd * rhs)
    }
    
    public static func * (lhs:Float, rhs:Vec4) -> Vec4 {
        Vec4(lhs * rhs.simd)
    }
    
    public static func / (lhs:Vec4, rhs:Vec4) -> Vec4 {
        Vec4(lhs.simd / rhs.simd)
    }
    
    public static func / (lhs:Vec4, rhs:Float) -> Vec4 {
        Vec4(lhs.simd / rhs)
    }
    
    public static func transform(_ m:Mat4, _ v:Vec4) -> Vec4 {
        Vec4(m.m00 * v.x + m.m01 * v.y + m.m02 * v.z + m.m03 * v.w,
             m.m10 * v.x + m.m11 * v.y + m.m12 * v.z + m.m13 * v.w,
             m.m20 * v.x + m.m21 * v.y + m.m22 * v.z + m.m23 * v.w,
             m.m30 * v.x + m.m31 * v.y + m.m32 * v.z + m.m33 * v.w
        )
    }
}

public struct Mat4 : Codable, CustomStringConvertible {
    
    public var m00:Float=1
    public var m01:Float=0
    public var m02:Float=0
    public var m03:Float=0
    
    public var m10:Float=0
    public var m11:Float=1
    public var m12:Float=0
    public var m13:Float=0
    
    public var m20:Float=0
    public var m21:Float=0
    public var m22:Float=1
    public var m23:Float=0
    
    public var m30:Float=0
    public var m31:Float=0
    public var m32:Float=0
    public var m33:Float=1
    
    public init() {
    }
    
    public init(_ m00:Float, _ m01:Float, _ m02:Float, _ m03:Float,
                _ m10:Float, _ m11:Float, _ m12:Float, _ m13:Float,
                _ m20:Float, _ m21:Float, _ m22:Float, _ m23:Float,
                _ m30:Float, _ m31:Float, _ m32:Float, _ m33:Float) {
        self.m00 = m00
        self.m01 = m01
        self.m02 = m02
        self.m03 = m03
        
        self.m10 = m10
        self.m11 = m11
        self.m12 = m12
        self.m13 = m13
        
        self.m20 = m20
        self.m21 = m21
        self.m22 = m22
        self.m23 = m23
        
        self.m30 = m30
        self.m31 = m31
        self.m32 = m32
        self.m33 = m33
    }
    
    public init(_ m:simd_float4x4) {
        let c0 = m.columns.0
        let c1 = m.columns.1
        let c2 = m.columns.2
        let c3 = m.columns.3
        
        m00 = c0.x
        m10 = c0.y
        m20 = c0.z
        m30 = c0.w
        
        m01 = c1.x
        m11 = c1.y
        m21 = c1.z
        m31 = c1.w
        
        m02 = c2.x
        m12 = c2.y
        m22 = c2.z
        m32 = c2.w
        
        m03 = c3.x
        m13 = c3.y
        m23 = c3.z
        m33 = c3.w
    }
    
    public var simd:simd_float4x4 {
        simd_float4x4(simd_float4(m00, m10, m20, m30),
                      simd_float4(m01, m11, m21, m31),
                      simd_float4(m02, m12, m22, m32),
                      simd_float4(m03, m13, m23, m33));
    }
    
    public var description: String {
        "\(m00) \(m01) \(m02) \(m03)\n\(m10) \(m11) \(m12) \(m13)\n\(m20) \(m21) \(m22) \(m23)\n\(m30) \(m31) \(m32) \(m33)"
    }
    
    public mutating func transpose() {
        self = Mat4.transpose(self)
    }
    
    public mutating func invert() {
        self = Mat4.invert(self)
    }
    
    public static var identity:Mat4 {
        Mat4(1, 0, 0, 0,
             0, 1, 0, 0,
             0, 0, 1, 0,
             0, 0, 0, 1
        )
    }
    
    public static func translation(_ t:Vec3) -> Mat4 {
        Mat4(1, 0, 0, t.x,
             0, 1, 0, t.y,
             0, 0, 1, t.z,
             0, 0, 0, 1
        )
    }
    
    public static func rotation(_ degrees:Float, _ axis:Vec3) -> Mat4 {
        let r = degrees * Float.pi / 180;
        let a = simd_normalize(axis.simd);
        let x = a.x;
        let y = a.y;
        let z = a.z;
        let c = cosf(r);
        let s = sinf(r);
        
        return Mat4(x * x * (1 - c) + c, x * y * (1 - c) - z * s, x * z * (1 - c) + y * s, 0,
                    y * x * (1 - c) + z * s, y * y * (1 - c) + c, y * z * (1 - c) - x * s, 0,
                    x * z * (1 - c) - y * s, y * z * (1 - c) + x * s, z * z * (1 - c) + c, 0,
                    0, 0, 0, 1
        )
    }
    
    public static func scaling(_ s:Vec3) -> Mat4 {
        Mat4(s.x, 0, 0, 0,
             0, s.y, 0, 0,
             0, 0, s.z, 0,
             0, 0, 0, 1
        )
    }
    
    public static func ortho(_ l:Float, _ r:Float, _ b:Float, _ t:Float, _ zn:Float, _ zf:Float) -> Mat4 {
        let sx = +2 / (r - l);
        let sy = +2 / (t - b);
        let sz = -2 / (zf - zn);
        let tx = -(r + l) / (r - l);
        let ty = -(t + b) / (t - b);
        let tz = -(zf + zn) / (zf - zn);
        
        return Mat4(sx, 0, 0, tx,
                    0, sy, 0, ty,
                    0, 0, sz, tz,
                    0, 0, 0, 1
        )
    }
    
    public static func perspective(_ fovDegrees:Float, _ aspectRatio:Float, _ zn:Float, _ zf:Float) -> Mat4 {
        let f = 1 / tanf(fovDegrees * Float.pi / 360)
        
        return Mat4(f / aspectRatio, 0, 0, 0,
                    0, f, 0, 0,
                    0, 0, (zf + zn) / (zn - zf), 2 * zf * zn / (zn - zf),
                    0, 0, -1, 0
        )
    }
    
    public static func lookAt(_ eye:Vec3, _ target:Vec3, _ up:Vec3) -> Mat4 {
        var f = simd_normalize(target.simd - eye.simd)
        var u = simd_normalize(up.simd)
        let r = simd_normalize(simd_cross(f, u))
        let e = -eye.simd
        
        u = simd_normalize(simd_cross(r, f))
        f = -f
        
        return Mat4(r.x, r.y, r.z, simd_dot(r, e),
                    u.x, u.y, u.z, simd_dot(u, e),
                    f.x, f.y, f.z, simd_dot(f, e),
                    0, 0, 0, 1
        )
    }
    
    public static func transpose(_ m:Mat4) -> Mat4 {
        Mat4(simd_transpose(m.simd))
    }
    
    public static func invert(_ m:Mat4) -> Mat4 {
        Mat4(simd_inverse(m.simd))
    }
    
    public static func * (lhs:Mat4, rhs:Mat4) -> Mat4 {
        Mat4(lhs.simd * rhs.simd)
    }
}
