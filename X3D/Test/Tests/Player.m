//
//  CollisionTest.m
//  X3DTest
//
//  Created by Douglas McNamara on 6/13/23.
//

#import "Test.h"

static Player* INSTANCE = nil;

@interface Player ()

@property Scene* scene;
@property BasicEncodable* text;
@property NSURL* url;

@end

@implementation Player;

- (id)initWithPath:(NSString *)path baseURL:(NSURL *)baseURL {
    self = [super init];
    if(self) {
        self.url = [baseURL URLByAppendingPathComponent:path];
    }
    return self;
}

- (void)setup:(MTLView *)view {
    view.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2f, 0.2f, 0.2f, 1);
    
    INSTANCE = self;

    self.info = @"";
    self.scene = [Scene deserialize:self.url view:view inDesign:NO];
    
    self.text = [[BasicEncodable alloc] initWithView:view vertexCount:1];
    self.text.texture = [view.assets load:@"assets/font.png"];
    self.text.vertexColorEnabled = YES;
    self.text.blendEnabled = YES;
    self.text.depthTestEnabled = NO;
    self.text.depthWriteEnabled = NO;
    self.text.textureSampler = NEAREST_CLAMP_TO_EDGE;
    
    [self.text createDepthAndPipelineState];
}

- (BOOL)nextFrame:(MTLView *)view {
    id<CAMetalDrawable> drawable = [view.metalLayer nextDrawable];
    
    [self.scene.root preUpdateWithScene:self.scene view:view];
    
    if(drawable) {
        view.renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
        
        id<MTLCommandBuffer> commandBuffer = [view.commandQueue commandBuffer];
        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:view.renderPassDescriptor];
        
        [self.scene.camera calcTransforms:view.aspectRatio];
        [self.scene.root calcTransform];
        
        [encoder setViewport:(MTLViewport){ 0, 0, view.width, view.height, 0, 1 }];
        [self.scene bufferLights];
        [self.scene encodeWithEncoder:encoder];
        [self.text encodeWithEncoder:encoder
                          projection:Mat4Ortho(0, view.width, view.height, 0, -1, 1)
                                view:Mat4Identity()
                               model:Mat4Identity()
                              lights:nil];
        [encoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
    }
    
    NSString* info = [NSString stringWithFormat:@"FPS = %i\nOBJ = %i\nESC = Quit", view.frameRate, XObject.instances];
    int h = view.height;
    
    [self.text clear];
    [self.text pushText:info xy:NSMakePoint(10, 10) size:NSMakeSize(8, 12) cols:100 lineSpacing:5 color:Vec4Make(1, 1, 1, 1)];
    [self.text pushText:self.info xy:NSMakePoint(10, h - 22) size:NSMakeSize(8, 12) cols:100 lineSpacing:5 color:Vec4Make(1, 1, 1, 1)];
    [self.text bufferVertices];
    
    [self.scene.root updateWithScene:self.scene view:view];
    
    return ![view isKeyDown:53];
}

- (void)tearDown {
    self.scene = nil;
    self.text = nil;
    
    INSTANCE = nil;
}

- (NSString*)description {
    NSString* name = [self.url.lastPathComponent stringByDeletingPathExtension];
    unichar c = [name characterAtIndex:0];
    
    c = toupper(c);
    name = [NSString stringWithFormat:@"%c%@", c, [name substringFromIndex:1]];
    
    return name;
}

+ (Player*)instance {
    return INSTANCE;
}

@end
