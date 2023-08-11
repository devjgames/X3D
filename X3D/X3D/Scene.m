//
//  Scene.m
//  X3D
//
//  Created by Douglas McNamara on 5/17/23.
//

#import <X3D/X3D.h>


@interface Scene ()

@property (weak) Camera* camera;
@property NSMutableArray<Node*>* encodables;
@property NSMutableArray<Light*>* lights;

- (void)list:(Node*)node;

@end

@implementation Scene

- (id)init {
    self = [super init];
    if(self) {
        _root = [[Node alloc] init];
        
        self.camera = nil;
        
        self.encodables = [NSMutableArray arrayWithCapacity:128];
        self.lights = [NSMutableArray arrayWithCapacity:16];
    }
    return self;
}

- (void)encodeWithEncoder:(id<MTLRenderCommandEncoder>)encoder size:(NSSize)size {
    
    [self.encodables removeAllObjects];
    [self.lights removeAllObjects];
    
    self.camera = nil;
    
    [self list:self.root];
    
    if(!self.camera) {
        [self.encodables removeAllObjects];
        [self.lights removeAllObjects];
        return;
    }
    
    [self.camera calcProjection:size.width / size.height];
    
    __weak Scene* me = self;
    
    [self.encodables sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        Node* n1 = obj1;
        Node* n2 = obj2;
        
        if(n1 == n2) {
            return NSOrderedSame;
        } else if(n1.zOrder == n2.zOrder) {
            float d1 = Vec3Length(n1.absolutePosition - me.camera.absolutePosition);
            float d2 = Vec3Length(n2.absolutePosition - me.camera.absolutePosition);
            
            if(d2 < d1) {
                return NSOrderedAscending;
            } else {
                return NSOrderedDescending;
            }
        } else if(n1.zOrder < n2.zOrder) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
    
    [self.lights sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        Light* l1 = obj1;
        Light* l2 = obj2;
        
        if(l1 == l2) {
            return NSOrderedSame;
        } else if([l1 isKindOfClass:PointLight.class] && [l2 isKindOfClass:PointLight.class]) {
            float d1 = Vec3Length(l1.absolutePosition - me.camera.absolutePosition);
            float d2 = Vec3Length(l2.absolutePosition - me.camera.absolutePosition);
            
            if(d1 < d2) {
                return NSOrderedAscending;
            } else {
                return NSOrderedDescending;
            }
        } else if([l1 isKindOfClass:PointLight.class]) {
            return NSOrderedDescending;
        } else if([l2 isKindOfClass:PointLight.class]) {
            return NSOrderedAscending;
        } else if(l1.zOrder < l2.zOrder) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
    
    for(Node* node in self.encodables) {
        [node encodeWithEncoder:encoder camera:self.camera lights:self.lights];
    }
    [self.encodables removeAllObjects];
    [self.lights removeAllObjects];
}

- (void)list:(Node *)node {
    if(node.visible) {
        if([node isKindOfClass:Camera.class]) {
            Camera* camera = (Camera*)node;
            
            if(camera.active) {
                self.camera = camera;
            }
        }
        if(node.isEncodable) {
            [self.encodables addObject:node];
        }
        if([node isKindOfClass:Light.class]) {
            [self.lights addObject:(Light*)node];
        }
        for(int i = 0; i != node.childCount; i++) {
            [self list:[node childAt:i]];
        }
    }
}

@end

