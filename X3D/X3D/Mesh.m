//
//  Mesh.m
//  X3D
//
//  Created by Douglas McNamara on 5/18/23.
//

#import <X3D/X3D.h>

@interface Mesh ()

@property (weak) MTLView* view;
@property NSMutableData* vertices;
@property NSMutableData* indices;
@property NSMutableArray<NSArray<NSNumber*>*>* faces;

@end

@implementation Mesh

- (id)initWithView:(MTLView *)view {
    self = [super init];
    if(self) {
        self.view = view;
        self.vertices = [NSMutableData dataWithCapacity:sizeof(BasicVertex)];
        self.indices = [NSMutableData dataWithCapacity:4];
        self.faces = [NSMutableArray arrayWithCapacity:1];
        self.encodable = [[BasicEncodable alloc] initWithView:view vertexCount:1];
    }
    return self;
}

- (int)vertexCount {
    return (int)(self.vertices.length / sizeof(BasicVertex));
}

- (BasicVertex)vertexAt:(int)i {
    return ((BasicVertex*)self.vertices.mutableBytes)[i];
}

- (void)setVertex:(BasicVertex)vertex at:(int)i {
    ((BasicVertex*)self.vertices.mutableBytes)[i] = vertex;
}

- (int)indexCount {
    return (int)(self.indices.length / 4);
}

- (int)indexAt:(int)i {
    return ((int*)self.indices.mutableBytes)[i];
}

- (int)faceCount {
    return (int)self.faces.count;
}

- (int)faceVertexCountAt:(int)i {
    return (int)[[self.faces objectAtIndex:i] count];
}

- (int)face:(int)i vertexAt:(int)j {
    return (int)[[[self.faces objectAtIndex:i] objectAtIndex:j] intValue];
}

- (void)pushVertex:(BasicVertex)vertex {
    [self.vertices appendBytes:&vertex length:sizeof(BasicVertex)];
}

- (void)pushFace:(NSArray<NSNumber*>*)indices swapWinding:(BOOL)swap {
    int tris = (int)indices.count - 2;
    
    if(swap) {
        NSMutableArray* temp = [NSMutableArray arrayWithCapacity:indices.count];
        
        for(int i = (int)indices.count - 1; i != -1; i--) {
            [temp addObject:indices[i]];
        }
        indices = temp;
    }
    
    for(int i = 0; i != tris; i++) {
        int i1 = [[indices objectAtIndex:0] intValue];
        int i2 = [[indices objectAtIndex:i + 1] intValue];
        int i3 = [[indices objectAtIndex:i + 2] intValue];
        
        [self.indices appendBytes:&i1 length:4];
        [self.indices appendBytes:&i2 length:4];
        [self.indices appendBytes:&i3 length:4];
    }
    [self.faces addObject:[NSArray arrayWithArray:indices]];
}

- (void)pushAccelPositions:(NSMutableData *)positions indices:(NSMutableData *)indices {
    int count = (int)(positions.length / sizeof(Vec3));
    
    for(int i = 0; i != self.vertexCount; i++) {
        BasicVertex v = [self vertexAt:i];
        
        v.position = Vec3Transform(self.model, v.position);
        
        [positions appendBytes:&(v.position) length:sizeof(Vec3)];
    }

    for(int i = 0; i != self.indexCount; i++) {
        int j = [self indexAt:i] + count;
        
        [indices appendBytes:&j length:4];
    }
}

- (void)pushBox:(Vec3)size position:(Vec3)position rotation:(Vec3)rotation invert:(BOOL)invert {
    Vec3 s = size / 2;
    float d = (invert) ? -1 : 1;

    [self pushVertex:Vertex(-s.x, -s.y, -s.z, 1, 1, 0, 0, 0, 0, -1 * d, 1, 1, 1, 1)];
    [self pushVertex:Vertex(+s.x, -s.y, -s.z, 0, 1, 0, 0, 0, 0, -1 * d, 1, 1, 1, 1)];
    [self pushVertex:Vertex(+s.x, +s.y, -s.z, 0, 0, 0, 0, 0, 0, -1 * d, 1, 1, 1, 1)];
    [self pushVertex:Vertex(-s.x, +s.y, -s.z, 1, 0, 0, 0, 0, 0, -1 * d, 1, 1, 1, 1)];
    [self pushFace:@[ @(0), @(1), @(2), @(3) ] swapWinding:invert];
    
    [self pushVertex:Vertex(-s.x, -s.y, +s.z, 0, 1, 0, 0, 0, 0, +1 * d, 1, 1, 1, 1)];
    [self pushVertex:Vertex(+s.x, -s.y, +s.z, 1, 1, 0, 0, 0, 0, +1 * d, 1, 1, 1, 1)];
    [self pushVertex:Vertex(+s.x, +s.y, +s.z, 1, 0, 0, 0, 0, 0, +1 * d, 1, 1, 1, 1)];
    [self pushVertex:Vertex(-s.x, +s.y, +s.z, 0, 0, 0, 0, 0, 0, +1 * d, 1, 1, 1, 1)];
    [self pushFace:@[ @(7), @(6), @(5), @(4) ] swapWinding:invert];
    
    [self pushVertex:Vertex(-s.x, -s.y, -s.z, 0, 1, 0, 0, -1 * d, 0, 0, 1, 1, 1, 1)];
    [self pushVertex:Vertex(-s.x, +s.y, -s.z, 0, 0, 0, 0, -1 * d, 0, 0, 1, 1, 1, 1)];
    [self pushVertex:Vertex(-s.x, +s.y, +s.z, 1, 0, 0, 0, -1 * d, 0, 0, 1, 1, 1, 1)];
    [self pushVertex:Vertex(-s.x, -s.y, +s.z, 1, 1, 0, 0, -1 * d, 0, 0, 1, 1, 1, 1)];
    [self pushFace:@[ @(8), @(9), @(10), @(11) ] swapWinding:invert];
    
    [self pushVertex:Vertex(+s.x, -s.y, -s.z, 1, 1, 0, 0, +1 * d, 0, 0, 1, 1, 1, 1)];
    [self pushVertex:Vertex(+s.x, +s.y, -s.z, 1, 0, 0, 0, +1 * d, 0, 0, 1, 1, 1, 1)];
    [self pushVertex:Vertex(+s.x, +s.y, +s.z, 0, 0, 0, 0, +1 * d, 0, 0, 1, 1, 1, 1)];
    [self pushVertex:Vertex(+s.x, -s.y, +s.z, 0, 1, 0, 0, +1 * d, 0, 0, 1, 1, 1, 1)];
    [self pushFace:@[ @(15), @(14), @(13), @(12) ] swapWinding:invert];
    
    [self pushVertex:Vertex(-s.x, -s.y, -s.z, 0, 1, 0, 0, 0, -1 * d, 0, 1, 1, 1, 1)];
    [self pushVertex:Vertex(-s.x, -s.y, +s.z, 0, 0, 0, 0, 0, -1 * d, 0, 1, 1, 1, 1)];
    [self pushVertex:Vertex(+s.x, -s.y, +s.z, 1, 0, 0, 0, 0, -1 * d, 0, 1, 1, 1, 1)];
    [self pushVertex:Vertex(+s.x, -s.y, -s.z, 1, 1, 0, 0, 0, -1 * d, 0, 1, 1, 1, 1)];
    [self pushFace:@[ @(16), @(17), @(18), @(19) ] swapWinding:invert];
    
    [self pushVertex:Vertex(-s.x, +s.y, -s.z, 0, 0, 0, 0, 0, +1 * d, 0, 1, 1, 1, 1)];
    [self pushVertex:Vertex(-s.x, +s.y, +s.z, 0, 1, 0, 0, 0, +1 * d, 0, 1, 1, 1, 1)];
    [self pushVertex:Vertex(+s.x, +s.y, +s.z, 1, 1, 0, 0, 0, +1 * d, 0, 1, 1, 1, 1)];
    [self pushVertex:Vertex(+s.x, +s.y, -s.z, 1, 0, 0, 0, 0, +1 * d, 0, 1, 1, 1, 1)];
    [self pushFace:@[ @(23), @(22), @(21), @(20) ] swapWinding:invert];
    
    Mat4 m = Mat4Mul(Mat4Rotate(rotation.x, Vec3Make(1, 0, 0)),
                     Mat4Mul(Mat4Rotate(rotation.y, Vec3Make(0, 1, 0)),
                             Mat4Rotate(rotation.z, Vec3Make(0, 0, 1))
                             )
                     );
    
    m = Mat4Mul(Mat4Translate(position), m);
    
    Mat4 it = Mat4Transpose(Mat4Invert(m));
    
    for(int i = 0; i != self.vertexCount; i++) {
        BasicVertex v = [self vertexAt:i];
        
        v.position = Vec3Transform(m, v.position);
        v.normal = Vec3Normalize(Vec3TransformNormal(it, v.normal));
        
        [self setVertex:v at:i];
    }
}

- (void)calcTextureCoordinates:(float)units {
    for(int i = 0; i != self.vertexCount; i++) {
        BasicVertex v = [self vertexAt:i];
        float x = fabsf(v.normal.x);
        float y = fabsf(v.normal.y);
        float z = fabsf(v.normal.z);
        
        if(x >= y && x >= z) {
            v.textureCoordinate = Vec2Make(v.position.z, v.position.y) / units;
        } else if(y >= x && y >= z) {
            v.textureCoordinate = Vec2Make(v.position.x, v.position.z) / units;
        } else {
            v.textureCoordinate = Vec2Make(v.position.x, v.position.y) / units;
        }
        [self setVertex:v at:i];
    }
}

- (void)bufferVertices {
    [self.basicEncodable clear];
    for(int i = 0; i != self.indexCount; i++) {
        [self.basicEncodable pushVertex:[self vertexAt:[self indexAt:i]]];
    }
    [self.basicEncodable bufferVertices];
}

@end
