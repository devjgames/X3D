//
//  Sprite.m
//  X3D
//
//  Created by Douglas McNamara on 8/9/23.
//

#import <X3D/X3D.h>

typedef struct SpriteVertex {
    Vec2 position;
    Vec2 textureCoordinate;
    Vec4 color;
} SpriteVertex;

@interface Sprite ()

@property (weak) MTLView* view;
@property id<MTLDepthStencilState> depthStencilState;
@property id<MTLRenderPipelineState> renderPipelineState;
@property id<MTLBuffer> vertexBuffer;
@property NSMutableData* vertices;

@end

@implementation Sprite

- (id)initWithView:(MTLView*)view texture:(id<MTLTexture>)texture {
    self = [super init];
    if(self) {
        self.view = view;
        
        _texture = texture;
        
        MTLDepthStencilDescriptor* depthStencilDescriptor = [[MTLDepthStencilDescriptor alloc] init];
        
        depthStencilDescriptor.depthWriteEnabled = NO;
        depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionAlways;
        
        self.depthStencilState = [view.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
        
        MTLRenderPipelineDescriptor* renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        
        renderPipelineDescriptor.vertexFunction = [view.library newFunctionWithName:@"spriteVertexShader"];
        renderPipelineDescriptor.fragmentFunction = [view.library newFunctionWithName:@"spriteFragmentShader"];
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        renderPipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
        renderPipelineDescriptor.colorAttachments[0].blendingEnabled = YES;
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
        
        NSError* error = nil;
        
        self.renderPipelineState = [view.device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error];
        
        if(error) {
            Log(@"%@", error.description);
        }
        
        self.vertexBuffer = [view.device newBufferWithLength:sizeof(SpriteVertex) * 6 options:MTLResourceStorageModeManaged];
        
        self.vertices = [NSMutableData dataWithCapacity:sizeof(SpriteVertex) * 60];
    }
    return self;
}

- (void)begin {
    self.vertices.length = 0;
}

- (void)pushSrc:(NSRect)src dst:(NSRect)dst color:(Vec4)color {
    float tw = self.texture.width;
    float th = self.texture.height;
    float sx1 = src.origin.x / tw;
    float sy1 = src.origin.y / th;
    float sx2 = (src.origin.x + src.size.width) / tw;
    float sy2 = (src.origin.y + src.size.height) / th;
    float dx1 = dst.origin.x;
    float dy1 = dst.origin.y;
    float dx2 = dst.origin.x + dst.size.width;
    float dy2 = dst.origin.y + dst.size.height;
    SpriteVertex v;
    
    v.position = Vec2Make(dx1, dy1);
    v.textureCoordinate = Vec2Make(sx1, sy1);
    v.color = color;
    
    [self.vertices appendBytes:&v length:sizeof(SpriteVertex)];
    
    v.position = Vec2Make(dx2, dy1);
    v.textureCoordinate = Vec2Make(sx2, sy1);
    v.color = color;
    
    [self.vertices appendBytes:&v length:sizeof(SpriteVertex)];
    
    v.position = Vec2Make(dx2, dy2);
    v.textureCoordinate = Vec2Make(sx2, sy2);
    v.color = color;
    
    [self.vertices appendBytes:&v length:sizeof(SpriteVertex)];
    
    v.position = Vec2Make(dx2, dy2);
    v.textureCoordinate = Vec2Make(sx2, sy2);
    v.color = color;
    
    [self.vertices appendBytes:&v length:sizeof(SpriteVertex)];
    
    v.position = Vec2Make(dx1, dy2);
    v.textureCoordinate = Vec2Make(sx1, sy2);
    v.color = color;
    
    [self.vertices appendBytes:&v length:sizeof(SpriteVertex)];
    
    v.position = Vec2Make(dx1, dy1);
    v.textureCoordinate = Vec2Make(sx1, sy1);
    v.color = color;
    
    [self.vertices appendBytes:&v length:sizeof(SpriteVertex)];
}

- (void)pustText:(NSString*)text cw:(int)cw ch:(int)ch columns:(int)cols scale:(int)scale lineSpacing:(int)spacing location:(NSPoint)location color:(Vec4)color {
    int sx = location.x;
    
    for(int i = 0; i != text.length; i++) {
        unichar c = [text characterAtIndex:i];
        
        if(c == '\n') {
            location.x = sx;
            location.y += ch * scale + spacing * scale;
        } else {
            int j = (int)c - (int)' ';
            
            if(j >= 0 && j < 100) {
                int x = j % cols;
                int y = j / cols;
                
                [self pushSrc:NSMakeRect(x * cw, y * ch, cw, ch) dst:NSMakeRect(location.x, location.y, cw * scale, ch * scale) color:color];
                
                location.x += cw * scale;
            }
        }
    }
}

- (void)end {
    if(self.vertices.length) {
        if(self.vertices.length > self.vertexBuffer.length) {
            
            Log(@"Resizing sprite vertex buffer ...");
            
            self.vertexBuffer = [self.view.device newBufferWithLength:self.vertexBuffer.length + 100 * 6 * sizeof(SpriteVertex) options:MTLResourceStorageModeManaged];
        }
        
        memmove(self.vertexBuffer.contents, self.vertices.mutableBytes, self.vertices.length);
        
        [self.vertexBuffer didModifyRange:NSMakeRange(0, self.vertices.length)];
        
        id<MTLCommandBuffer> commandBuffer = [self.view.commandQueue commandBuffer];
        id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];
        
        [encoder synchronizeResource:self.vertexBuffer];
        [encoder endEncoding];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
    }
}

- (void)encodeWithEncoder:(id<MTLRenderCommandEncoder>)encoder size:(NSSize)size {
    static Mat4 projection;
    
    
    projection = Mat4Ortho(0, size.width, size.height, 0, -1, 1);
    
    [encoder setCullMode:MTLCullModeNone];
    [encoder setDepthStencilState:self.depthStencilState];
    [encoder setRenderPipelineState:self.renderPipelineState];
    
    [encoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [encoder setVertexBytes:&projection length:sizeof(Mat4) atIndex:1];
    
    [encoder setFragmentTexture:self.texture atIndex:0];
    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.vertices.length / sizeof(SpriteVertex)];
}

@end
