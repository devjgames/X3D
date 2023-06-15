//
//  Triangle.h
//  X3D
//
//  Created by Douglas McNamara on 5/16/23.
//

typedef struct Triangle {
    Vec3 p1;
    Vec3 p2;
    Vec3 p3;
    Vec3 n;
    float d;
    int tag;
} Triangle;

Triangle TriangleMake(Vec3 p1, Vec3 p2, Vec3 p3);
Triangle TransformTriangle(Mat4 m, Triangle tri);
Triangle TriangleCalcPlane(Triangle tri);
Triangle TriangleTransform(Mat4 m, Triangle tri);
Vec3 TrianglePointAt(Triangle tri, int i);
BOOL TriangleContains(Triangle tri, Vec3 point, float buffer);
BOOL TriangleRayIntersectsPlane(Triangle tri, Vec3 origin, Vec3 direction, float* time);
BOOL TriangleRayIntersects(Triangle tri, Vec3 origin, Vec3 direction, float buffer, float* time);
Vec3 TriangleClosestEdgePoint(Triangle tri, Vec3 point);
BOOL TriangleResolve(Triangle tri, Mat4 transform, Vec3 position, float radius, Vec3* rPos, Vec3 *rNormal, float* time);
