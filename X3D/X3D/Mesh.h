//
//  Mesh.h
//  X3D
//
//  Created by Douglas McNamara on 8/10/23.
//

#define MAX_LIGHTS 16

#define AMBIENT_LIGHT 0
#define DIRECTIONAL_LIGHT 1
#define POINT_LIGHT 2

typedef struct Vertex {
    Vec3 position;
    Vec2 textureCoordinate;
    Vec3 normal;
} Vertex;

typedef struct LightData {
    UInt8 type;
    Vec3 vector;
    Vec4 color;
    float range;
} LightData;

typedef struct VertexData {
    Mat4 projection;
    Mat4 view;
    Mat4 model;
    Mat4 modelIT;
    Vec4 color;
    UInt8 lightCount;
    LightData lights[MAX_LIGHTS];
} VertexData;

typedef struct FragmentData {
    UInt8 textureEnabled;
    UInt8 linear;
} FragmentData;

@interface Mesh : Node

@property Vec4 color;
@property id<MTLTexture> texture;
@property BOOL textureLinear;
@property BOOL depthWriteEnabled;
@property BOOL depthTestEnabled;
@property BOOL blendEnabled;
@property BOOL additiveBlend;
@property BOOL cullEnabled;
@property BOOL cullBack;

- (id)initWithView:(MTLView*)view;
- (int)vertexCount;
- (Vertex)vertexAt:(int)i;
- (void)setVertex:(Vertex)v at:(int)i;
- (int)indexCount;
- (int)indexAt:(int)i;
- (void)clearVertices;
- (void)pushVertex:(Vertex)v;
- (void)calcNormals;
- (void)clearFaces;
- (void)pushFace:(NSArray<NSNumber*>*)indices;
- (void)bufferVertices;
- (void)bufferIndices;
- (void)createDepthStencilState;
- (void)createRenderPipelineState;

@end

@interface NodeLoader : AssetLoader

@end

