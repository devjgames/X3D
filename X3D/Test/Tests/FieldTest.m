//
//  FieldTest.m
//  X3DTest
//
//  Created by Douglas McNamara on 6/15/23.
//

#import "Test.h"

@interface FieldTest ()

@property Scene* scene;
@property Mesh* mesh;
@property BasicEncodable* text;
@property NSString* info;
@property BOOL reset;
@property MTLRenderPassDescriptor* renderPassDescriptor;

@end

@implementation FieldTest

- (void)setup:(MTLView *)view {
    self.scene = [[Scene alloc] initInDesign:YES];
    self.scene.camera.eye = Vec3Make(60, 60, 60);
    
    self.mesh = [[Mesh alloc] initWithView:view];
    self.mesh.basicEncodable.vertexColorEnabled = YES;
    [self.mesh pushBox:Vec3Make(50, 50, 50) position:Vec3Make(0, 0, 0) rotation:Vec3Make(0, 0, 0) invert:NO];
    for(int i = 0; i != self.mesh.vertexCount; i++) {
        BasicVertex v = [self.mesh vertexAt:i];
        
        if(v.position.y < 0) {
            v.color = Vec4Make(1, 0, 0, 1);
        } else {
            v.color = Vec4Make(1, 1, 0, 1);
        }
        [self.mesh setVertex:v at:i];
    }
    [self.mesh bufferVertices];
    [self.scene.root addChild:self.mesh];
    
    self.text = [[BasicEncodable alloc] initWithView:view vertexCount:1];
    self.text.texture = [view.assets load:@"assets/font.png"];
    self.text.vertexColorEnabled = YES;
    self.text.depthTestEnabled = NO;
    self.text.depthWriteEnabled = NO;
    self.text.blendEnabled = YES;
    self.text.textureSampler = NEAREST_CLAMP_TO_EDGE;
    
    [self.text createDepthAndPipelineState];
    
    self.info = @"Hello World!";
    self.reset = YES;
    
    view.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2f, 0.2f, 0.2f, 1);
    
    MTLTextureDescriptor* descriptor = [[MTLTextureDescriptor alloc] init];
    
    descriptor.width = 256;
    descriptor.height = 256;
    descriptor.textureType = MTLTextureType2D;
    descriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
    descriptor.pixelFormat = view.metalLayer.pixelFormat;
    
    self.renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
    self.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1);
    self.renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    self.renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    self.renderPassDescriptor.colorAttachments[0].texture = [view.device newTextureWithDescriptor:descriptor];
    
    descriptor.usage = MTLTextureUsageRenderTarget;
    descriptor.pixelFormat = view.renderPassDescriptor.depthAttachment.texture.pixelFormat;
    
    self.renderPassDescriptor.depthAttachment.clearDepth = 1;
    self.renderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    self.renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
    self.renderPassDescriptor.depthAttachment.texture = [view.device newTextureWithDescriptor:descriptor];
}

- (BOOL)nextFrame:(MTLView *)view {
    int w = (int)self.renderPassDescriptor.colorAttachments[0].texture.width;
    int h = (int)self.renderPassDescriptor.colorAttachments[0].texture.height;
    
    [self.text clear];
    [self.text pushText:self.info xy:NSMakePoint(w / 2 - self.info.length * 8 / 2, h / 2 - 6) size:NSMakeSize(8, 12) cols:100 lineSpacing:5 color:Vec4Make(0, 0, 0, 1)];
    [self.text bufferVertices];
    
    self.text.warpEnabled = YES;
    self.text.warpAmplitudes = Vec3Make(0, 16, 0);
    self.text.warpSpeed = 2;
    
    id<MTLCommandBuffer> commandBuffer = [view.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:self.renderPassDescriptor];
    
    [encoder setViewport:(MTLViewport){ 0, 0, w, h, 0, 1 }];
    [self.scene bufferLights];
    [self.text encodeWithEncoder:encoder
                      projection:Mat4Ortho(0, w, h, 0, -1, 1)
                            view:Mat4Identity()
                           model:Mat4Identity()
                          lights:nil];
    [encoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    self.text.warpEnabled = NO;
    self.mesh.basicEncodable.texture = self.renderPassDescriptor.colorAttachments[0].texture;
    
    NSString* info = [NSString stringWithFormat:@"FPS = %i\nOBJ = %i\nESC = Quit", view.frameRate, XObject.instances];
    
    [self.text clear];
    [self.text pushText:info xy:NSMakePoint(10, 10) size:NSMakeSize(8, 12) cols:100 lineSpacing:5 color:Vec4Make(1, 1, 1, 1)];
    [self.text bufferVertices];
    
    id<CAMetalDrawable> drawable = [view.metalLayer nextDrawable];
    
    if(drawable) {
        view.renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
        
        commandBuffer = [view.commandQueue commandBuffer];
        encoder = [commandBuffer renderCommandEncoderWithDescriptor:view.renderPassDescriptor];
        
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
    
    if([view isButtonDown:0]) {
        [self.scene.camera rotate:view];
    }
    [self.scene.root updateWithScene:self.scene view:view];
    
    id result;
    
    [view.ui begin];
    if((result = [view.ui field:@"FieldTest.info.field" gap:0 caption:@"Info" text:self.info width:250 reset:self.reset])) {
        self.info = result;
    }
    [view.ui end];
    
    self.reset = NO;
    
    return ![view isKeyDown:53];
}

- (void)tearDown {
    self.scene = nil;
    self.mesh = nil;
    self.text = nil;
    self.renderPassDescriptor = nil;
}

@end
