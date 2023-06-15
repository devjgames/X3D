//
//  BoundingBox.m
//  X3D
//
//  Created by Douglas McNamara on 5/16/23.
//

#import <X3D/X3D.h>

BoundingBox BoundingBoxMake(Vec3 min, Vec3 max) {
    return (BoundingBox){ min, max };
}

BoundingBox BoundingBoxEmpty(void) {
    return (BoundingBox){ Vec3Make(1, 1, 1) * FLT_MAX, Vec3Make(1, 1, 1) * -FLT_MAX };
}

BoundingBox BoundingBoxBuffer(BoundingBox b, Vec3 buffer) {
    if(BoundingBoxIsEmpty(b)) {
        b.min -= buffer;
        b.max += buffer;
    }
    return b;
}

BoundingBox BoundingBoxAddPoint(BoundingBox b, Vec3 p) {
    b.min.x = MIN(b.min.x, p.x);
    b.min.y = MIN(b.min.y, p.y);
    b.min.z = MIN(b.min.z, p.z);
    b.max.x = MAX(b.max.x, p.x);
    b.max.y = MAX(b.max.y, p.y);
    b.max.z = MAX(b.max.z, p.z);
    return b;
}

BoundingBox BoundingBoxCombine(BoundingBox b1, BoundingBox b2) {
    if(!BoundingBoxIsEmpty(b1) && !BoundingBoxIsEmpty(b2)) {
        b1 = BoundingBoxAddPoint(b1, b2.min);
        b1 = BoundingBoxAddPoint(b1, b2.max);
    } else if(BoundingBoxIsEmpty(b1)) {
        b1 = b2;
    }
    return b1;
}

BoundingBox BoundingBoxTransform(Mat4 m, BoundingBox b) {
    if(!BoundingBoxIsEmpty(b)) {
        static BoundingBox t;
        static Vec4 c1, c2, c3, c4;
        static Vec4 r1, r2, r3, r4;
        
        c1 = m.columns[0];
        c2 = m.columns[1];
        c3 = m.columns[2];
        c4 = m.columns[3];
        r1 = Vec4Make(c1.x, c2.x, c3.x, c4.x);
        r2 = Vec4Make(c1.y, c2.y, c3.y, c4.y);
        r3 = Vec4Make(c1.z, c2.z, c3.z, c4.z);
        r4 = Vec4Make(c1.w, c2.w, c3.w, c4.w);
        
        t.min = t.max = Vec3Make(c4.x, c4.y, c4.z);
        
        t.min.x += (r1.x < 0) ? r1.x * b.max.x : r1.x * b.min.x;
        t.min.x += (r1.y < 0) ? r1.y * b.max.y : r1.y * b.min.y;
        t.min.x += (r1.z < 0) ? r1.z * b.max.z : r1.z * b.min.z;
        t.max.x += (r1.x > 0) ? r1.x * b.max.x : r1.x * b.min.x;
        t.max.x += (r1.y > 0) ? r1.y * b.max.y : r1.y * b.min.y;
        t.max.x += (r1.z > 0) ? r1.z * b.max.z : r1.z * b.min.z;
        
        t.min.y += (r2.x < 0) ? r2.x * b.max.x : r2.x * b.min.x;
        t.min.y += (r2.y < 0) ? r2.y * b.max.y : r2.y * b.min.y;
        t.min.y += (r2.z < 0) ? r2.z * b.max.z : r2.z * b.min.z;
        t.max.y += (r2.x > 0) ? r2.x * b.max.x : r2.x * b.min.x;
        t.max.y += (r2.y > 0) ? r2.y * b.max.y : r2.y * b.min.y;
        t.max.y += (r2.z > 0) ? r2.z * b.max.z : r2.z * b.min.z;
        
        t.min.z += (r3.x < 0) ? r3.x * b.max.x : r3.x * b.min.x;
        t.min.z += (r3.y < 0) ? r3.y * b.max.y : r3.y * b.min.y;
        t.min.z += (r3.z < 0) ? r3.z * b.max.z : r3.z * b.min.z;
        t.max.z += (r3.x > 0) ? r3.x * b.max.x : r3.x * b.min.x;
        t.max.z += (r3.y > 0) ? r3.y * b.max.y : r3.y * b.min.y;
        t.max.z += (r3.z > 0) ? r3.z * b.max.z : r3.z * b.min.z;
        
        b = t;
    }
    return b;
}

Vec3 BoundingBoxCalcCenter(BoundingBox b) {
    return (b.max + b.min) * 0.5f;
}

Vec3 BoundingBoxCalcSize(BoundingBox b) {
    return b.max - b.min;
}

BOOL BoundingBoxIsEmpty(BoundingBox b) {
    return b.min.x > b.max.x || b.min.y > b.max.y || b.min.z > b.max.z;
}

BOOL BoundingBoxContainsPoint(BoundingBox b, Vec3 p) {
    if(!BoundingBoxIsEmpty(b)) {
        return
        p.x >= b.min.x && p.x <= b.max.x &&
        p.y >= b.min.y && p.y <= b.max.y &&
        p.z >= b.min.z && p.z <= b.max.z;
    }
    return NO;
}

BOOL BoundingBoxTouch(BoundingBox b1, BoundingBox b2) {
    if(!BoundingBoxIsEmpty(b1) && !BoundingBoxIsEmpty(b2)) {
        return !(b1.min.x > b2.max.x ||
                 b1.max.x < b2.min.x ||
                 b1.min.y > b2.max.y ||
                 b1.max.y < b2.min.y ||
                 b1.min.z > b2.max.z ||
                 b1.max.z < b2.min.z
                 );
    }
    return NO;
}

BOOL BoundingBoxIntersectsRay(BoundingBox b, Vec3 origin, Vec3 direction, float *time) {
    if(BoundingBoxIsEmpty(b)) {
        return NO;
    }
    
    static float tnear, tfar, tolerance = 0.00000001, t1, t2, temp;
    static Vec3 min, max, orig, dir;
    
    tnear = -FLT_MAX;
    tfar = FLT_MAX;
    
    min = b.min;
    max = b.max;
    orig = origin;
    dir = direction;
    
    if(fabsf(dir.x) < tolerance) {
        if(orig.x <= min.x || orig.x >= max.x) {
            return NO;
        }
    } else {
        t1 = (min.x - orig.x) / dir.x;
        t2 = (max.x - orig.x) / dir.x;
        if(t1 > t2) {
            temp = t1;
            t1 = t2;
            t2 = temp;
        }
        if(t1 > tnear) {
            tnear = t1;
        }
        if(t2 < tfar) {
            tfar = t2;
        }
        if(tnear > tfar || tfar < 0) {
            return NO;
        }
    }
    
    if(fabsf(dir.y) < tolerance) {
        if(orig.y <= min.y || orig.y >= max.y) {
            return NO;
        }
    } else {
        t1 = (min.y - orig.y) / dir.y;
        t2 = (max.y - orig.y) / dir.y;
        if(t1 > t2) {
            temp = t1;
            t1 = t2;
            t2 = temp;
        }
        if(t1 > tnear) {
            tnear = t1;
        }
        if(t2 < tfar) {
            tfar = t2;
        }
        if(tnear > tfar || tfar < 0) {
            return NO;
        }
    }
    
    if(fabsf(dir.z) < tolerance) {
        if(orig.z <= min.z || orig.z >= max.z) {
            return NO;
        }
    } else {
        t1 = (min.z - orig.z) / dir.z;
        t2 = (max.z - orig.z) / dir.z;
        if(t1 > t2) {
            temp = t1;
            t1 = t2;
            t2 = temp;
        }
        if(t1 > tnear) {
            tnear = t1;
        }
        if(t2 < tfar) {
            tfar = t2;
        }
        if(tnear > tfar || tfar < 0) {
            return NO;
        }
    }

    if(tnear < 0) {
        if(tfar >= 0 && tfar < *time) {
            *time = tfar;
        }
    } else if(tnear < *time) {
        *time = tnear;
    }
    return YES;
}
