//
//  Mesh.h
//  X3D
//
//  Created by Douglas McNamara on 5/18/23.
//

@interface Mesh : Node

- (id)initWithView:(MTLView*)view;
- (int)vertexCount;
- (BasicVertex)vertexAt:(int)i;
- (void)setVertex:(BasicVertex)vertex at:(int)i;
- (int)indexCount;
- (int)indexAt:(int)i;
- (int)faceCount;
- (int)faceVertexCountAt:(int)i;
- (int)face:(int)i vertexAt:(int)j;
- (void)pushVertex:(BasicVertex)vertex;
- (void)pushFace:(NSArray<NSNumber*>*)indices swapWinding:(BOOL)swap;
- (void)pushAccelPositions:(NSMutableData*)positions indices:(NSMutableData*)indices;
- (void)pushBox:(Vec3)size position:(Vec3)position rotation:(Vec3)rotation invert:(BOOL)invert;
- (void)calcTextureCoordinates:(float)units;
- (void)bufferVertices;

@end
