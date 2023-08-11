//
//  Plot.m
//  X3DTest
//
//  Created by Douglas McNamara on 8/10/23.
//

#import "Test.h"

#define H 50
#define D 64

@interface RotatingPointLight : PointLight

@property float angularVelocity;

- (id)initWithPosition:(Vec3)position color:(Vec4)color range:(float)range angularVelocity:(float)velocity;

@end

@implementation RotatingPointLight

- (id)initWithPosition:(Vec3)position color:(Vec4)color range:(float)range angularVelocity:(float)velocity {
    self = [super init];
    if(self) {
        self.position = position;
        self.color = color;
        self.range = range;
        self.angularVelocity = velocity;
    }
    return self;
}

- (Mat4)localModel {
    return Mat4Mul(self.rotation, Mat4Translate(self.position));
}

- (void)onUpdateWithScene:(Scene *)scene view:(MTLView *)view {
    self.rotation = Mat4Mul(self.rotation, Mat4Rotate(self.angularVelocity * view.elapsedTime, Vec3Make(0, 1, 0)));
}

@end

@interface Graph : Mesh

@property (readonly) float h;
@property (readonly) int d;

- (void)plot;

@end

@implementation Graph

- (id)initWithView:(MTLView *)view {
    self = [super initWithView:view];
    if(self) {
        _h = 50;
        _d = -1;
        
        for(int i = 0; i != D - 1; i++) {
            for(int j = 0; j != D - 1; j++) {
                [self pushFace:@[ @(i * D + j), @((i + 1) * D + j), @((i + 1) * D + j + 1), @(i * D + j + 1) ]];
            }
        }
        [self bufferIndices];
        [self plot];
        
        self.texture = [view.assets load:@"assets/textures/checker.png"];
    }
    return self;
}

- (void)plot {
    [self clearVertices];
    for(int i = 0; i != D; i++) {
        for(int j = 0; j != D; j++) {
            float x = -50 + i / (D - 1.0f) * 100;
            float z = -50 + j / (D - 1.0f) * 100;
            float y = _h / (1 + (x * 0.1f) * (x * 0.1f) + (z * 0.1f) * (z * 0.1f));
            
            [self pushVertex:(Vertex){ { x, y, z }, { i / (D - 1.0f) * 4, j / (D - 1.0f) * 4 }, { 0, 0, 0 } }];
        }
    }
    [self calcNormals];
    [self bufferVertices];
}

- (void)onUpdateWithScene:(Scene *)scene view:(MTLView *)view {
    _h += _d * 100 * view.elapsedTime;
    if(_h < -(H - 1)) {
        _d = 1;
    } else if(_h > H - 1) {
        _d = -1;
    }
    [self plot];
}

@end

@interface Plot ()

@property Scene* scene;
@property Sprite* sprite;

@end

@implementation Plot

- (void)setup:(MTLView *)view {
    self.scene = [[Scene alloc] init];
    
    Camera* camera = [[Camera alloc] init];
    
    camera.position = Vec3Make(100, 100, 100);
    camera.rotation = Mat4Look(Vec3Make(-1, -1, -1), Vec3Make(0, 1, 0));
    
    [self.scene.root addChild:camera];
    
    [camera activate];
    
    Light* light = [[AmbientLight alloc] init];
    
    light.color = Vec4Make(0.5f, 0.5f, 0.5f, 1);
    
    [self.scene.root addChild:light];
    
    [self.scene.root addChild:[[RotatingPointLight alloc] initWithPosition:Vec3Make(+40, 20, 0)
                                                                     color:Vec4Make(2, 1, 0, 1)
                                                                     range:200
                                                           angularVelocity:+180]
    ];
    [self.scene.root addChild:[[RotatingPointLight alloc] initWithPosition:Vec3Make(-40, 20, 0)
                                                                     color:Vec4Make(0, 1, 2, 1)
                                                                     range:200
                                                           angularVelocity:-180]
    ];
    
    [self.scene.root addChild:[[Graph alloc] initWithView:view]];
    
    self.sprite = [[Sprite alloc] initWithView:view texture:[view.assets load:@"assets/font.png"]];
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
    
    [self.sprite begin];
    [self.sprite pustText:[NSString stringWithFormat:@"FPS = %i\nOBJ = %i", view.frameRate, XObject.instances]
                       cw:8 ch:12
                  columns:100
                    scale:2
              lineSpacing:5
                 location:NSMakePoint(10, 10)
                    color:Vec4Make(0, 0, 0, 1)
    ];
    [self.sprite end];
}

- (void)tearDown {
    self.scene = nil;
    self.sprite = nil;
}

@end

