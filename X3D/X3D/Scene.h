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
@property BOOL isLight;
@property Vec4 lightColor;
@property float lightRadius;
@property BOOL collidable;
@property BOOL dynamic;
@property int triangleTag;

- (BasicEncodable*)basicEncodable;
- (int)triangleCount;
- (Triangle)triangleAt:(int)i;
- (id)root;
- (id)parent;
- (id)lastChild;
- (id)childAt:(int)i;
- (int)childCount;
- (void)detach;
- (void)detachChildren;
- (void)addChild:(Node*)child;
- (void)setup:(Scene*)scene view:(MTLView*)view;
- (void)onSetup:(Scene*)scene view:(MTLView*)view;
- (void)preUpdateWithScene:(Scene*)scene view:(MTLView*)view;
- (void)onPreUpdateWithScene:(Scene*)scene view:(MTLView*)view;
- (void)updateWithScene:(Scene*)scene view:(MTLView*)view;
- (void)onUpdateWithScene:(Scene*)scene view:(MTLView*)view;
- (void)handleUI:(Scene*)scene view:(MTLView*)view reset:(BOOL)reset;
- (NSString*)serialize:(Scene*)scene view:(MTLView*)view;
- (void)deserialize:(Scene*)scene view:(MTLView*)view tokens:(NSArray<NSString*>*)tokens;
- (void)calcTransform;
- (Node*)transform;

@end

@interface EditorNode : Node

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
- (void)rotateAroundEye:(MTLView*)view;
- (void)rotateAroundEyeDelta:(NSPoint)delta;

@end

@interface Scene : XObject

@property (readonly) Camera* camera;
@property (readonly) Node* root;
@property (readonly) BOOL inDesign;
@property (readonly) NSMutableData* lights;
@property int lightMapWidth;
@property int lightMapHeight;
@property float aoStrength;
@property float aoLength;
@property float sampleRadius;
@property int sampleCount;

- (id)initInDesign:(BOOL)inDesign;
- (void)encodeWithEncoder:(id<MTLRenderCommandEncoder>)encoder;
- (void)bufferLights;
- (void)serialize:(NSURL*)url view:(MTLView*)view;
+ (Scene*)deserialize:(NSURL*)url view:(MTLView*)view inDesign:(BOOL)inDesign;

@end

