//
//  KeyFrameMesh.h
//  X3D
//
//  Created by Douglas McNamara on 5/17/23.
//

typedef struct KeyFrameVertex {
    Vec3 position;
    Vec2 textureCoordinate;
    Vec3 normal;
} KeyFrameVertex;

@interface KeyFrame : XObject

@property (readonly) BoundingBox bounds;

- (int)vertexCount;
- (KeyFrameVertex)vertexAt:(int)i;
- (void)pushVertex:(KeyFrameVertex)vertex;

@end

@interface KeyFrameMesh : Node

@property (readonly) BoundingBox bounds;
@property (readonly) int start;
@property (readonly) int end;
@property (readonly) int speed;
@property (readonly) BOOL looping;
@property (readonly) BOOL done;

- (id)initWithView:(MTLView*)view frames:(NSArray<KeyFrame*>*)frames;
- (id)initWithKeyFrameMesh:(KeyFrameMesh*)mesh;
- (int)frameCount;
- (BoundingBox)frameBoundsAt:(int)i;
- (void)setSequenceStart:(int)start end:(int)end speed:(int)speed looping:(BOOL)looping;
- (void)reset;
- (void)bufferVertices;
+ (NSArray<NSArray<id>*>*)sequences;

@end

@interface KeyFrameMeshLoader : AssetLoader

+ (int)normalCount;
+ (Vec3)normalAt:(int)i;

@end

