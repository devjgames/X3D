//
//  Scene.m
//  X3D
//
//  Created by Douglas McNamara on 5/17/23.
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
        
        _identifier = 0;
        _visible = YES;
        
        self.encodable = nil;
        
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

- (BasicEncodable*)basicEncodable {
    if(self.encodable) {
        if([self.encodable isKindOfClass:[BasicEncodable class]]) {
            return self.encodable;
        }
    }
    return nil;
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

- (void)calcTransform {
    _model = Mat4Translate(self.position);
    _model = Mat4Mul(self.model, self.rotation);
    _model = Mat4Mul(self.model, Mat4Scale(self.scale));
    if(self.parent) {
        Node* parent = self.parent;
        
        _model = Mat4Mul(parent.model, _model);
    }
    _absolutePosition = Vec3Transform(self.model, Vec3Make(0, 0, 0));
    
    for(int i = 0; i != self.childCount; i++) {
        [[self childAt:i] calcTransform];
    }
}

@end

@implementation Camera

- (id)init {
    self = [super init];
    if(self) {
        self.eye = Vec3Make(100, 100, 100);
        self.target = Vec3Make(0, 0, 0);
        self.up = Vec3Make(0, 1, 0);
        self.fieldOfViewDegrees = 60;
        self.zNear = 0.1f;
        self.zFar = 10000;
        
        _projection = _view = Mat4Identity();
    }
    return self;
}

- (void)calcTransforms:(float)aspectRatio {
    _projection = Mat4Perspective(self.fieldOfViewDegrees, aspectRatio, self.zNear, self.zFar);
    _view = Mat4LookAt(self.eye, self.target, self.up);
}

- (void)rotate:(MTLView*)view {
    [self rotateDelta:NSMakePoint(-view.deltaX, -view.deltaY)];
}

- (void)rotateDelta:(NSPoint)delta {
    Mat4 m = Mat4Rotate(delta.x, Vec3Make(0, 1, 0));
    Vec3 x = _eye - _target;
    Vec3 r = Vec3Normalize(Vec3TransformNormal(m, Vec3Cross(x, _up)));
    
    x = Vec3TransformNormal(m, x);
    m = Mat4Rotate(delta.y, r);
    _up = Vec3Normalize(Vec3TransformNormal(m, Vec3Cross(r, x)));
    _eye = _target + Vec3TransformNormal(m, x);
}

@end

@interface Scene ()

@property (readonly) NSMutableArray<Node*>* nodes;

- (void)addNodes:(Node*)node;

@end

@implementation Scene

- (id)init {
    self = [super init];
    if(self) {
        _nodes = [NSMutableArray arrayWithCapacity:32];
        _camera = [[Camera alloc] init];
        _root = [[Node alloc] init];
    }
    return self;
}

- (void)encodeWithEncoder:(id<MTLRenderCommandEncoder>)encoder lights:(NSMutableData *)lights {
    
    [self addNodes:self.root];
    
    __weak Scene* me = self;
    
    [self.nodes sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        Node* n1 = obj1;
        Node* n2 = obj2;
        
        if(n1 == n2) {
            return 0;
        } else if(n1.zOrder == n2.zOrder) {
            float d1 = Vec3Length(n1.absolutePosition - me.camera.eye);
            float d2 = Vec3Length(n2.absolutePosition - me.camera.eye);
            
            if(d1 < d2) {
                return 1;
            } else {
                return -1;
            }
        } else if(n1.zOrder < n2.zOrder) {
            return -1;
        } else {
            return 1;
        }
    }];
    
    for(Node* node in self.nodes) {
        id<Encodable> encodable = node.encodable;
        
        [encodable encodeWithEncoder:encoder projection:self.camera.projection view:self.camera.view model:node.model lights:lights];
    }
    [self.nodes removeAllObjects];
}

- (void)addNodes:(Node *)node {
    if(node.visible) {
        if(node.encodable) {
            [self.nodes addObject:node];
        }
        for(int i = 0; i != node.childCount; i++) {
            [self addNodes:[node childAt:i]];
        }
    }
}

@end
