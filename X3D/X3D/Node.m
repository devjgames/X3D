//
//  Node.m
//  X3D
//
//  Created by Douglas McNamara on 8/9/23.
//

#import <X3D/X3D.h>

@interface Node ()

@property (readonly) NSMutableArray<Node*>* children;
@property (readonly, weak) Node* _parent;

- (void)setReadonlyParent:(Node*)parent;

@end

@implementation Node

- (id)init {
    self = [super init];
    if(self) {
        _children = [NSMutableArray arrayWithCapacity:8];
        __parent = nil;
        
        self.name = NSStringFromClass(self.class);
        
        _visible = YES;
        
        _absolutePosition = Vec3Make(0, 0, 0);
        _position = Vec3Make(0, 0, 0);
        _scale = Vec3Make(1, 1, 1);
        _rotation = Mat4Identity();
        _model = Mat4Identity();
        _zOrder = 0;
    }
    return self;
}

- (void)setReadonlyParent:(Node *)parent {
    __parent = parent;
}

- (int)triangleCount {
    return 0;
}

- (Triangle)triangleAt:(int)i {
    static Triangle triangle;
    
    return triangle;
}

- (id)root {
    Node* r = self;
    
    while(r.parent != nil) {
        r = r.parent;
    }
    return r;
}

- (id)parent {
    return __parent;
}

- (id)lastChild {
    return self.children.lastObject;
}

- (id)childAt:(int)i {
    return self.children[i];
}

- (int)childCount {
    return (int)self.children.count;
}

- (void)detach {
    if(self.parent) {
        Node* parent = self.parent;
        
        [parent.children removeObject:self];
        __parent = nil;
    }
}

- (void)detachChildren {
    while(self.childCount) {
        [self.children[0] detach];
    }
}

- (void)addChild:(Node*)child {
    [child detach];
    [child setReadonlyParent:self];
    [self.children addObject:child];
}

- (void)updateWithScene:(Scene*)scene view:(MTLView*)view {
    [self onUpdateWithScene:scene view:view];
    
    for(int i = 0; i != self.childCount; i++) {
        [[self childAt:i] updateWithScene:scene view:view];
    }
}

- (void)onUpdateWithScene:(Scene*)scene view:(MTLView*)view {
}

- (Mat4)localModel {
    Mat4 m = Mat4Translate(self.position);
    
    m = Mat4Mul(m, self.rotation);
    m = Mat4Mul(m, Mat4Scale(self.scale));
    
    return m;
}

- (void)calcTransform {
    _model = self.localModel;
    if(self.parent) {
        Node* parent = self.parent;
        
        _model = Mat4Mul(parent.model, _model);
    }
    _absolutePosition = Vec3Transform(self.model, Vec3Make(0, 0, 0));
    
    for(int i = 0; i != self.childCount; i++) {
        [[self childAt:i] calcTransform];
    }
}

- (BOOL)isEncodable {
    return NO;
}

- (void)encodeWithEncoder:(id<MTLRenderCommandEncoder>)encoder camera:(id)camera lights:(NSArray *)lights {
}

- (NSString*)description {
    return self.name;
}

@end
