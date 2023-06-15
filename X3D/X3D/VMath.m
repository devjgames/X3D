//
//  VMath.m
//  X3D
//
//  Created by Douglas McNamara on 5/15/23.
//

#import <X3D/X3D.h>


Vec2 Vec2Make(float x, float y) {
    return (simd_float2){ x, y };
}

Vec2 Vec2Normalize(Vec2 v) {
    return simd_normalize(v);
}

Vec2 Vec2Transform(Mat4 m, Vec2 v) {
    static Vec4 t;
    
    t = simd_mul(m, (simd_float4){ v.x, v.y, 0, 1 });
    
    return (simd_float2){ t.x, t.y };
}

Vec2 Vec2TransformNormal(Mat4 m, Vec2 v) {
    static Vec4 t;
    
    t = simd_mul(m, (simd_float4){ v.x, v.y, 0, 0 });
    
    return (simd_float2){ t.x, t.y };
}

float Vec2Length(Vec2 v) {
    return simd_length(v);
}

float Vec2LengthSquared(Vec2 v) {
    return simd_length_squared(v);
}

float Vec2Dot(Vec2 v1, Vec2 v2) {
    return simd_dot(v1, v2);
}

Vec3 Vec3Make(float x, float y, float z) {
    return (simd_float3){ x, y, z };
}

Vec3 Vec3Normalize(Vec3 v) {
    return simd_normalize(v);
}

Vec3 Vec3Cross(Vec3 v1, Vec3 v2) {
    return simd_cross(v1, v2);
}

Vec3 Vec3Transform(Mat4 m, Vec3 v) {
    static Vec4 t;
    
    t = simd_mul(m, (simd_float4){ v.x, v.y, v.z, 1 });
    
    return (simd_float3){ t.x, t.y, t.z };
}

Vec3 Vec3TransformNormal(Mat4 m, Vec3 v) {
    static Vec4 t;
    
    t = simd_mul(m, (simd_float4){ v.x, v.y, v.z, 0 });
    
    return (simd_float3){ t.x, t.y, t.z };
}

float Vec3Length(Vec3 v) {
    return simd_length(v);
}

float Vec3LengthSquared(Vec3 v) {
    return simd_length_squared(v);
}

float Vec3Dot(Vec3 v1, Vec3 v2) {
    return simd_dot(v1, v2);
}

Vec4 Vec4Make(float x, float y, float z, float w) {
    return (simd_float4){ x, y, z, w };
}

Vec4 Vec4Normalize(Vec4 v) {
    return simd_normalize(v);
}

Vec4 Vec4Transform(Mat4 m, Vec4 v) {
    return simd_mul(m, v);
}

float Vec4Length(Vec4 v) {
    return simd_length(v);
}

float Vec4LengthSquared(Vec4 v) {
    return simd_length_squared(v);
}

float Vec4Dot(Vec4 v1, Vec4 v2) {
    return simd_dot(v1, v2);
}

Mat4 Mat4Make(float m00, float m01, float m02, float m03,
              float m10, float m11, float m12, float m13,
              float m20, float m21, float m22, float m23,
              float m30, float m31, float m32, float m33) {
    return (simd_float4x4){
        (simd_float4){ m00, m10, m20, m30 },
        (simd_float4){ m01, m11, m21, m31 },
        (simd_float4){ m02, m12, m22, m32 },
        (simd_float4){ m03, m13, m23, m33 }
    };
}

Mat4 Mat4Identity(void) {
    return matrix_identity_float4x4;
}

Mat4 Mat4Invert(Mat4 m) {
    return simd_inverse(m);
}

Mat4 Mat4Transpose(Mat4 m) {
    return simd_transpose(m);
}

Mat4 Mat4Mul(Mat4 m1, Mat4 m2) {
    return simd_mul(m1, m2);
}

Mat4 Mat4Translate(Vec3 p) {
    return Mat4Make(1, 0, 0, p.x,
                    0, 1, 0, p.y,
                    0, 0, 1, p.z,
                    0, 0, 0, 1
                    );
}

Mat4 Mat4Rotate(float degrees, Vec3 axis) {
    static float c, s, r, x, y, z;
    static Vec3 a;
    
    r = degrees * PI / 180;
    a = simd_normalize(axis);
    x = a.x;
    y = a.y;
    z = a.z;
    c = cosf(r);
    s = sinf(r);
    return Mat4Make(x * x * (1 - c) + c, x * y * (1 - c) - z * s, x * z * (1 - c) + y * s, 0,
                    y * x * (1 - c) + z * s, y * y * (1 - c) + c, y * z * (1 - c) - x * s, 0,
                    x * z * (1 - c) - y * s, y * z * (1 - c) + x * s, z * z * (1 - c) + c, 0,
                    0, 0, 0, 1
                    );
}

Mat4 Mat4Scale(Vec3 s) {
    return Mat4Make(s.x, 0, 0, 0,
                    0, s.y, 0, 0,
                    0, 0, s.z, 0,
                    0, 0, 0, 1
                    );
}

Mat4 Mat4Ortho(float l, float r, float b, float t, float zn, float zf) {
    static float sx, sy, sz, tx, ty, tz;

    sx = +2 / (r - l);
    sy = +2 / (t - b);
    sz = -2 / (zf - zn);
    tx = -(r + l) / (r - l);
    ty = -(t + b) / (t - b);
    tz = -(zf + zn) / (zf - zn);
    
    return Mat4Make(sx, 0, 0, tx,
                    0, sy, 0, ty,
                    0, 0, sz, tz,
                    0, 0, 0, 1
                    );
}

Mat4 Mat4Perspective(float fovDegrees, float aspectRatio, float zn, float zf) {
    static float f;
    
    f = 1 / tanf(fovDegrees * PI / 360);
    
    return Mat4Make(f / aspectRatio, 0, 0, 0,
                    0, f, 0, 0,
                    0, 0, (zf + zn) / (zn - zf), 2 * zf * zn / (zn - zf),
                    0, 0, -1, 0
                    );
}

Mat4 Mat4LookAt(Vec3 eye, Vec3 target, Vec3 up) {
    static Vec3 f, u, r;
    
    f = simd_normalize(target - eye);
    u = simd_normalize(up);
    r = simd_normalize(simd_cross(f, u));
    u = simd_normalize(simd_cross(r, f));
    f = -f;
    return Mat4Make(r.x, r.y, r.z, -simd_dot(eye, r),
                    u.x, u.y, u.z, -simd_dot(eye, u),
                    f.x, f.y, f.z, -simd_dot(eye, f),
                    0, 0, 0, 1
                    );
}
