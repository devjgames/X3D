//
//  CollisionTest.m
//  X3DTest
//
//  Created by Douglas McNamara on 6/13/23.
//

#import "Test.h"

#define RADIUS_Y 32
#define RADIUS_XZ 8

@interface Animator ()

@end

@implementation Animator

- (void)setup:(MTLView *)view scene:(Scene *)scene node:(Node *)node lights:(NSMutableData *)lights {
}

- (void)animate:(MTLView *)view scene:(Scene *)scene node:(Node *)node {
}

@end

@interface Player ()

@property Scene* scene;
@property BasicEncodable* text;
@property NSMutableData* lights;
@property NSString* path;

- (void)setupNode:(Node*)node view:(MTLView*)view;
- (void)animateNode:(Node*)node view:(MTLView*)view;

@end

@implementation Player;

- (id)initWithPath:(NSString *)path baseURL:(NSURL *)baseURL {
    self = [super init];
    if(self) {
        self.path = path;
    }
    return self;
}

- (void)setup:(MTLView *)view {
    self.scene = [[Scene alloc] init];
    self.scene.camera.eye = Vec3Make(300, 300, 300);
    
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

    Node* node = [view.assets load:self.path];
    
    [self.scene.root addChild:node];
    [self.scene.camera calcTransforms:view.aspectRatio];
    [self.scene.root calcTransform];
    
    [self setupNode:self.scene.root view:view];
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
    
    [self animateNode:self.scene.root view:view];
    [self.scene.root updateWithScene:self.scene view:view];
    
    return ![view isKeyDown:53];
}

- (void)tearDown {
    self.scene = nil;
    self.text = nil;
    self.lights = nil;
}

- (NSString*)description {
    NSString* name = [self.path.lastPathComponent stringByDeletingPathExtension];
    unichar c = [name characterAtIndex:0];
    
    c = toupper(c);
    name = [NSString stringWithFormat:@"%c%@", c, [name substringFromIndex:1]];
    
    return name;
}

- (void)setupNode:(Node *)node view:(MTLView *)view {
    if(node.userData) {
        if([node.userData isKindOfClass:[Animator class]]) {
            Animator* animator = node.userData;
            
            [animator setup:view scene:self.scene node:node lights:self.lights];
        }
    }
    for(int i = 0; i != node.childCount; i++) {
        [self setupNode:[node childAt:i] view:view];
    }
}

- (void)animateNode:(Node *)node view:(MTLView *)view {
    if(node.userData) {
        if([node.userData isKindOfClass:[Animator class]]) {
            Animator* animator = node.userData;
            
            [animator animate:view scene:self.scene node:node];
        }
    }
    for(int i = 0; i != node.childCount; i++) {
        [self animateNode:[node childAt:i] view:view];
    }
}

@end
