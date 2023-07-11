//
//  PlayerNode.m
//  X3DTest
//
//  Created by Douglas McNamara on 6/29/23.
//

#import "PlayerNode.h"
#import "Player.h"

#define RADIUS 16
#define GROUND_SLOPE 60

@interface PlayerNode ()

@property NSMutableData* triangles;
@property Vec3 velocity;
@property Mat4 groundMatrix;
@property BOOL onGround;
@property float targetLength;
@property float targetHeight;
@property Vec3 offset;

- (void)appendTriangles:(Node*)node;
- (BOOL)intersectsOrigin:(Vec3)origin direction:(Vec3)direction buffer:(float)buffer time:(float*)time;

@end

@implementation PlayerNode

- (id)init {
    self = [super init];
    if(self) {
        self.offset = Vec3Make(100, 100, 100);
        self.targetLength = 100;
        self.targetHeight = 25;
    }
    return self;
}

- (void)onSetup:(Scene *)scene view:(MTLView *)view {
    KeyFrameMesh* mesh = [view.assets load:@"assets/md2/babyboom.md2"];

    mesh = [[KeyFrameMesh alloc] initWithKeyFrameMesh:mesh];
    mesh.basicEncodable.texture = [view.assets load:@"assets/md2/babyboom.png"];
    
    [mesh setSequenceStart:0 end:39 speed:10 looping:YES];
    
    mesh.rotation = Mat4Rotate(-90, Vec3Make(1, 0, 0));
    mesh.position = Vec3Make(0, -[mesh frameBoundsAt:0].min.z - RADIUS, 0);
    
    [self addChild:mesh];
    
    scene.camera.target = self.position;
    scene.camera.eye = self.position + Vec3Normalize(self.offset * Vec3Make(1, 0, 1)) * self.targetLength + Vec3Make(0, self.targetHeight, 0);
    
    if(scene.inDesign) {
        return;
    }
    
    self.triangles = nil;
    
    _velocity = Vec3Make(0, 0, 0);
    _groundMatrix = Mat4Identity();
    _onGround = NO;
    
    Player* player = [Player instance];
    
    if(player) {
        player.info =  @"Press left & right arrow keys to turn, up & down arrow keys to move";
    }
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
    
    KeyFrameMesh* mesh = [self childAt:0];
    
    Vec3 forward = (scene.camera.target - scene.camera.eye) * Vec3Make(1, 0, 1);
    int d = 0;
    BOOL moving = NO;

    if([view isKeyDown:123]) {
        [scene.camera rotateDelta:NSMakePoint(+180 * view.elapsedTime, 0)];
    } else if([view isKeyDown:124]) {
        [scene.camera rotateDelta:NSMakePoint(-180 * view.elapsedTime, 0)];
    }
    if([view isKeyDown:125]) {
        d = -1;
    } else if([view isKeyDown:126]) {
        d = 1;
    }
    _velocity = _velocity * Vec3Make(0, 1, 0);
    if(d != 0 && Vec3Length(forward) > 0.0000001) {
        forward = Vec3Normalize(forward) * 100 * d;
        _velocity = _velocity + forward;
        forward = Vec3Normalize(forward);
        
        float angle = acosf(MAX(-0.999f, MIN(0.999f, forward.x)));
        
        if(forward.z > 0) {
            angle = 2 * PI - angle;
        }
        self.rotation = Mat4Rotate(angle * 180 / PI, Vec3Make(0, 1, 0));
        moving = YES;
    }
    if(_onGround) {
        BOOL set = mesh.looping;
        
        if(!set) {
            set = mesh.done;
        }
        if(set) {
            if(moving) {
                [mesh setSequenceStart:40 end:45 speed:8 looping:YES];
            } else {
                [mesh setSequenceStart:0 end:39 speed:10 looping:YES];
            }
        }
    } else {
        [mesh setSequenceStart:66 end:69 speed:7 looping:NO];
    }
    
    _velocity.y -= 2000 * view.elapsedTime;
    
    Vec3 delta = Vec3TransformNormal(_groundMatrix, _velocity * view.elapsedTime);
    
    _groundMatrix = Mat4Identity();
    _onGround = NO;
    
    if(Vec3Length(delta) > 0.0000001) {
        int count = (int)(self.triangles.length / sizeof(Triangle));
        Vec3 groundNormal = Vec3Make(0, 0, 0);
        
        if(Vec3Length(delta) > RADIUS * 0.5f) {
            delta = Vec3Normalize(delta) * RADIUS * 0.5f;
        }
        
        self.position = self.position + delta;
        
        for(int i = 0; i != 3; i++) {
            float time = RADIUS;
            Vec3 rPos = self.position, rNormal = Vec3Make(0, 0, 0);
            BOOL resolved = NO;
            
            for(int j = 0; j != count; j++) {
                Triangle triangle = ((Triangle*)self.triangles.mutableBytes)[j];
                
                if(TriangleResolve(triangle, Mat4Identity(), self.position, RADIUS, &rPos, &rNormal, &time)) {
                    resolved = YES;
                }
            }
            if(resolved) {
                if(acosf(MAX(-0.999f, MIN(0.999f, Vec3Dot(rNormal, Vec3Make(0, 1, 0))))) * 180 / PI < GROUND_SLOPE) {
                    _velocity.y = 0;
                    _onGround = YES;
                    
                    groundNormal = groundNormal + rNormal;
                }
                self.position = rPos;
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
    
    Vec3 offset = scene.camera.eye - scene.camera.target;
    Vec3 direction = Vec3Normalize(offset * Vec3Make(1, 0, 1));
    Vec3 origin = self.position;
    float time = self.targetLength + (RADIUS - 1);
    float length = self.targetLength;
    
    if([self intersectsOrigin:origin direction:direction buffer:1 time:&time]) {
        length = MIN(length, time) - (RADIUS - 1);
    }
    offset = direction * length;
    offset.y = self.targetHeight + (self.targetLength - length);
    direction = Vec3Normalize(offset);
    time = self.targetLength + (RADIUS - 1);
    length =  self.targetLength;
    if([self intersectsOrigin:origin direction:direction buffer:1 time:&time]) {
        length = MIN(length, time) - (RADIUS - 1);
    }
    offset = Vec3Normalize(offset) * length;
    
    scene.camera.target = self.position;
    scene.camera.eye = self.position + offset;
    scene.camera.up = Vec3Make(0, 1, 0);
}

- (void)handleUI:(Scene *)scene view:(MTLView *)view reset:(BOOL)reset {
    UIManager* ui = view.ui;
    Vec3 offset = self.offset;
    float l = self.targetLength;
    float h = self.targetHeight;
    
    [ui field:@"PlayerNode.offset.field" gap:0 caption:@"Offset" vec3Value:&offset width:100 reset:reset];
    [ui addRow:5];
    [ui field:@"PlayerNode.target.length.field" gap:0 caption:@"Target Length" floatValue:&l width:75 reset:reset];
    [ui addRow:5];
    [ui field:@"PlayerNode.target.height.field" gap:0 caption:@"Target Height" floatValue:&h width:75 reset:reset];
    
    self.offset = offset;
    self.targetLength = l;
    self.targetHeight = h;
}

- (NSString*)serialize:(Scene *)scene view:(MTLView *)view {
    return [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@ %@",
            [NSNumber numberWithFloat:self.position.x],
            [NSNumber numberWithFloat:self.position.y],
            [NSNumber numberWithFloat:self.position.z],
            [NSNumber numberWithFloat:self.offset.x],
            [NSNumber numberWithFloat:self.offset.y],
            [NSNumber numberWithFloat:self.offset.z],
            [NSNumber numberWithFloat:self.targetLength],
            [NSNumber numberWithFloat:self.targetHeight]
    ];
}

- (void)deserialize:(Scene *)scene view:(MTLView *)view tokens:(NSArray<NSString *> *)tokens {
    self.position = Vec3Make([tokens[2] floatValue],
                             [tokens[3] floatValue],
                             [tokens[4] floatValue]
                             );
    self.offset = Vec3Make([tokens[5] floatValue],
                           [tokens[6] floatValue],
                           [tokens[7] floatValue]
                           );
    self.targetLength = [tokens[8] floatValue];
    self.targetHeight = [tokens[9] floatValue];
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

- (BOOL)intersectsOrigin:(Vec3)origin direction:(Vec3)direction buffer:(float)buffer time:(float *)time {
    int count = (int)(self.triangles.length / sizeof(Triangle));
    BOOL hit = NO;
    
    for(int i = 0; i != count; i++) {
        Triangle triangle = ((Triangle*)self.triangles.mutableBytes)[i];
        
        if(TriangleRayIntersects(triangle, origin, direction, buffer, time)) {
            hit = YES;
        }
    }
    return hit;
}

@end
