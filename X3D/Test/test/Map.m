//
//  Map.m
//  X3DTest
//
//  Created by Douglas McNamara on 8/10/23.
//

#import "Test.h"

@interface FPSCamera : Camera

@property (readonly) NSMutableData* triangles;
@property Vec3 velocity;
@property Vec3 radii;
@property float speed;
@property float gravity;
@property float groundSlope;
@property (readonly) Mat4 groundMatrix;
@property (readonly) BOOL onGround;

@end

@implementation FPSCamera

- (id)init {
    self = [super init];
    if(self) {
        _triangles = [NSMutableData dataWithCapacity:100 * sizeof(Triangle)];
        _velocity = Vec3Make(0, 0, 0);
        _radii = Vec3Make(12, 24, 12);
        _speed = 100;
        _gravity = 10000;
        _groundSlope = 60;
        _groundMatrix = Mat4Identity();
        _onGround = NO;
    }
    return self;
}

- (void)onUpdateWithScene:(Scene *)scene view:(MTLView *)view {
    Mat4 m = Mat4Rotate(-view.deltaX, Vec3Make(0, 1, 0));
    Vec4 c0 = self.rotation.columns[0];
    Vec4 c1 = self.rotation.columns[1];
    Vec4 c2 = self.rotation.columns[2];
    Vec3 f = Vec3Make(c0.z, c1.z, c2.z);
    Vec3 u = Vec3Make(c0.y, c1.y, c2.y);
    Vec3 r = Vec3Normalize(Vec3TransformNormal(m, Vec3Cross(f, u)));
    
    f = Vec3Normalize(Vec3TransformNormal(m, f));
    m = Mat4Rotate(view.deltaY, r);
    u = Vec3Normalize(Vec3TransformNormal(m, Vec3Cross(r, f)));
    f = Vec3Normalize(Vec3TransformNormal(m, f));
    
    self.rotation = Mat4Look(-f, u);
    
    BOOL b1 = [view isButtonDown:0];
    BOOL b2 = [view isButtonDown:1];
    Vec3 d = -f * Vec3Make(1, 0, 1);
    
    _velocity *= Vec3Make(0, 1, 0);
    
    if(_onGround && Vec3Length(d) > 0.0000001 && (b1 || b2)) {
        _velocity += Vec3Normalize(d) * ((b1) ? _speed : -_speed);
    }
    _velocity.y -= _gravity * view.elapsedTime;
    
    Vec3 delta = _velocity * view.elapsedTime;
    Vec3 position = self.position;
    Vec3 groundNormal = Vec3Make(0, 0, 0);
    
    delta = Vec3TransformNormal(_groundMatrix, delta);
    
    _groundMatrix = Mat4Identity();
    _onGround = NO;
    
    if(Vec3Length(delta) > 0.000001) {
        Mat4 toUnit = Mat4Make(1 / _radii.x, 0, 0, 0,
                               0, 1 / _radii.y, 0, 0,
                               0, 0, 1 / _radii.z, 0,
                               0, 0, 0, 1
                               );
        Mat4 inverseToUnit = Mat4Invert(toUnit);
        
        delta = Vec3TransformNormal(toUnit, delta);
        if(Vec3Length(delta) > 0.5f) {
            delta = Vec3Normalize(delta) * 0.5f;
        }
        position = Vec3TransformNormal(toUnit, position);
        
        position += delta;
        
        for(int i = 0; i < 3; i++) {
            Vec3 rPosition = { 0, 0, 0 }, rNormal = { 0, 0, 0 };
            BOOL hit = NO;
            float time = 1;
            
            for(int j = 0; j != (int)(self.triangles.length / sizeof(Triangle)); j++) {
                Triangle triangle = ((Triangle*)self.triangles.mutableBytes)[j];
                
                if(TriangleResolve(triangle, toUnit, position, 1, &rPosition, &rNormal, &time)) {
                    hit = YES;
                }
            }
            if(hit) {
                rNormal = Vec3Normalize(Vec3TransformNormal(inverseToUnit, rNormal));
                if(acosf(MAX(-0.999f, MIN(0.999f, Vec3Dot(rNormal, Vec3Make(0, 1, 0))))) * 180 / PI < _groundSlope) {
                    groundNormal += rNormal;
                    _onGround = YES;
                }
                position = rPosition;
            } else {
                break;
            }
        }
        position = Vec3TransformNormal(inverseToUnit, position);
    }
    if(_onGround) {
        u = Vec3Normalize(groundNormal);
        r = Vec3Make(1, 0, 0);
        f = Vec3Normalize(Vec3Cross(r, u));
        r = Vec3Normalize(Vec3Cross(u, f));
        _groundMatrix = Mat4Make(r.x, u.x, f.x, 0,
                                 r.y, u.y, f.y, 0,
                                 r.z, u.z, f.z, 0,
                                 0, 0, 0, 1
                                 );
        _velocity.y = 0;
    }
    self.position = position;
}

@end

@interface Map ()

@property NSString* path;
@property Vec3 position;
@property Vec2 direction;
@property Vec4 ambientColor;

@property Scene* scene;
@property Sprite* sprite;
@property (weak) FPSCamera* camera;

@end

@implementation Map

- (id)initWithPath:(NSString *)path position:(Vec3)position direction:(Vec2)direction ambientColor:(Vec4)ambientColor {
    self = [super init];
    if(self) {
        self.path = path;
        self.position = position;
        self.direction = direction;
        self.ambientColor = ambientColor;
    }
    return self;
}

- (void)setup:(MTLView *)view {
    self.scene = [[Scene alloc] init];
    
    FPSCamera* camera = [[FPSCamera alloc] init];
    
    camera.position = self.position;
    camera.rotation = Mat4Look(Vec3Make(self.direction.x, 0, self.direction.y), Vec3Make(0, 1, 0));
    
    [self.scene.root addChild:camera];
    [self setCamera:camera];
    
    [camera activate];
    
    Light* light = [[AmbientLight alloc] init];
    
    light.color = self.ambientColor;
    
    [self.scene.root addChild:light];
    
    Node* map = [view.assets load:self.path];
    
    for(int i = 0; i != map.childCount; i++) {
        Mesh* mesh = [map childAt:i];
        
        for(int j = 0; j != mesh.indexCount; ) {
            Vertex v1 = [mesh vertexAt:[mesh indexAt:j++]];
            Vertex v2 = [mesh vertexAt:[mesh indexAt:j++]];
            Vertex v3 = [mesh vertexAt:[mesh indexAt:j++]];
            Triangle triangle = TriangleMake(v1.position, v2.position, v3.position);
            
            [camera.triangles appendBytes:&triangle length:sizeof(Triangle)];
        }
    }
    [self.scene.root addChild:map];
    
    self.sprite = [[Sprite alloc] initWithView:view texture:[view.assets load:@"assets/font.png"]];
    
    view.fpsMouseEnabled = YES;
}

- (void)nextFrame:(MTLView *)view {
    id<CAMetalDrawable> drawable = view.currentDrawable;
    
    [self.scene.root calcTransform];
    [self.scene.root updateWithScene:self.scene view:view];
    
    if(drawable) {
        view.currentRenderPassDescriptor.colorAttachments[0].texture = drawable.texture;
        
        id<MTLCommandBuffer> commandBuffer = [view.commandQueue commandBuffer];
        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:view.currentRenderPassDescriptor];
        
        [encoder setViewport:(MTLViewport){ 0, 0, view.drawableSize.width, view.drawableSize.height, 0, 1 }];
        [self.scene encodeWithEncoder:encoder size:view.drawableSize];
        [self.sprite encodeWithEncoder:encoder size:view.drawableSize];
        [encoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
    }
    
    NSString* pos = [NSString stringWithFormat:@"POS = %i, %i, %i", (int)self.camera.position.x, (int)self.camera.position.y, (int)self.camera.position.z];
    
    [self.sprite begin];
    [self.sprite pustText:[NSString stringWithFormat:@"FPS = %i\nOBJ = %i\n%@\n%@", view.frameRate, XObject.instances, pos, (view.fpsMouseEnabled) ? @"ESC = Release mouse" : @""]
                       cw:8 ch:12
                  columns:100
                    scale:2
              lineSpacing:5
                 location:NSMakePoint(10, 10)
                    color:Vec4Make(1, 1, 1, 1)
    ];
    [self.sprite end];
    
    if([view isKeyDown:53]) {
        view.fpsMouseEnabled = NO;
    }
}

- (void)tearDown {
    self.scene = nil;
    self.sprite = nil;
}

- (NSString*)description {
    return self.path.lastPathComponent;
}

@end
