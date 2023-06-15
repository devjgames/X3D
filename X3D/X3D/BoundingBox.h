//
//  BoundingBox.h
//  X3D
//
//  Created by Douglas McNamara on 5/16/23.
//


typedef struct BoundingBox {
    Vec3 min;
    Vec3 max;
} BoundingBox;

BoundingBox BoundingBoxMake(Vec3 min, Vec3 max);
BoundingBox BoundingBoxEmpty(void);
BoundingBox BoundingBoxBuffer(BoundingBox b, Vec3 buffer);
BoundingBox BoundingBoxAddPoint(BoundingBox b, Vec3 p);
BoundingBox BoundingBoxCombine(BoundingBox b1, BoundingBox b2);
BoundingBox BoundingBoxTransform(Mat4 m, BoundingBox b);
Vec3 BoundingBoxCalcCenter(BoundingBox b);
Vec3 BoundingBoxCalcSize(BoundingBox b);
BOOL BoundingBoxIsEmpty(BoundingBox b);
BOOL BoundingBoxContainsPoint(BoundingBox b, Vec3 p);
BOOL BoundingBoxTouch(BoundingBox b1, BoundingBox b2);
BOOL BoundingBoxIntersectsRay(BoundingBox b, Vec3 origin, Vec3 direction, float *time);
