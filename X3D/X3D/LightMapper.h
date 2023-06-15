//
//  LightMapper.h
//  X3D
//
//  Created by Douglas McNamara on 6/11/23.
//

typedef struct LMVertex {
    Vec2 coord;
    Vec3 position;
    Vec3 normal;
    Vec4 ambientColor;
    Vec4 diffuseColor;
} LMVertex;

@interface LightMapper : XObject

@property float sampleRadius;
@property float aoLength;
@property float aoStrength;

- (id)initWithView:(MTLView*)view width:(int)width height:(int)height;
- (void)clear;
- (void)pushVertex:(LMVertex)vertex;
- (void)pushSample:(Vec3)sample;
- (void)pushQuad:(int)i mesh:(Mesh*)mesh x:(int)x y:(int)y width:(int*)width height:(int*)height ambient:(Vec4)ambient diffuse:(Vec4)diffuse scale:(int)scale;
- (void)buffer;
- (void)render:(id<MTLAccelerationStructure>)accel lights:(NSData*)lights;
- (id<MTLAccelerationStructure>)createAccel:(NSMutableData*)vertices indices:(NSMutableData*)indices;
- (id<MTLTexture>)texture;

@end

