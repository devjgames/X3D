//
//  VMath.h
//  X3D
//
//  Created by Douglas McNamara on 5/15/23.
//

#define PI 3.14159265359f

typedef simd_float2 Vec2;
typedef simd_float3 Vec3;
typedef simd_float4 Vec4;
typedef simd_float4x4 Mat4;

Vec2 Vec2Make(float x, float y);
Vec2 Vec2Normalize(Vec2 v);
Vec2 Vec2Transform(Mat4 m, Vec2 v);
Vec2 Vec2TransformNormal(Mat4 m, Vec2 v);
float Vec2Length(Vec2 v);
float Vec2LengthSquared(Vec2 v);
float Vec2Dot(Vec2 v1, Vec2 v2);

Vec3 Vec3Make(float x, float y, float z);
Vec3 Vec3Normalize(Vec3 v);
Vec3 Vec3Cross(Vec3 v1, Vec3 v2);
Vec3 Vec3Transform(Mat4 m, Vec3 v);
Vec3 Vec3TransformNormal(Mat4 m, Vec3 v);
float Vec3Length(Vec3 v);
float Vec3LengthSquared(Vec3 v);
float Vec3Dot(Vec3 v1, Vec3 v2);

Vec4 Vec4Make(float x, float y, float z, float w);
Vec4 Vec4Normalize(Vec4 v);
Vec4 Vec4Transform(Mat4 m, Vec4 v);
float Vec4Length(Vec4 v);
float Vec4LengthSquared(Vec4 v);
float Vec4Dot(Vec4 v1, Vec4 v2);

Mat4 Mat4Make(float m00, float m01, float m02, float m03,
              float m10, float m11, float m12, float m13,
              float m20, float m21, float m22, float m23,
              float m30, float m31, float m32, float m33);
Mat4 Mat4Identity(void);
Mat4 Mat4Invert(Mat4 m);
Mat4 Mat4Transpose(Mat4 m);
Mat4 Mat4Mul(Mat4 m1, Mat4 m2);
Mat4 Mat4Translate(Vec3 p);
Mat4 Mat4Rotate(float degrees, Vec3 axis);
Mat4 Mat4Scale(Vec3 s);
Mat4 Mat4Ortho(float l, float r, float b, float t, float zn, float zf);
Mat4 Mat4Perspective(float fovDegrees, float aspectRatio, float zn, float zf);
Mat4 Mat4LookAt(Vec3 eye, Vec3 target, Vec3 up);

