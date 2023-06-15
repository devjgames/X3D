//
//  LightMapperTest.m
//  X3DTest
//
//  Created by Douglas McNamara on 6/11/23.
//

#import "Test.h"

@interface LightMapperTest ()

@property Scene* scene;
@property BasicEncodable* text;
@property NSMutableData* lights;
@property float offsetLength;

@end

@implementation LightMapperTest

- (void)setup:(MTLView *)view {
    self.scene = [[Scene alloc] init];
    
    self.scene.camera.target = Vec3Make(0, 16, 0);
    self.scene.camera.eye = self.scene.camera.target + Vec3Make(100, 100, 100);
    self.offsetLength = Vec3Length(self.scene.camera.eye - self.scene.camera.target);
    
    self.text = [[BasicEncodable alloc] initWithView:view vertexCount:1];
    self.text.texture = [view.assets load:@"assets/font.png"];
    self.text.vertexColorEnabled = YES;
    self.text.blendEnabled = YES;
    self.text.depthTestEnabled = NO;
    self.text.depthWriteEnabled = NO;
    self.text.textureSampler = NEAREST_CLAMP_TO_EDGE;
    
    [self.text createDepthAndPipelineState];
    
    Light lights[] = {
        { { 50, 75, 50 }, { 1.5f, 0.75f, 0.5f, 1 }, 400 }
    };
    
    self.lights = [NSMutableData dataWithBytes:lights length:sizeof(lights)];
    
    view.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2f, 0.2f, 0.2f, 1);
    
    LightMapper* lightMapper = [[LightMapper alloc] initWithView:view width:256 height:64];
    Mesh* mesh = [[Mesh alloc] initWithView:view];
    Mesh* groundMesh = [[Mesh alloc] initWithView:view];
    
    [lightMapper clear];
    for(int i = 0; i != [KeyFrameMeshLoader normalCount]; i++) {
        [lightMapper pushSample:[KeyFrameMeshLoader normalAt:i]];
    }
    
    [mesh pushBox:Vec3Make(32, 32, 32) position:Vec3Make(0, 16, 0) rotation:Vec3Make(0, 0, 0) invert:false];
    
    [mesh calcTextureCoordinates:64];
    
    [groundMesh pushVertex:Vertex(-64, +00, -64, 0, 0, 0, 0, 0, +1, 0, 1, 1, 1, 1)];
    [groundMesh pushVertex:Vertex(+64, +00, -64, 0, 0, 0, 0, 0, +1, 0, 1, 1, 1, 1)];
    [groundMesh pushVertex:Vertex(+64, +00, +64, 0, 0, 0, 0, 0, +1, 0, 1, 1, 1, 1)];
    [groundMesh pushVertex:Vertex(-64, +00, +64, 0, 0, 0, 0, 0, +1, 0, 1, 1, 1, 1)];
    [groundMesh pushFace:@[ @(0), @(1), @(2), @(3) ] swapWinding:NO];
    
    [groundMesh calcTextureCoordinates:128];
    
    int x = 0, w, h;
    
    for(int i = 0; i != mesh.faceCount; i++) {
        [lightMapper pushQuad:i mesh:mesh x:x y:0 width:&w height:&h ambient:Vec4Make(0.3f, 0.3f, 0.6f, 1) diffuse:Vec4Make(1, 1, 1, 1) scale:2];
        
        x += w;
    }
    [mesh bufferVertices];
    
    for(int i = 0; i != groundMesh.faceCount; i++) {
        [lightMapper pushQuad:i mesh:groundMesh x:x y:0 width:&w height:&h ambient:Vec4Make(0.3f, 0.3f, 0.6f, 1) diffuse:Vec4Make(1, 1, 1, 1) scale:2];
        
        x += w;
    }
    [groundMesh bufferVertices];
    
    [lightMapper buffer];
    
    NSMutableData* vertices = [NSMutableData dataWithCapacity:100 * sizeof(Vec3)];
    NSMutableData* indices = [NSMutableData dataWithLength:300 * 4];

    [mesh pushAccelPositions:vertices indices:indices];
    [groundMesh pushAccelPositions:vertices indices:indices];
    
    [lightMapper render:[lightMapper createAccel:vertices indices:indices] lights:self.lights];
    
    mesh.basicEncodable.texture2 = lightMapper.texture;
    mesh.basicEncodable.texture2Sampler = LINEAR_CLAMP_TO_EDGE;
    mesh.basicEncodable.texture = [view.assets load:@"assets/textures/stone.png"];
    mesh.basicEncodable.textureSampler = LINEAR_REPEAT;
    
    groundMesh.basicEncodable.texture2 = lightMapper.texture;
    groundMesh.basicEncodable.texture2Sampler = LINEAR_CLAMP_TO_EDGE;
    groundMesh.basicEncodable.texture = [view.assets load:@"assets/textures/dirt.png"];
    groundMesh.basicEncodable.textureSampler = LINEAR_REPEAT;
    
    [self.scene.root addChild:mesh];
    [self.scene.root addChild:groundMesh];
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
    
    if([view isButtonDown:0]) {
        [self.scene.camera rotate:view];
    }
    
    Vec3 o = self.scene.camera.target;
    Vec3 d = Vec3Normalize(self.scene.camera.eye - o);
    float time = self.offsetLength + 14;
    float t = Vec3Dot(d, Vec3Make(0, 1, 0));
    float length = self.offsetLength;
    
    if(fabsf(t) > 0.0000001) {
        t = -Vec3Dot(o, Vec3Make(0, 1, 0)) / t;
        if(t > 0.0000001 && t < time) {
            length = MIN(length, t) - 14;
        }
    }
    self.scene.camera.eye = o + d * length;
    
    [self.scene.root updateWithScene:self.scene view:view];
    
    NSString* info = [NSString stringWithFormat:@"FPS = %i\nOBJ = %i\nESC = Quit", view.frameRate, XObject.instances];
    
    [self.text clear];
    [self.text pushText:info xy:NSMakePoint(10, 10) size:NSMakeSize(8, 12) cols:100 lineSpacing:5 color:Vec4Make(1, 1, 1, 1)];
    [self.text bufferVertices];
    
    return ![view isKeyDown:53];
}

- (void)tearDown {
    self.scene = nil;
    self.text = nil;
    self.lights = nil;
}

@end
