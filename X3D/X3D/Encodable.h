//
//  Encodable.h
//  X3D
//
//  Created by Douglas McNamara on 5/15/23.
//

#define MAX_LIGHTS 16

#define LINEAR_CLAMP_TO_EDGE 1
#define LINEAR_REPEAT 2
#define NEAREST_CLAMP_TO_EDGE 3
#define NEAREST_REPEAT 4

typedef struct Light {
    Vec3 position;
    Vec4 color;
    float radius;
} Light;

typedef struct BasicVertex {
    Vec3 position;
    Vec2 textureCoordinate;
    Vec2 textureCoordinate2;
    Vec3 normal;
    Vec4 color;
} BasicVertex;

BasicVertex Vertex(float x, float y, float z, float s, float t, float u, float v, float nx, float ny, float nz, float r, float g, float b, float a);

@protocol Encodable <NSObject>

- (void)encodeWithEncoder:(id<MTLRenderCommandEncoder>)encoder projection:(Mat4)projection view:(Mat4)view model:(Mat4)model lights:(NSData*)lights;

@end

@interface BasicEncodable : XObject <Encodable>

@property Vec4 ambientColor;
@property Vec4 diffuseColor;
@property Vec4 color;
@property BOOL lightingEnabled;
@property BOOL vertexColorEnabled;
@property id<MTLTexture> texture;
@property id<MTLTexture> texture2;
@property int textureSampler;
@property int texture2Sampler;
@property BOOL depthTestEnabled;
@property BOOL depthWriteEnabled;
@property BOOL blendEnabled;
@property BOOL additiveBlend;
@property BOOL cullEnabled;
@property BOOL cullBack;
@property BOOL warpEnabled;
@property Vec3 warpAmplitudes;
@property float warpFrequency;
@property float warpSpeed;

- (id)initWithView:(MTLView*)view vertexCount:(int)count;
- (int)vertexCount;
- (BasicVertex)vertexAt:(int)i;
- (void)setVertex:(BasicVertex)vertex at:(int)i;
- (void)pushVertex:(BasicVertex)vertex;
- (void)pushSrcRect:(NSRect)src dstRect:(NSRect)dst color:(Vec4)color flip:(BOOL)flip;
- (void)pushText:(NSString*)text scale:(int)scale xy:(NSPoint)xy size:(NSSize)size cols:(int)cols lineSpacing:(int)spacing color:(Vec4)color;
- (void)clear;
- (void)bufferVertices;
- (void)createDepthAndPipelineState;

@end

