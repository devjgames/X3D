//
//  LightMapper.m
//  X3D
//
//  Created by Douglas McNamara on 6/11/23.
//

#import <X3D/X3D.h>

typedef struct Uniforms {
    float sampleRadius;
    float aoLength;
    float aoStrength;
    UInt8 sampleCount;
    UInt8 lightCount;
    Light lights[MAX_LIGHTS];
} Uniforms;

@interface LightMapper ()

@property (weak) MTLView* view;
@property NSMutableData* vertices;
@property NSMutableData* samples;
@property id<MTLBuffer> vertexBuffer;
@property id<MTLBuffer> sampleBuffer;
@property MTLRenderPassDescriptor* renderPassDescriptor;
@property id<MTLRenderPipelineState> pipelineState;
@property id<MTLDepthStencilState> depthState;

@end

@implementation LightMapper

- (id)initWithView:(MTLView*)view width:(int)width height:(int)height {
    self = [super init];
    if(self) {
        self.view = view;
        self.vertices = [NSMutableData dataWithCapacity:sizeof(LMVertex) * 300];
        self.samples = [NSMutableData dataWithCapacity:sizeof(Vec3) * 128];
        self.vertexBuffer = nil;
        self.sampleBuffer = nil;
        
        MTLTextureDescriptor* textureDescriptor = [[MTLTextureDescriptor alloc] init];
        
        textureDescriptor.width = width;
        textureDescriptor.height = height;
        textureDescriptor.pixelFormat = MTLPixelFormatRGBA32Float;
        textureDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
        textureDescriptor.textureType = MTLTextureType2D;
        
        self.renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
        self.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 1, 1);
        self.renderPassDescriptor.colorAttachments[0].texture = [view.device newTextureWithDescriptor:textureDescriptor];
        self.renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        self.renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        
        textureDescriptor.pixelFormat = MTLPixelFormatDepth32Float;
        
        self.renderPassDescriptor.depthAttachment.texture = [view.device newTextureWithDescriptor:textureDescriptor];
        
        MTLRenderPipelineDescriptor* pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        
        pipelineDescriptor.vertexFunction = [view.library newFunctionWithName:@"lightVertexShader"];
        pipelineDescriptor.fragmentFunction = [view.library newFunctionWithName:@"lightFragmentShader"];
        pipelineDescriptor.colorAttachments[0].pixelFormat = self.renderPassDescriptor.colorAttachments[0].texture.pixelFormat;
        pipelineDescriptor.colorAttachments[0].blendingEnabled = NO;
        pipelineDescriptor.depthAttachmentPixelFormat = self.renderPassDescriptor.depthAttachment.texture.pixelFormat;
        
        NSError* error = nil;
        
        self.pipelineState = [self.view.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
        
        if(error) {
            Log(@"%@", [error description]);
        }
        
        MTLDepthStencilDescriptor* depthDescriptor = [[MTLDepthStencilDescriptor alloc] init];
        
        depthDescriptor.depthWriteEnabled = NO;
        depthDescriptor.depthCompareFunction = MTLCompareFunctionAlways;
        
        self.depthState = [self.view.device newDepthStencilStateWithDescriptor:depthDescriptor];
        
        self.sampleRadius = 32;
        self.aoLength = 16;
        self.aoStrength = 2;
    }
    return self;
}

- (void)clear {
    self.vertices.length = 0;
    self.samples.length = 0;
}

- (void)pushVertex:(LMVertex)vertex {
    [self.vertices appendBytes:&vertex length:sizeof(LMVertex)];
}

- (void)pushSample:(Vec3)sample {
    [self.samples appendBytes:&sample length:sizeof(Vec3)];
}

- (void)pushQuad:(int)i mesh:(Mesh *)mesh x:(int)x y:(int)y width:(int *)width height:(int *)height ambient:(Vec4)ambient diffuse:(Vec4)diffuse scale:(int)scale {
    BasicVertex v1 = [mesh vertexAt:[mesh face:i vertexAt:0]];
    BasicVertex v2 = [mesh vertexAt:[mesh face:i vertexAt:1]];
    BasicVertex v3 = [mesh vertexAt:[mesh face:i vertexAt:2]];
    BasicVertex v4 = [mesh vertexAt:[mesh face:i vertexAt:3]];
    Vec3 u = v2.position - v1.position;
    Vec3 v = v3.position - v2.position;
    int w = MAX((int)Vec3Length(u) / scale, 1);
    int h = MAX((int)Vec3Length(v) / scale, 1);
    float psx = 1.0f / self.renderPassDescriptor.colorAttachments[0].texture.width;
    float psy = 1.0f / self.renderPassDescriptor.colorAttachments[0].texture.height;
    
    [self pushVertex:(LMVertex){ { x + 0, y + 0 }, v1.position, v1.normal, ambient, diffuse }];
    [self pushVertex:(LMVertex){ { x + w, y + 0 }, v2.position, v2.normal, ambient, diffuse }];
    [self pushVertex:(LMVertex){ { x + w, y + h }, v3.position, v3.normal, ambient, diffuse }];
    [self pushVertex:(LMVertex){ { x + w, y + h }, v3.position, v3.normal, ambient, diffuse }];
    [self pushVertex:(LMVertex){ { x + 0, y + h }, v4.position, v4.normal, ambient, diffuse }];
    [self pushVertex:(LMVertex){ { x + 0, y + 0 }, v1.position, v1.normal, ambient, diffuse }];
    
    v1.textureCoordinate2 = Vec2Make((x + 0 + 0.5f) * psx, (y + 0 + 0.5f) * psy);
    v2.textureCoordinate2 = Vec2Make((x + w - 0.5f) * psx, (y + 0 + 0.5f) * psy);
    v3.textureCoordinate2 = Vec2Make((x + w - 0.5f) * psx, (y + h - 0.5f) * psy);
    v4.textureCoordinate2 = Vec2Make((x + 0 + 0.5f) * psx, (y + h - 0.5f) * psy);
    
    [mesh setVertex:v1 at:[mesh face:i vertexAt:0]];
    [mesh setVertex:v2 at:[mesh face:i vertexAt:1]];
    [mesh setVertex:v3 at:[mesh face:i vertexAt:2]];
    [mesh setVertex:v4 at:[mesh face:i vertexAt:3]];
    
    *width = w;
    *height = h;
}

- (void)buffer {
    self.vertexBuffer = [self.view.device newBufferWithBytes:self.vertices.mutableBytes length:self.vertices.length options:MTLResourceStorageModeManaged];
    self.sampleBuffer = [self.view.device newBufferWithBytes:self.samples.mutableBytes length:self.samples.length options:MTLResourceStorageModeManaged];
}

- (void)render:(id<MTLAccelerationStructure>)accel lights:(NSData*)lights {
    static Uniforms uniforms;
    static Mat4 transform;
    
    id<MTLCommandBuffer> commandBuffer = [self.view.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:self.renderPassDescriptor];
    
    uniforms.sampleRadius = self.sampleRadius;
    uniforms.aoLength = self.aoLength;
    uniforms.aoStrength = self.aoStrength;
    uniforms.sampleCount = self.samples.length / sizeof(Vec3);
    uniforms.lightCount = MIN(MAX_LIGHTS, lights.length / sizeof(Light));
    
    memmove(uniforms.lights, lights.bytes, uniforms.lightCount * sizeof(Light));
    
    transform = Mat4Ortho(0, self.renderPassDescriptor.colorAttachments[0].texture.width, self.renderPassDescriptor.colorAttachments[0].texture.height, 0, -1, 1);
    
    [encoder setViewport:(MTLViewport){ 0, 0, self.renderPassDescriptor.colorAttachments[0].texture.width, self.renderPassDescriptor.colorAttachments[0].texture.height, 0, 1 }];
    [encoder setCullMode:MTLCullModeNone];
    [encoder setDepthStencilState:self.depthState];
    [encoder setRenderPipelineState:self.pipelineState];
    [encoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [encoder setVertexBytes:&transform length:sizeof(Mat4) atIndex:1];
    [encoder setFragmentAccelerationStructure:accel atBufferIndex:0];
    [encoder setFragmentBuffer:self.sampleBuffer offset:0 atIndex:1];
    [encoder setFragmentBytes:&uniforms length:sizeof(Uniforms) atIndex:2];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.vertices.length / sizeof(LMVertex)];
    [encoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
}

- (id<MTLAccelerationStructure>)createAccel:(NSMutableData *)vertices indices:(NSMutableData *)indices {
    MTLPrimitiveAccelerationStructureDescriptor* primitiveDescriptor = [[MTLPrimitiveAccelerationStructureDescriptor alloc] init];
    MTLAccelerationStructureTriangleGeometryDescriptor* geometryDescriptor = [[MTLAccelerationStructureTriangleGeometryDescriptor alloc] init];
    
    geometryDescriptor.triangleCount = indices.length / 4 / 3;
    geometryDescriptor.vertexStride = sizeof(Vec3);
    geometryDescriptor.vertexBufferOffset = 0;
    geometryDescriptor.indexType = MTLIndexTypeUInt32;
    geometryDescriptor.vertexBuffer = [self.view.device newBufferWithBytes:vertices.mutableBytes length:vertices.length options:MTLResourceStorageModeManaged];
    geometryDescriptor.indexBufferOffset = 0;
    geometryDescriptor.indexBuffer = [self.view.device newBufferWithBytes:indices.mutableBytes length:indices.length options:MTLResourceStorageModeManaged];
    geometryDescriptor.allowDuplicateIntersectionFunctionInvocation = YES;
    geometryDescriptor.opaque = YES;
    primitiveDescriptor.geometryDescriptors = @[ geometryDescriptor ];
    primitiveDescriptor.usage = MTLAccelerationStructureUsagePreferFastBuild;
    
    MTLAccelerationStructureSizes sizes = [self.view.device accelerationStructureSizesWithDescriptor:primitiveDescriptor];
    id<MTLAccelerationStructure> accel = [self.view.device newAccelerationStructureWithSize:sizes.accelerationStructureSize];
    id<MTLBuffer> scratchBuffer = [self.view.device newBufferWithLength:sizes.buildScratchBufferSize options:MTLResourceStorageModePrivate];
    
    id<MTLCommandBuffer> commandBuffer = [self.view.commandQueue commandBuffer];
    id<MTLAccelerationStructureCommandEncoder> encoder = [commandBuffer accelerationStructureCommandEncoder];
    
    [encoder buildAccelerationStructure:accel descriptor:primitiveDescriptor scratchBuffer:scratchBuffer scratchBufferOffset:0];
    [encoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    return accel;
}

- (id<MTLTexture>)texture {
    return self.renderPassDescriptor.colorAttachments[0].texture;
}

@end
