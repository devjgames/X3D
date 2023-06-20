//
//  CollisionTest.m
//  X3DTest
//
//  Created by Douglas McNamara on 6/13/23.
//

#import "Test.h"

#define RADIUS 32

@interface CollisionTest ()

@property Scene* scene;
@property Node* player;
@property BasicEncodable* text;
@property NSMutableData* triangles;
@property NSMutableData* lights;
@property Vec3 velocity;
@property Vec3 groundNormal;
@property Mat4 groundMatrix;
@property BOOL onGround;
@property Sound* jump;
@property Sound* pain;
@property Vec3 start;
@property Vec3 offset;
@property Vec4 color;
@property float fall;
@property int jumpAmount;
@property NSString* path;

@end

@implementation CollisionTest

- (id)initWithPath:(NSString *)path baseURL:(NSURL *)baseURL {
    self = [super init];
    if(self) {
        NSString* name = [path.lastPathComponent stringByDeletingPathExtension];
        NSString* cfgPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt", name]];
        NSArray<NSString*>* lines = [Parser split:[NSString stringWithContentsOfURL:[baseURL URLByAppendingPathComponent:cfgPath] encoding:NSASCIIStringEncoding error:nil]
                                           delims:[NSCharacterSet newlineCharacterSet]
        ];
            
        for(NSString* line in lines) {
            NSString* tLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSArray<NSString*>* tokens = [Parser split:tLine delims:[NSCharacterSet whitespaceCharacterSet]];

            if([tLine hasPrefix:@"start "]) {
                self.start = Vec3Make([tokens[1] floatValue], [tokens[2] floatValue], [tokens[3] floatValue]);
            } else if([tLine hasPrefix:@"fall "]) {
                self.fall = [tokens[1] floatValue];
            } else if([tLine hasPrefix:@"offset "]) {
                self.offset = Vec3Make([tokens[1] floatValue], [tokens[2] floatValue], [tokens[3] floatValue]);
            } else if([tLine hasPrefix:@"color "]) {
                self.color = Vec4Make([tokens[1] floatValue], [tokens[2] floatValue], [tokens[3] floatValue], [tokens[4] floatValue]);
            } else if([tLine hasPrefix:@"jump "]) {
                self.jumpAmount = [tokens[1] intValue];
            }
        }
        self.path = path;
    }
    return self;
}

- (void)setup:(MTLView *)view {
    self.scene = [[Scene alloc] init];
    self.scene.camera.eye = self.offset;
    
    self.text = [[BasicEncodable alloc] initWithView:view vertexCount:1];
    self.text.texture = [view.assets load:@"assets/font.png"];
    self.text.vertexColorEnabled = YES;
    self.text.blendEnabled = YES;
    self.text.depthTestEnabled = NO;
    self.text.depthWriteEnabled = NO;
    self.text.textureSampler = NEAREST_CLAMP_TO_EDGE;
    
    [self.text createDepthAndPipelineState];

    self.lights = [NSMutableData dataWithCapacity:MAX_LIGHTS * sizeof(Light)];
    
    view.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2f, 0.2f, 0.2f, 1);

    Mesh* mesh = [view.assets load:self.path];
    NSString* name = [self.path.lastPathComponent stringByDeletingPathExtension];
    NSString* texture = [[self.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", name]];
    
    mesh.basicEncodable.texture = [view.assets load:texture];
    mesh.basicEncodable.textureSampler = LINEAR_CLAMP_TO_EDGE;
    mesh.basicEncodable.color = self.color;
    
    [self.scene.root addChild:mesh];
    
    self.triangles = [NSMutableData dataWithCapacity:mesh.indexCount / 3 * sizeof(Triangle)];
    
    for(int i = 0; i != mesh.indexCount; ) {
        int i1 = [mesh indexAt:i++];
        int i2 = [mesh indexAt:i++];
        int i3 = [mesh indexAt:i++];
        Triangle triangle = TriangleMake([mesh vertexAt:i1].position, [mesh vertexAt:i2].position, [mesh vertexAt:i3].position);
        
        triangle = TriangleTransform(mesh.model, triangle);
        
        [self.triangles appendBytes:&triangle length:sizeof(Triangle)];
    }
    
    KeyFrameMesh* kfMesh = [view.assets load:@"assets/md2/babyboom.md2"];
    
    kfMesh = [[KeyFrameMesh alloc] initWithKeyFrameMesh:kfMesh];
    kfMesh.rotation = Mat4Rotate(-90, Vec3Make(1, 0, 0));
    kfMesh.position -= Vec3Make(0, [kfMesh frameBoundsAt:0].min.z, 0);
    kfMesh.position -= Vec3Make(0, RADIUS, 0);
    kfMesh.basicEncodable.texture = [view.assets load:@"assets/md2/babyboom.png"];
    [kfMesh setSequenceStart:0 end:39 speed:10 looping:YES];
    
    self.player = [[Node alloc] init];
    self.player.position = self.start;
    self.player.rotation = Mat4Rotate(180, Vec3Make(0, 1, 0));
    [self.player addChild:kfMesh];
    
    [self.scene.root addChild:self.player];
    
    self.groundNormal = Vec3Make(0, 0, 0);
    self.groundMatrix = Mat4Identity();
    self.onGround = NO;

    self.jump = [view.assets load:@"assets/sound/jump.wav"];
    self.jump.player.volume = 0.25f;
    
    self.pain = [view.assets load:@"assets/sound/pain.wav"];
    self.pain.player.volume = 0.25f;
}

- (BOOL)nextFrame:(MTLView *)view {
    id<CAMetalDrawable> drawable = [view.metalLayer nextDrawable];
    
    if(drawable) {
        view.renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
        
        id<MTLCommandBuffer> commandBuffer = [view.commandQueue commandBuffer];
        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:view.renderPassDescriptor];
        
        [self.scene.camera calcTransforms:view.aspectRatio];
        [self.scene.root calcTransform];
        
        [encoder setViewport:(MTLViewport){ 0, 0, view.width, view.height, 0, 1 }];
        [self.scene encodeWithEncoder:encoder lights:self.lights];
        [self.text encodeWithEncoder:encoder
                          projection:Mat4Ortho(0, view.width, view.height, 0, -1, 1)
                                view:Mat4Identity()
                               model:Mat4Identity()
                              lights:self.lights];
        [encoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
    }
    
    NSString* info = [NSString stringWithFormat:@"FPS = %i\nOBJ = %i\nESC = Quit", view.frameRate, XObject.instances];
    
    [self.text clear];
    [self.text pushText:info xy:NSMakePoint(10, 10) size:NSMakeSize(8, 12) cols:100 lineSpacing:5 color:Vec4Make(1, 1, 1, 1)];
    [self.text bufferVertices];
    
    float dx = view.mouseX - view.width / 2;
    float dy = view.mouseY - view.height / 2;
    float dl = Vec2Length(Vec2Make(dx, dy));
    Vec3 f = -(self.scene.camera.eye - self.scene.camera.target) * Vec3Make(1, 0, 1);
    BOOL moving = false;
    KeyFrameMesh* mesh = [self.player childAt:0];

    if([view isButtonDown:1]) {
        [self.scene.camera rotateDelta:NSMakePoint(-view.deltaX, 0)];
    }
    
    if([view isKeyDown:49] && self.onGround && self.jumpAmount > 0) {
        self.velocity = Vec3Make(0, self.jumpAmount, 0);
        
        [self.jump.player play];
    }
    
    self.velocity *= Vec3Make(0, 1, 0);
    if(Vec3Length(f) > 0.0000001 && dl > 0.1 && [view isButtonDown:0]) {
        Vec3 r = Vec3Normalize(Vec3Cross(f = Vec3Normalize(f), Vec3Make(0, 1, 0)));

        f = f * -100 * dy / dl + r * 100 * dx / dl;
        self.velocity += f;
        
        f = Vec3Normalize(f);
        
        float d = acosf(MAX(-0.999f, MIN(0.999f, f.x))) * 180 / PI;
        
        if(f.z > 0) {
            d = 360 - d;
        }
        self.player.rotation = Mat4Rotate(d, Vec3Make(0, 1, 0));
        moving = YES;
    }
    if(self.onGround) {
        BOOL set = mesh.looping;
        
        if(!set) {
            set = mesh.done;
        }
        if(set) {
            if(moving) {
                [mesh setSequenceStart:40 end:45 speed:7 looping:YES];
            } else {
                [mesh setSequenceStart:0 end:39 speed:10 looping:YES];
            }
        }
    } else {
        [mesh setSequenceStart:66 end:69 speed:7 looping:NO];
    }
    self.velocity -= Vec3Make(0, 3000 * view.elapsedTime, 0);
    
    Vec3 delta = Vec3TransformNormal(self.groundMatrix, self.velocity * view.elapsedTime);
    
    self.groundMatrix = Mat4Identity();
    self.groundNormal = Vec3Make(0, 0, 0);
    self.onGround = NO;
    
    if(Vec3Length(delta) > 0.0000001) {
        Mat4 unitTransform = Mat4Scale(Vec3Make(1, 1, 1) / Vec3Make(RADIUS / 2, RADIUS, RADIUS / 2));
        Mat4 inverseUnitTransform = Mat4Invert(unitTransform);
        Vec3 position = Vec3Transform(unitTransform, self.player.position);
        
        delta = Vec3TransformNormal(unitTransform, delta);
        if(Vec3Length(delta) > 0.5f) {
            delta = Vec3Normalize(delta) * 0.5f;
        }
        position += delta;
        for(int l = 0; l != 3; l++) {
            float time = 1;
            Vec3 rPos = Vec3Make(0, 0, 0);
            Vec3 rNormal = Vec3Make(0, 0, 0);
            BOOL hit = NO;
            
            for(int i = 0; i != (int)(self.triangles.length / sizeof(Triangle)); i++) {
                Triangle triangle = ((Triangle*)self.triangles.mutableBytes)[i];
                
                if(TriangleResolve(triangle, unitTransform, position, 1, &rPos, &rNormal, &time)) {
                    hit = YES;
                }
            }
            if(hit) {
                rNormal = Vec3Normalize(Vec3TransformNormal(inverseUnitTransform, rNormal));
                if(acosf(MAX(-0.999f, MIN(0.999f, Vec3Dot(rNormal, Vec3Make(0, 1, 0))))) < PI / 4) {
                    self.onGround = YES;
                    self.velocity *= Vec3Make(1, 0, 1);
                    self.groundNormal += rNormal;
                }
                if(acosf(MAX(-0.999f, MIN(0.999f, Vec3Dot(rNormal, Vec3Make(0, -1, 0))))) < PI / 4) {
                    self.velocity *= Vec3Make(1, 0, 1);
                }
                position = rPos;
            } else {
                break;
            }
        }
        if(self.onGround) {
            Vec3 u = Vec3Normalize(self.groundNormal);
            Vec3 r = Vec3Make(1, 0, 0);
            Vec3 f = Vec3Normalize(Vec3Cross(r, u));
            
            r = Vec3Normalize(Vec3Cross(u, f));
            
            self.groundMatrix = Mat4Make(r.x, u.x, f.x, 0,
                                         r.y, u.y, f.y, 0,
                                         r.z, u.z, f.z, 0,
                                         0, 0, 0, 1
                                         );
        }
        self.player.position = Vec3Transform(inverseUnitTransform, position);
    }
    
    Vec3 p = self.player.position;
    
    if(p.y < self.fall) {
        self.player.position = p = self.start;
        
        [self.pain.player play];
    }
    
    f = self.scene.camera.eye - self.scene.camera.target;
    
    self.scene.camera.target = p;
    self.scene.camera.eye = self.scene.camera.target + f;
    
    [self.scene.root updateWithScene:self.scene view:view];
    
    return ![view isKeyDown:53];
}

- (void)tearDown {
    self.scene = nil;
    self.player = nil;
    self.text = nil;
    self.triangles = nil;
    self.lights = nil;
    self.jump = nil;
    self.pain = nil;
}

- (NSString*)description {
    NSString* name = [self.path.lastPathComponent stringByDeletingPathExtension];
    unichar c = [name characterAtIndex:0];
    
    c = toupper(c);
    name = [NSString stringWithFormat:@"%c%@", c, [name substringFromIndex:1]];
    
    return name;
}

@end
