//
//  Camera.m
//  X3D
//
//  Created by Douglas McNamara on 8/9/23.
//

#import <X3D/X3D.h>

@interface Camera ()

- (void)activateCamera:(Camera*)camera node:(Node*)node;
- (void)activate:(BOOL)activate;

@end

@implementation Camera

- (id)init {
    self = [super init];
    if(self) {
        _projection = Mat4Identity();
        _active = false;
    }
    return self;
}

- (Mat4)localModel {
    return Mat4Mul(self.rotation, Mat4Translate(-self.position));
}

- (void)calcProjection:(float)aspectRatio {
    _projection = Mat4Perspective(60, aspectRatio, 1, 10000);
}

- (void)activate {
    [self activateCamera:self node:self.root];
}

- (void)activateCamera:(Camera *)camera node:(Node *)node {
    if([node isKindOfClass:Camera.class]) {
        Camera* c = (Camera*)node;
        
        [c activate:c == camera];
    }
    for(int i = 0; i != node.childCount; i++) {
        [self activateCamera:camera node:[node childAt:i]];
    }
}

- (void)activate:(BOOL)activate {
    _active = activate;
    if(self.active) {
        Log(@"Activated %@!", self);
    }
}

@end

