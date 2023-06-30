//
//  Encodable.m
//  X3D
//
//  Created by Douglas McNamara on 5/15/23.
//

#import <X3D/X3D.h>

typedef struct VertexUniforms {
    Mat4 projection;
    Mat4 view;
    Mat4 model;
    Mat4 modelIT;
    Vec4 ambientColor;
    Vec4 diffuseColor;
    Vec4 color;
    UInt8 lightingEnabled;
    UInt8 vertexColorEnabled;
    UInt8 lightCount;
    Vec3 warpAmplitudes;
    float warpFrequency;
    float warpTime;
    float warpSpeed;
    UInt8 warpEnabled;
    Light lights[MAX_LIGHTS];
} VertexUniforms;

typedef struct FragmentUniforms {
    UInt8 textureEnabled;
    UInt8 textureSampler;
    UInt8 texture2Enabled;
    UInt8 texture2Sampler;
} FragmentUniforms;

BasicVertex Vertex(float x, float y, float z, float s, float t, float u, float v, float nx, float ny, float nz, float r, float g, float b, float a) {
    return (BasicVertex){ {x, y, z}, {s, t}, {u, v}, {nx, ny, nz}, {r, g, b, a} };
}

@interface BasicEncodable ()

@property (weak) MTLView* view;
@property NSMutableData* data;
@property id<MTLDepthStencilState> depthState;
@property id<MTLRenderPipelineState> pipelineState;
@property id<MTLBuffer> vertexBuffer;
@property int count;
@property NSMutableData* noLights;

@end

@implementation BasicEncodable

- (id)initWithView:(MTLView*)view vertexCount:(int)count {
    self = [super init];
    if(self) {
        self.ambientColor = Vec4Make(0, 0, 0, 1);
        self.diffuseColor = Vec4Make(1, 1, 1, 1);
        self.color = Vec4Make(1, 1, 1, 1);
        self.lightingEnabled = NO;
        self.vertexColorEnabled = NO;
        self.texture = nil;
        self.texture2 = nil;
        self.textureSampler = NEAREST_REPEAT;
        self.texture2Sampler = LINEAR_CLAMP_TO_EDGE;
        self.depthTestEnabled = YES;
        self.depthWriteEnabled = YES;
        self.blendEnabled = NO;
        self.additiveBlend = NO;
        self.cullEnabled = YES;
        self.cullBack = YES;
        self.view = view;
        self.data = [NSMutableData dataWithCapacity:count * sizeof(BasicVertex)];
        self.vertexBuffer = [self.view.device newBufferWithLength:count * sizeof(BasicVertex) options:MTLResourceStorageModeManaged];
        self.count = count;
        self.warpAmplitudes = Vec3Make(8, 8, 8);
        self.warpFrequency = 0.05f;
        self.warpSpeed = 1;
        self.warpEnabled = NO;
        self.noLights = [NSMutableData dataWithCapacity:sizeof(Light) * MAX_LIGHTS];
        
        [self createDepthAndPipelineState];
    }
    return self;
}

- (int)vertexCount {
    return (int)(self.data.length / sizeof(BasicVertex));
}

- (BasicVertex)vertexAt:(int)i {
    return ((BasicVertex*)self.data.mutableBytes)[i];
}

- (void)setVertex:(BasicVertex)vertex at:(int)i {
    ((BasicVertex*)self.data.mutableBytes)[i] = vertex;
}

- (void)pushVertex:(BasicVertex)vertex {
    [self.data appendBytes:&vertex length:sizeof(BasicVertex)];
}

- (void)pushSrcRect:(NSRect)src dstRect:(NSRect)dst color:(Vec4)color flip:(BOOL)flip {
    static float tw, th, sx1, sy1, sx2, sy2, dx1, dy1, dx2, dy2, temp;
    
    if(self.texture) {
        tw = self.texture.width;
        th = self.texture.height;
        sx1 = src.origin.x / tw;
        sy1 = src.origin.y / th;
        sx2 = (src.origin.x + src.size.width) / tw;
        sy2 = (src.origin.y + src.size.height) / th;
        dx1 = dst.origin.x;
        dy1 = dst.origin.y;
        dx2 = dx1 + dst.size.width;
        dy2 = dy1 + dst.size.height;
        
        if(flip) {
            temp = sy1;
            sy1 = sy2;
            sy2 = temp;
        }
        
        [self pushVertex:Vertex(dx1, dy1, 0, sx1, sy1, 0, 0, 0, 0, 0, color.x, color.y, color.z, color.w)];
        [self pushVertex:Vertex(dx2, dy1, 0, sx2, sy1, 0, 0, 0, 0, 0, color.x, color.y, color.z, color.w)];
        [self pushVertex:Vertex(dx2, dy2, 0, sx2, sy2, 0, 0, 0, 0, 0, color.x, color.y, color.z, color.w)];
        [self pushVertex:Vertex(dx2, dy2, 0, sx2, sy2, 0, 0, 0, 0, 0, color.x, color.y, color.z, color.w)];
        [self pushVertex:Vertex(dx1, dy2, 0, sx1, sy2, 0, 0, 0, 0, 0, color.x, color.y, color.z, color.w)];
        [self pushVertex:Vertex(dx1, dy1, 0, sx1, sy1, 0, 0, 0, 0, 0, color.x, color.y, color.z, color.w)];
    }
}

- (void)pushText:(NSString *)text xy:(NSPoint)xy size:(NSSize)size cols:(int)cols lineSpacing:(int)spacing color:(Vec4)color {
    static char* ptr, c;
    static int sx, i, row, col;
    
    sx = xy.x;
    ptr = (char*)[text cStringUsingEncoding:NSASCIIStringEncoding];
    while((c = *ptr++)) {
        if(c == '\n') {
            xy.x = sx;
            xy.y += size.height + spacing;
        } else {
            i = (int)c - (int)' ';
            if(i >= 0 && i < 100) {
                col = i % cols;
                row = i / cols;
                [self pushSrcRect:NSMakeRect(col * size.width, row * size.height, size.width, size.height)
                          dstRect:NSMakeRect(xy.x, xy.y, size.width, size.height)
                            color:color
                             flip:NO];
                xy.x += size.width;
            }
        }
    }
}

- (void)clear {
    self.data.length = 0;
}

- (void)bufferVertices {
    if(self.data.length) {
        int count = (int)(self.data.length / sizeof(BasicVertex));
        
        if(count > self.count) {
            Log(@"Increasing basic encodable vertex buffer capacity to %i ...", count);
        
            self.count = count;
            self.vertexBuffer = [self.view.device newBufferWithBytes:self.data.mutableBytes length:count * sizeof(BasicVertex) options:MTLResourceStorageModeManaged];
        } else {
            memmove(self.vertexBuffer.contents, self.data.mutableBytes, self.data.length);
            [self.vertexBuffer didModifyRange:NSMakeRange(0, self.data.length)];
            
            id<MTLCommandBuffer> commandBuffer = [self.view.commandQueue commandBuffer];
            id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];
            
            [encoder synchronizeResource:self.vertexBuffer];
            [encoder endEncoding];
            [commandBuffer commit];
            [commandBuffer waitUntilCompleted];
        }
    }
}

- (void)encodeWithEncoder:(id<MTLRenderCommandEncoder>)encoder projection:(Mat4)projection view:(Mat4)view model:(Mat4)model lights:(NSData*)lights {
    static VertexUniforms vertexUniforms;
    static FragmentUniforms fragmentUniforms;
    static int count;
    
    count = (int)(self.data.length / sizeof(BasicVertex));
    
    if(count) {
        if(lights == nil) {
            lights = self.noLights;
        }
        vertexUniforms.projection = projection;
        vertexUniforms.view = view;
        vertexUniforms.model = model;
        vertexUniforms.modelIT = Mat4Transpose(Mat4Invert(model));
        vertexUniforms.ambientColor = self.ambientColor;
        vertexUniforms.diffuseColor = self.diffuseColor;
        vertexUniforms.color = self.color;
        vertexUniforms.lightingEnabled = (self.lightingEnabled) ? 1 : 0;
        vertexUniforms.vertexColorEnabled = (self.vertexColorEnabled) ? 1 : 0;
        vertexUniforms.warpAmplitudes = self.warpAmplitudes;
        vertexUniforms.warpFrequency = self.warpFrequency;
        vertexUniforms.warpSpeed = self.warpSpeed;
        vertexUniforms.warpTime = self.view.totalTime;
        vertexUniforms.warpEnabled = self.warpEnabled;
        vertexUniforms.lightCount = MIN(MAX_LIGHTS, (int)(lights.length / sizeof(Light)));
        memmove(vertexUniforms.lights, lights.bytes, vertexUniforms.lightCount * sizeof(Light));
        
        fragmentUniforms.textureEnabled = self.texture != nil;
        fragmentUniforms.textureSampler = self.textureSampler;
        fragmentUniforms.texture2Enabled = self.texture2 != nil;
        fragmentUniforms.texture2Sampler = self.texture2Sampler;
        
        if(self.cullEnabled) {
            if(self.cullBack) {
                [encoder setCullMode:MTLCullModeBack];
            } else {
                [encoder setCullMode:MTLCullModeFront];
            }
        } else {
            [encoder setCullMode:MTLCullModeNone];
        }
        [encoder setDepthStencilState:self.depthState];
        [encoder setRenderPipelineState:self.pipelineState];
        [encoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
        [encoder setVertexBytes:&vertexUniforms length:sizeof(VertexUniforms) atIndex:1];
        [encoder setFragmentBytes:&fragmentUniforms length:sizeof(FragmentUniforms) atIndex:0];
        if(self.texture) {
            [encoder setFragmentTexture:self.texture atIndex:0];
        }
        if(self.texture2) {
            [encoder setFragmentTexture:self.texture2 atIndex:1];
        }
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:count];
    }
}

- (void)createDepthAndPipelineState {
    Log(@"Creating basic encodable depth and pipeline state ...");
    
    MTLDepthStencilDescriptor* depthDescriptor = [[MTLDepthStencilDescriptor alloc] init];
    
    depthDescriptor.depthWriteEnabled = self.depthWriteEnabled;
    depthDescriptor.depthCompareFunction = (self.depthTestEnabled) ? MTLCompareFunctionLess : MTLCompareFunctionAlways;
    
    self.depthState = [self.view.device newDepthStencilStateWithDescriptor:depthDescriptor];
    
    MTLRenderPipelineDescriptor* pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    pipelineDescriptor.vertexFunction = [self.view.library newFunctionWithName:@"vertexShader"];
    pipelineDescriptor.fragmentFunction = [self.view.library newFunctionWithName:@"fragmentShader"];
    pipelineDescriptor.colorAttachments[0].pixelFormat = self.view.metalLayer.pixelFormat;
    pipelineDescriptor.colorAttachments[0].blendingEnabled = self.blendEnabled;
    if(self.blendEnabled) {
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
        if(self.additiveBlend) {
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorOne;
            pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorOne;
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOne;
            pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOne;
        } else {
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
            pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
            pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        }
    }
    pipelineDescriptor.depthAttachmentPixelFormat = self.view.renderPassDescriptor.depthAttachment.texture.pixelFormat;
    
    NSError* error = nil;
    
    self.pipelineState = [self.view.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    
    if(error) {
        Log(@"%@", error.description);
    }
}

@end
