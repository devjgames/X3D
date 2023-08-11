//
//  Mesh.m
//  X3D
//
//  Created by Douglas McNamara on 8/10/23.
//

#import <X3D/X3D.h>

@interface Mesh ()

@property MTLView* view;
@property id<MTLBuffer> vertexBuffer;
@property id<MTLBuffer> indexBuffer;
@property id<MTLDepthStencilState> depthStencilState;
@property id<MTLRenderPipelineState> renderPipelineState;
@property NSMutableData* vertices;
@property NSMutableData* indices;

- (id<MTLBuffer>)buffer:(id<MTLBuffer>)buffer data:(NSMutableData*)data;

@end

@implementation Mesh

- (id)initWithView:(MTLView*)view {
    self = [super init];
    if(self) {
        self.color = Vec4Make(1, 1, 1, 1);
        self.texture = nil;
        self.textureLinear = NO;
        self.depthWriteEnabled = YES;
        self.depthTestEnabled = YES;
        self.blendEnabled = NO;
        self.additiveBlend = NO;
        self.cullEnabled = YES;
        self.cullBack = YES;
        
        self.view = view;
        self.vertexBuffer = nil;
        self.indexBuffer = nil;
        
        [self createDepthStencilState];
        [self createRenderPipelineState];
        
        self.vertices = [NSMutableData dataWithCapacity:90 * sizeof(Vertex)];
        self.indices = [NSMutableData dataWithCapacity:90 * 4];
    }
    return self;
}

- (int)vertexCount {
    return (int)(self.vertices.length / sizeof(Vertex));
}

- (Vertex)vertexAt:(int)i {
    return ((Vertex*)self.vertices.mutableBytes)[i];
}

- (void)setVertex:(Vertex)v at:(int)i {
    ((Vertex*)self.vertices.mutableBytes)[i] = v;
}

- (int)indexCount {
    return (int)(self.indices.length / 4);
}

- (int)indexAt:(int)i {
    return ((int*)self.indices.mutableBytes)[i];
}

- (void)clearVertices {
    self.vertices.length = 0;
}

- (void)pushVertex:(Vertex)v {
    [self.vertices appendBytes:&v length:sizeof(Vertex)];
}

- (void)calcNormals {
    for(int i = 0; i != self.vertexCount; i++) {
        Vertex v = [self vertexAt:i];
        
        v.normal = Vec3Make(0, 0, 0);
        
        [self setVertex:v at:i];
    }
    
    for(int i = 0; i != self.indexCount; ) {
        Vertex v1 = [self vertexAt:[self indexAt:i + 0]];
        Vertex v2 = [self vertexAt:[self indexAt:i + 1]];
        Vertex v3 = [self vertexAt:[self indexAt:i + 2]];
        Vec3 normal = Vec3Normalize(Vec3Cross(v3.position - v2.position, v2.position - v1.position));
        
        v1.normal += normal;
        v2.normal += normal;
        v3.normal += normal;
        
        [self setVertex:v1 at:[self indexAt:i++]];
        [self setVertex:v2 at:[self indexAt:i++]];
        [self setVertex:v3 at:[self indexAt:i++]];
    }
    
    for(int i = 0; i != self.vertexCount; i++) {
        Vertex v = [self vertexAt:i];
        
        v.normal = Vec3Normalize(v.normal);
        
        [self setVertex:v at:i];
    }
}

- (void)clearFaces {
    self.indices.length = 0;
}

- (void)pushFace:(NSArray<NSNumber*>*)indices {
    int tris = (int)indices.count - 2;
    
    for(int i = 0; i != tris; i++) {
        int i1 = indices[0].intValue;
        int i2 = indices[i + 1].intValue;
        int i3 = indices[i + 2].intValue;
        
        [self.indices appendBytes:&i1 length:4];
        [self.indices appendBytes:&i2 length:4];
        [self.indices appendBytes:&i3 length:4];
    }
}

- (id<MTLBuffer>)buffer:(id<MTLBuffer>)buffer data:(NSMutableData*)data {
    if(data.length) {
        if(buffer) {
            if(data.length <= buffer.length) {
                memmove(buffer.contents, data.mutableBytes, data.length);
                [buffer didModifyRange:NSMakeRange(0, data.length)];
                
                id<MTLCommandBuffer> commandBuffer = [self.view.commandQueue commandBuffer];
                id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];
                
                [encoder synchronizeResource:buffer];
                [encoder endEncoding];
                [commandBuffer commit];
                [commandBuffer waitUntilCompleted];
                
                return buffer;
            }
        }
        Log(@"Creating mesh buffer ...");
        
        buffer = [self.view.device newBufferWithBytes:data.mutableBytes length:data.length options:MTLResourceStorageModeManaged];
    }
    return buffer;
}

- (void)bufferVertices {
    self.vertexBuffer = [self buffer:self.vertexBuffer data:self.vertices];
}

- (void)bufferIndices {
    self.indexBuffer = [self buffer:self.indexBuffer data:self.indices];
}

- (void)createDepthStencilState {
    
    Log(@"Creating mesh depth stencil state ...");
    
    MTLDepthStencilDescriptor* descriptor = [[MTLDepthStencilDescriptor alloc] init];
    
    descriptor.depthWriteEnabled = self.depthWriteEnabled;
    descriptor.depthCompareFunction = (self.depthTestEnabled) ? MTLCompareFunctionLess : MTLCompareFunctionAlways;
    
    self.depthStencilState = [self.view.device newDepthStencilStateWithDescriptor:descriptor];
}

- (void)createRenderPipelineState {
    Log(@"Creating mesh render pipeline state ...");
    
    MTLRenderPipelineDescriptor* descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    descriptor.vertexFunction = [self.view.library newFunctionWithName:@"lightVertexShader"];
    descriptor.fragmentFunction = [self.view.library newFunctionWithName:@"lightFragmentShader"];
    descriptor.depthAttachmentPixelFormat = self.view.depthStencilPixelFormat;
    descriptor.colorAttachments[0].pixelFormat = self.view.colorPixelFormat;
    descriptor.colorAttachments[0].blendingEnabled = self.blendEnabled;
    if(self.blendEnabled) {
        descriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
        descriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
        if(self.additiveBlend) {
            descriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorOne;
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorOne;
            descriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOne;
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOne;
        } else {
            descriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
            descriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        }
    }
    
    NSError* error = nil;
    
    self.renderPipelineState = [self.view.device newRenderPipelineStateWithDescriptor:descriptor error:&error];
    
    if(error) {
        Log(@"%@", error.description);
    }
}

- (BOOL)isEncodable {
    return YES;
}

- (void)encodeWithEncoder:(id<MTLRenderCommandEncoder>)encoder camera:(Camera *)camera lights:(NSArray<Light *> *)lights {
    static VertexData vertexData;
    static FragmentData fragmentData;
    
    if(self.indexCount == 0 || self.vertexCount == 0 || self.vertexBuffer == nil || self.indexBuffer == nil) {
        return;
    }
    
    vertexData.projection = camera.projection;
    vertexData.view = camera.model;
    vertexData.model = self.model;
    vertexData.modelIT = Mat4Transpose(Mat4Invert(self.model));
    vertexData.color = self.color;
    vertexData.lightCount = (UInt8)MIN(MAX_LIGHTS, lights.count);
    
    for(int i = 0; i != vertexData.lightCount; i++) {
        Light* light = lights[i];
        
        vertexData.lights[i].color = light.color;
        
        if([light isKindOfClass:AmbientLight.class]) {
            vertexData.lights[i].type = AMBIENT_LIGHT;
            
        } else if([light isKindOfClass:DirectionalLight.class]) {
            vertexData.lights[i].type = DIRECTIONAL_LIGHT;
            vertexData.lights[i].vector = ((DirectionalLight*)light).lightDirection;
            
        } else {
            vertexData.lights[i].type = POINT_LIGHT;
            vertexData.lights[i].vector = light.absolutePosition;
            vertexData.lights[i].range = ((PointLight*)light).range;
        }
    }
    
    fragmentData.textureEnabled = (UInt8)((self.texture) ? 1 : 0);
    fragmentData.linear = (UInt8)((self.textureLinear) ? 1 : 0);
    
    if(self.cullEnabled) {
        if(self.cullBack) {
            [encoder setCullMode:MTLCullModeBack];
        } else {
            [encoder setCullMode:MTLCullModeFront];
        }
    } else {
        [encoder setCullMode:MTLCullModeNone];
    }
    [encoder setDepthStencilState:self.depthStencilState];
    [encoder setRenderPipelineState:self.renderPipelineState];
    [encoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [encoder setVertexBytes:&vertexData length:sizeof(VertexData) atIndex:1];
    
    if(self.texture) {
        [encoder setFragmentTexture:self.texture atIndex:0];
    }
    
    [encoder setFragmentBytes:&fragmentData length:sizeof(FragmentData) atIndex:0];
    
    [encoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                        indexCount:self.indexCount
                         indexType:MTLIndexTypeUInt32
                       indexBuffer:self.indexBuffer
                 indexBufferOffset:0
    ];
}

@end


@implementation NodeLoader

- (id)load:(NSURL *)url assets:(AssetManager *)assets {
    NSURL* baseURL = [NSURL fileURLWithPath:[url URLByDeletingLastPathComponent].path];
    NSString* basePath = [baseURL.path stringByReplacingOccurrencesOfString:assets.baseURL.path withString:@""];
    
    if([basePath characterAtIndex:basePath.length - 1] == '/') {
        basePath = [basePath substringToIndex:basePath.length - 1];
    }
    Log(@"NodeLoader base path = '%@'", basePath);
    
    NSArray* lines = [Parser split:[NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:nil] delims:[NSCharacterSet newlineCharacterSet]];
    Node* root = [[Node alloc] init];
    NSMutableDictionary<NSString*, Mesh*>* meshes = [NSMutableDictionary dictionaryWithCapacity:32];
    NSMutableDictionary<NSString*, id<MTLTexture>>* textures = [NSMutableDictionary dictionaryWithCapacity:8];
    Mesh* mesh = nil;
    NSMutableData* vList = [NSMutableData dataWithCapacity:100 * sizeof(Vec3)];
    NSMutableData* tList = [NSMutableData dataWithCapacity:100 * sizeof(Vec2)];
    NSMutableData* nList = [NSMutableData dataWithCapacity:100 * sizeof(Vec3)];
    
    for(NSString* line in lines) {
        NSString* tLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray<NSString*>* tokens = [Parser split:tLine delims:[NSCharacterSet whitespaceCharacterSet]];
        
        if([tLine hasPrefix:@"mtllib "]) {
            NSString* name = [[tLine substringFromIndex:6] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSURL* mtlURL = [baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@", name]];
            NSArray* mLines = [Parser split:[NSString stringWithContentsOfURL:mtlURL encoding:NSASCIIStringEncoding error:nil] delims:[NSCharacterSet newlineCharacterSet]];
            
            name = nil;
            for(NSString* mLine in mLines) {
                NSString* tMLine = [mLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
                if([tMLine hasPrefix:@"newmtl "]) {
                    name = [[tMLine substringFromIndex:6] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                } else if([tMLine hasPrefix:@"map_Kd "]) {
                    NSString* tex = [[tMLine substringFromIndex:6] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    
                    [textures setObject:[assets load:[NSString stringWithFormat:@"%@/%@", basePath, tex]] forKey:name];
                }
            }
        } else if([tLine hasPrefix:@"usemtl "]) {
            NSString* name = [[tLine substringFromIndex:6] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString* key = @"";
            id<MTLTexture> texture = [textures objectForKey:name];
            
            if(texture) {
                key = [texture.label.lastPathComponent stringByDeletingPathExtension];
            }
            
            mesh = [meshes objectForKey:key];
            
            if(mesh == nil) {
                mesh = [[Mesh alloc] initWithView:assets.view];
                mesh.texture = texture;
                
                [root addChild:mesh];
                [meshes setObject:mesh forKey:key];
            }
        } else if([tLine hasPrefix:@"v "]) {
            Vec3 v = { tokens[1].floatValue, tokens[2].floatValue, tokens[3].floatValue };
            
            [vList appendBytes:&v length:sizeof(Vec3)];
        } else if([tLine hasPrefix:@"vt "]) {
            Vec2 v = { tokens[1].floatValue, 1 - tokens[2].floatValue};
            
            [tList appendBytes:&v length:sizeof(Vec2)];
        } else if([tLine hasPrefix:@"vn "]) {
            Vec3 v = { tokens[1].floatValue, tokens[2].floatValue, tokens[3].floatValue };
            
            [nList appendBytes:&v length:sizeof(Vec3)];
        } else if([tLine hasPrefix:@"f "]) {
            if(mesh == nil) {
                mesh = [[Mesh alloc] initWithView:assets.view];
                
                [root addChild:mesh];
                [meshes setObject:mesh forKey:@""];
            }
            
            int baseVertex = mesh.vertexCount;
            NSMutableArray<NSNumber*>* indices = [NSMutableArray arrayWithCapacity:tokens.count - 1];
            
            for(int i = 1; i != (int)tokens.count; i++) {
                NSArray<NSString*>* iTokens = [Parser split:tokens[i] delims:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
                Vertex v;
                
                v.position = ((Vec3*)vList.mutableBytes)[iTokens[0].intValue - 1];
                v.textureCoordinate = ((Vec2*)tList.mutableBytes)[iTokens[1].intValue - 1];
                v.normal = ((Vec3*)nList.mutableBytes)[iTokens[2].intValue - 1];
                
                [mesh pushVertex:v];
                
                [indices insertObject:@(baseVertex + i - 1) atIndex:0];
            }
            [mesh pushFace:indices];
        }
    }
    for(int i = 0; i != root.childCount; i++) {
        Mesh* mesh = [root childAt:i];
        
        [mesh bufferIndices];
        [mesh bufferVertices];
    }
    return root;
}

@end
