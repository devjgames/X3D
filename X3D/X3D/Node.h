//
//  Node.h
//  X3D
//
//  Created by Douglas McNamara on 8/9/23.
//

@class Scene;
@class Camera;
@class Light;

@interface Node : XObject

@property NSString* name;
@property BOOL visible;
@property (readonly) Vec3 absolutePosition;
@property Vec3 position;
@property Vec3 scale;
@property Mat4 rotation;
@property (readonly) Mat4 model;
@property int zOrder;

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
- (void)updateWithScene:(Scene*)scene view:(MTLView*)view;
- (void)onUpdateWithScene:(Scene*)scene view:(MTLView*)view;
- (Mat4)localModel;
- (void)calcTransform;
- (BOOL)isEncodable;
- (void)encodeWithEncoder:(id<MTLRenderCommandEncoder>)encoder camera:(Camera*)camera lights:(NSArray<Light*>*)lights;

@end
