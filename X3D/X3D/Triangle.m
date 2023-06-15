//
//  Triangle.m
//  X3D
//
//  Created by Douglas McNamara on 5/16/23.
//

#import <X3D/X3D.h>

Triangle TriangleMake(Vec3 p1, Vec3 p2, Vec3 p3) {
    return TriangleCalcPlane((Triangle){ p1, p2, p3, Vec3Make(0, 0, 0), 0, 1 });
}

Triangle TransformTriangle(Mat4 m, Triangle tri) {
    tri.p1 = Vec3Transform(m, tri.p1);
    tri.p2 = Vec3Transform(m, tri.p2);
    tri.p3 = Vec3Transform(m, tri.p3);
    return TriangleCalcPlane(tri);
}

Triangle TriangleCalcPlane(Triangle tri) {
    tri.n = Vec3Normalize(Vec3Cross(tri.p3 - tri.p2, tri.p2 - tri.p1));
    tri.d = -Vec3Dot(tri.n, tri.p1);
    return tri;
}

Triangle TriangleTransform(Mat4 m, Triangle tri) {
    tri.p1 = Vec3Transform(m, tri.p1);
    tri.p2 = Vec3Transform(m, tri.p2);
    tri.p3 = Vec3Transform(m, tri.p3);
    return TriangleCalcPlane(tri);
}

Vec3 TrianglePointAt(Triangle tri, int i) {
    if(i == 1) {
        return tri.p2;
    } else if(i == 2) {
        return tri.p3;
    } else {
        return tri.p1;
    }
}

BOOL TriangleContains(Triangle tri, Vec3 point, float buffer) {
    for(int i = 0; i != 3; i++) {
        Vec3 a = TrianglePointAt(tri, i);
        Vec3 b = TrianglePointAt(tri, i + 1);
        Vec3 n = Vec3Normalize(Vec3Cross(a - b, tri.n));
        float d = -Vec3Dot(n, a + buffer * n);
        float t = Vec3Dot(point, n) + d;
        
        if(t > 0) {
            return NO;
        }
    }
    return YES;
}

BOOL TriangleRayIntersectsPlane(Triangle tri, Vec3 origin, Vec3 direction, float* time) {
    float t = Vec3Dot(direction, tri.n);
    
    if(fabsf(t) > 0.0000001f) {
        t = (-tri.d - Vec3Dot(origin, tri.n)) / t;
        if(t >= 0 && t < *time) {
            *time = t;
            return YES;
        }
    }
    return NO;
}

BOOL TriangleRayIntersects(Triangle tri, Vec3 origin, Vec3 direction, float buffer, float* time) {
    float t = *time;
    
    if(TriangleRayIntersectsPlane(tri, origin, direction, time)) {
        if(TriangleContains(tri, origin + (*time) * direction, buffer)) {
            return YES;
        }
    }
    *time = t;
    return NO;
}

Vec3 TriangleClosestEdgePoint(Triangle tri, Vec3 point) {
    Vec3 cp = tri.p1;
    float min = FLT_MAX;
    
    for(int i = 0; i != 3; i++) {
        Vec3 a = TrianglePointAt(tri, i);
        Vec3 b = TrianglePointAt(tri, i + 1);
        Vec3 ab = b - a;
        Vec3 ap = point - a;
        Vec3 c = a;
        Vec3 d;
        float s = Vec3Dot(ab, ap);
        
        if(s > 0) {
            s /= Vec3LengthSquared(ab);
            if(s < 1) {
                c = a + s * ab;
            } else {
                c = b;
            }
        }
        d = point - c;
        if(Vec3Length(d) < min) {
            min = Vec3Length(d);
            cp = c;
        }
    }
    return cp;
}

BOOL TriangleResolve(Triangle tri, Mat4 transform, Vec3 position, float radius, Vec3* rPos, Vec3 *rNormal, float* time) {
    float t = *time;
    BOOL hit = NO;
    
    tri = TriangleTransform(transform, tri);
    
    if(TriangleRayIntersectsPlane(tri, position, -tri.n, &t)) {
        Vec3 p = position + -tri.n * t;
        
        if(TriangleContains(tri, p, 0)) {
            *rPos = p + tri.n * radius;
            *rNormal = tri.n;
            *time = t;
            hit = YES;
        } else {
            Vec3 c = TriangleClosestEdgePoint(tri, position);
            Vec3 d = position - c;
            
            if(Vec3Length(d) > 0.0000001 && Vec3Length(d) < *time) {
                *rPos = c + Vec3Normalize(d) * radius;
                *rNormal = Vec3Normalize(d);
                *time = Vec3Length(d);
                hit = YES;
            }
        }
    }
    return hit;
}
