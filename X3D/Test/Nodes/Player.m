//
//  Player.m
//  X3DTest
//
//  Created by Douglas McNamara on 6/29/23.
//

#import "Player.h"
#import "ScenePlayer.h"

#define RADIUS 24
#define GROUND_SLOPE 60

@interface Player ()

@property NSMutableData* triangles;
@property Vec3 velocity;
@property Mat4 groundMatrix;
@property BOOL onGround;

- (void)appendTriangles:(Node*)node;

@end

@implementation Player

- (id)init {
    self = [super init];
    if(self) {
    }
    return self;
}

- (void)onSetup:(Scene *)scene view:(MTLView *)view {
    
    if(scene.inDesign) {
        MeshLoader* loader = [[MeshLoader alloc] init];
        
        loader.center = NO;
        
        Node* ui = [loader load:[view.assets.baseURL URLByAppendingPathComponent:@"assets/ui/ui.obj"] assets:view.assets];
        Node* node = [[ui childAt:0] childAt:0];
        
        node.basicEncodable.textureSampler = LINEAR_CLAMP_TO_EDGE;
        
        [self addChild:ui];
        
        return;
    }
    
    Vec4 f = self.rotation.columns[2];
    
    scene.camera.eye = self.position;
    scene.camera.target = self.position + Vec3Make(f.x, f.y, f.z);
    
    self.triangles = nil;
    
    _velocity = Vec3Make(0, 0, 0);
    _groundMatrix = Mat4Identity();
    _onGround = NO;
    
    ScenePlayer* player = [ScenePlayer instance];
    
    if(player) {
        player.info =  @"Press left & right mouse buttons to move forwards & backwards";
    }
    
    view.fpsMouseEnabled = YES;
}

- (void)onUpdateWithScene:(Scene *)scene view:(MTLView *)view {
    if(scene.inDesign) {
        return;
    }
    
    if(self.triangles == nil) {
        self.triangles = [NSMutableData dataWithCapacity:300 * sizeof(Triangle)];
        
        [self appendTriangles:scene.root];
        
        Log(@"%i collidable triangle(s)", self.triangles.length / sizeof(Triangle));
    }
    
    [scene.camera rotateAroundEye:view];
    
    Vec3 forward = scene.camera.target - scene.camera.eye;
    Vec3 f = forward;
    
    forward = forward * Vec3Make(1, 0, 1);

    _velocity = _velocity * Vec3Make(0, 1, 0);
    if(([view isButtonDown:0] || [view isButtonDown:1]) && Vec3Length(forward) > 0.0000001) {
        _velocity = _velocity + Vec3Normalize(forward) * (([view isButtonDown:0]) ? 100 : -100);
    }
    
    _velocity.y -= 20000 * view.elapsedTime;
    
    Vec3 delta = Vec3TransformNormal(_groundMatrix, _velocity * view.elapsedTime);
    
    _groundMatrix = Mat4Identity();
    _onGround = NO;
    
    if(Vec3Length(delta) > 0.0000001) {
        int count = (int)(self.triangles.length / sizeof(Triangle));
        Vec3 groundNormal = Vec3Make(0, 0, 0);
        
        if(Vec3Length(delta) > RADIUS * 0.5f) {
            delta = Vec3Normalize(delta) * RADIUS * 0.5f;
        }
        
        scene.camera.eye = scene.camera.eye + delta;
        
        for(int i = 0; i != 3; i++) {
            float time = RADIUS;
            Vec3 rPos = scene.camera.eye, rNormal = Vec3Make(0, 0, 0);
            BOOL resolved = NO;
            
            for(int j = 0; j != count; j++) {
                Triangle triangle = ((Triangle*)self.triangles.mutableBytes)[j];
                
                if(TriangleResolve(triangle, Mat4Identity(), scene.camera.eye, RADIUS, &rPos, &rNormal, &time)) {
                    resolved = YES;
                }
            }
            if(resolved) {
                if(acosf(MAX(-0.999f, MIN(0.999f, Vec3Dot(rNormal, Vec3Make(0, 1, 0))))) * 180 / PI < GROUND_SLOPE) {
                    _velocity.y = 0;
                    _onGround = YES;
                    
                    groundNormal = groundNormal + rNormal;
                }
                scene.camera.eye = rPos;
            } else {
                break;
            }
        }
        
        if(_onGround) {
            Vec3 u = Vec3Normalize(groundNormal);
            Vec3 r = Vec3Make(1, 0, 0);
            Vec3 f = Vec3Normalize(Vec3Cross(r, u));
            
            r = Vec3Normalize(Vec3Cross(u, f));
            
            _groundMatrix = Mat4Make(r.x, u.x, f.x, 0,
                                     r.y, u.y, f.y, 0,
                                     r.z, u.z, f.z, 0,
                                     0, 0, 0, 1
                                     );
        }
    }
    
    scene.camera.target = scene.camera.eye + f;
}

- (NSString*)serialize:(Scene *)scene view:(MTLView *)view {
    Vec4 f = self.rotation.columns[2];
    
    return [NSString stringWithFormat:@"%@ %@ %@ %@ %@",
            [NSNumber numberWithFloat:self.position.x],
            [NSNumber numberWithFloat:self.position.y],
            [NSNumber numberWithFloat:self.position.z],
            [NSNumber numberWithFloat:f.x],
            [NSNumber numberWithFloat:f.z]
    ];
}

- (void)deserialize:(Scene *)scene view:(MTLView *)view tokens:(NSArray<NSString *> *)tokens {
    self.position = Vec3Make([tokens[2] floatValue],
                             [tokens[3] floatValue],
                             [tokens[4] floatValue]
                             );
    Vec3 f = Vec3Normalize(Vec3Make([tokens[5] floatValue], 0, [tokens[6] floatValue]));
    Vec3 u = Vec3Make(0, 1, 0);
    Vec3 r = Vec3Normalize(Vec3Cross(u, f));
    
    self.rotation = Mat4Make(r.x, u.x, f.x, 0,
                             r.y, u.y, f.y, 0,
                             r.z, u.z, f.z, 0,
                             0, 0, 0, 1
                             );
}

- (void)appendTriangles:(Node *)node {
    if(node.collidable) {
        for(int i = 0; i != node.triangleCount; i++) {
            Triangle triangle = [node triangleAt:i];
            
            [self.triangles appendBytes:&triangle length:sizeof(Triangle)];
        }
    }
    for(int i = 0; i != node.childCount; i++) {
        [self appendTriangles:[node childAt:i]];
    }
}

@end
