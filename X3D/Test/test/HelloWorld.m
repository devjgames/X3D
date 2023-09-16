//
//  HelloWorld.m
//  X3DTest
//
//  Created by Douglas McNamara on 8/9/23.
//

#import "Test.h"

@interface RotatingQuad : Mesh

@end

@implementation RotatingQuad

- (id)initWithView:(MTLView *)view {
    self = [super initWithView:view];
    if(self) {
        [self pushVertex:(Vertex){ { -50, 0, -50 }, { 0, 0 }, { 0, 1, 0 } }];
        [self pushVertex:(Vertex){ { +50, 0, -50 }, { 2, 0 }, { 0, 1, 0 } }];
        [self pushVertex:(Vertex){ { +50, 0, +50 }, { 2, 2 }, { 0, 1, 0 } }];
        [self pushVertex:(Vertex){ { -50, 0, +50 }, { 0, 2 }, { 0, 1, 0 } }];
        
        [self pushFace:@[ @0, @1, @2, @3 ]];
        
        [self bufferVertices];
        [self bufferIndices];
        
        self.texture = [view.assets load:@"assets/textures/checker.png"];
    }
    return self;
}

- (void)onUpdateWithScene:(Scene *)scene view:(MTLView *)view {
    self.rotation = Mat4Mul(self.rotation, Mat4Rotate(45 * view.elapsedTime, Vec3Make(0, 1, 0)));
}

@end

@interface HelloWorld ()

@property Scene* scene;
@property Sprite* sprite;
@property Light* light;

@end

@implementation HelloWorld

- (void)setup:(MTLView *)view {
    self.scene = [[Scene alloc] init];
    
    Camera* camera = [[Camera alloc] init];
    
    camera.position = Vec3Make(100, 100, 100);
    camera.rotation = Mat4Look(Vec3Make(-1, -1, -1), Vec3Make(0, 1, 0));
    
    [self.scene.root addChild:camera];
    
    [camera activate];
    
    self.light = [[AmbientLight alloc] init];
    self.light.color = Vec4Make(0.5f, 0.5f, 0.5f, 1);
    
    [self.scene.root addChild:self.light];
    
    [self.scene.root addChild:[[RotatingQuad alloc] initWithView:view]];
    
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

- (void)handleUI:(UIManager *)ui reset:(BOOL)reset {
    Vec4 color = self.light.color;
    
    [ui addRow:5];
    [ui field:@"HelloWorld.color.field" gap:0 caption:@"Color" vec4Value:&color width:100 reset:reset];
    
    self.light.color = color;
}

- (void)tearDown {
    self.scene = nil;
    self.sprite = nil;
    self.light = nil;
}

@end
