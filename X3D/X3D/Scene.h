//
//  Scene.h
//  X3D
//
//  Created by Douglas McNamara on 5/17/23.
//

@class Scene;

@interface Node : XObject

@property NSString* name;
@property BOOL visible;
@property id encodable;
@property (readonly) Vec3 absolutePosition;
@property Vec3 position;
@property Vec3 scale;
@property Mat4 rotation;
@property (readonly) Mat4 model;
@property int zOrder;
@property id userData;

- (BasicEncodable*)basicEncodable;
- (id)root;
- (id)parent;
- (id)lastChild;
- (id)childAt:(int)i;
- (int)childCount;
- (void)detach;
- (void)detachChildren;
- (void)addChild:(Node*)child;
- (void)updateWithScene:(Scene*)scene view:(MTLView*)view;
- (void)onUpdateWithScene:(Scene*)scene view:(MTLView*)view;
- (void)calcTransform;

@end

@interface Camera : XObject

@property Vec3 eye;
@property Vec3 target;
@property Vec3 up;
@property float fieldOfViewDegrees;
@property float zNear;
@property float zFar;
@property (readonly) Mat4 projection;
@property (readonly) Mat4 view;

- (void)calcTransforms:(float)aspectRatio;
- (void)rotate:(MTLView*)view;
- (void)rotateDelta:(NSPoint)delta;

@end

@interface Scene : XObject

@property (readonly) Camera* camera;
@property (readonly) Node* root;

- (void)encodeWithEncoder:(id<MTLRenderCommandEncoder>)encoder lights:(NSMutableData*)lights;

@end

