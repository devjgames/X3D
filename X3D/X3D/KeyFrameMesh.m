//
//  KeyFrameMesh.m
//  X3D
//
//  Created by Douglas McNamara on 5/17/23.
//

#import <X3D/X3D.h>

@interface KeyFrame ()

@property (readonly) NSMutableData* data;

@end

@implementation KeyFrame

- (id)init {
    self = [super init];
    if(self) {
        _data = [NSMutableData dataWithCapacity:sizeof(KeyFrameVertex)];
        _bounds = BoundingBoxEmpty();
    }
    return self;
}

- (int)vertexCount {
    return (int)(self.data.length / sizeof(KeyFrameVertex));
}

- (KeyFrameVertex)vertexAt:(int)i {
    return ((KeyFrameVertex*)self.data.mutableBytes)[i];
}

- (void)pushVertex:(KeyFrameVertex)vertex {
    _bounds = BoundingBoxAddPoint(_bounds, vertex.position);
    
    [self.data appendBytes:&vertex length:sizeof(KeyFrameVertex)];
}

@end

@interface KeyFrameMesh ()

@property (readonly, weak) MTLView* view;
@property (readonly) NSArray<KeyFrame*>* frames;
@property (readonly) int frame;
@property (readonly) float amount;

@end

@implementation KeyFrameMesh

- (id)initWithView:(MTLView *)view frames:(NSArray<KeyFrame *> *)frames {
    self = [super init];
    if(self) {
        _view = view;
        _frames = frames;
        _frame = 0;
        _amount = 0;
        _start = 0;
        _end = 0;
        _speed = 0;
        _looping = NO;
        _done = YES;
        
        self.encodable = [[BasicEncodable alloc] initWithView:view vertexCount:1];
        
        [self reset];
    }
    return self;
}

- (id)initWithKeyFrameMesh:(KeyFrameMesh *)mesh {
    self = [self initWithView:mesh.view frames:mesh.frames];
    if(self) {
    }
    return self;
}

- (int)frameCount {
    return (int)_frames.count;
}

- (BoundingBox)frameBoundsAt:(int)i {
    return _frames[i].bounds;
}

- (void)setSequenceStart:(int)start end:(int)end speed:(int)speed looping:(BOOL)looping {
    if(start != _start || end != _end || speed != _speed || looping != _looping) {
        int n = self.frameCount;
        
        if(start >= 0 && start < n && end >= 0 && end < n && start <= end && speed >= 0) {
            _start = start;
            _end = end;
            _speed = speed;
            _looping = looping;
            
            [self reset];
        }
    }
}

- (void)reset {
    _frame = _start;
    _amount = 0;
    _done = _start == _end;
    _bounds = self.frames[_frame].bounds;
    
    [self bufferVertices];
}

- (void)onUpdateWithScene:(Scene *)scene view:(MTLView *)view {
    if(!_done) {
        _amount += _speed * view.elapsedTime;
        if(_amount >= 1) {
            if(_looping) {
                if(_frame == _end) {
                    _frame = _start;
                } else {
                    _frame++;
                }
                _amount = 0;
            } else if(_frame == _end - 1) {
                _amount = 1;
                _done = YES;
            } else {
                _amount = 0;
                _frame++;
            }
        }
        KeyFrame* f1 = _frames[_frame];
        KeyFrame* f2 = nil;
        
        if(_frame == _end) {
            f2 = _frames[_start];
        } else {
            f2 = _frames[_frame + 1];
        }
        _bounds.min = simd_lerp(f1.bounds.min, f2.bounds.min, _amount);
        _bounds.max = simd_lerp(f1.bounds.max, f2.bounds.max, _amount);
        
        [self bufferVertices];
    }
}

- (void)bufferVertices {
    
    KeyFrame* f1 = _frames[_frame];
    KeyFrame* f2 = nil;
    
    if(_frame == _end) {
        f2 = _frames[_start];
    } else {
        f2 = _frames[_frame + 1];
    }
    _bounds.min = simd_lerp(f1.bounds.min, f2.bounds.min, _amount);
    _bounds.max = simd_lerp(f1.bounds.max, f2.bounds.max, _amount);
    
    BasicEncodable* encodable = self.basicEncodable;
    
    [encodable clear];
    for(int i = 0; i != f1.vertexCount; i++) {
        KeyFrameVertex v1 = [f1 vertexAt:i];
        KeyFrameVertex v2 = [f2 vertexAt:i];
        KeyFrameVertex v3 = v1;
        
        v3.position = simd_lerp(v1.position, v2.position, _amount);
        v3.normal = simd_lerp(v1.normal, v2.normal, _amount);
        
        [encodable pushVertex:Vertex(v3.position.x, v3.position.y, v3.position.z,
                                     v3.textureCoordinate.x, v3.textureCoordinate.y,
                                     0, 0,
                                     v3.normal.x, v3.normal.y, v3.normal.z,
                                     1, 1, 1, 1
                                     )];
    }
    [encodable bufferVertices];
}

+ (NSArray<NSArray<id>*>*)sequences {
    return @[
        @[ @"STAND", @(0), @(39), @(9), @(YES) ],
        @[ @"RUN", @(40), @(45), @(10), @(YES) ],
        @[ @"ATTACK", @(46), @(53), @(10), @(YES) ],
        @[ @"PAIN_A", @(54), @(57), @(7), @(YES) ],
        @[ @"PAIN_B", @(58), @(61), @(7), @(YES) ],
        @[ @"PAIN_C", @(62), @(65), @(7), @(YES) ],
        @[ @"JUMP", @(66), @(71), @(7), @(YES) ],
        @[ @"FLIP", @(72), @(83), @(7), @(YES) ],
        @[ @"SALUTE", @(84), @(94), @(7), @(YES) ],
        @[ @"FALLBACK", @(95), @(111), @(10), @(YES) ],
        @[ @"WAVE", @(112), @(122), @(7), @(YES) ],
        @[ @"POINT", @(123), @(134), @(6), @(YES) ],
        @[ @"CROUCH_STAND", @(135), @(153), @(10), @(YES) ],
        @[ @"CROUCH_WALK", @(154), @(159), @(7), @(YES) ],
        @[ @"CROUCH_ATTACK", @(160), @(168), @(10), @(YES) ],
        @[ @"CROUCH_PAIN", @(169), @(172), @(7), @(YES) ],
        @[ @"CROUCH_DEATH", @(173), @(177), @(5), @(NO) ],
        @[ @"DEATH_FALLBACK", @(178), @(183), @(7), @(NO) ],
        @[ @"DEATH_FALLFORWARD", @(184), @(189), @(7), @(NO) ],
        @[ @"DEATH_FALLBACKSLOW", @(190), @(197), @(7), @(NO) ]
    ];
}

@end

static const float _MD2_NORMALS[162][3] = {
    {-0.525731f, 0.000000f, 0.850651f},
    {-0.442863f, 0.238856f, 0.864188f},
    {-0.295242f, 0.000000f, 0.955423f},
    {-0.309017f, 0.500000f, 0.809017f},
    {-0.162460f, 0.262866f, 0.951056f},
    {0.000000f, 0.000000f, 1.000000f},
    {0.000000f, 0.850651f, 0.525731f},
    {-0.147621f, 0.716567f, 0.681718f},
    {0.147621f, 0.716567f, 0.681718f},
    {0.000000f, 0.525731f, 0.850651f},
    {0.309017f, 0.500000f, 0.809017f},
    {0.525731f, 0.000000f, 0.850651f},
    {0.295242f, 0.000000f, 0.955423f},
    {0.442863f, 0.238856f, 0.864188f},
    {0.162460f, 0.262866f, 0.951056f},
    {-0.681718f, 0.147621f, 0.716567f},
    {-0.809017f, 0.309017f, 0.500000f},
    {-0.587785f, 0.425325f, 0.688191f},
    {-0.850651f, 0.525731f, 0.000000f},
    {-0.864188f, 0.442863f, 0.238856f},
    {-0.716567f, 0.681718f, 0.147621f},
    {-0.688191f, 0.587785f, 0.425325f},
    {-0.500000f, 0.809017f, 0.309017f},
    {-0.238856f, 0.864188f, 0.442863f},
    {-0.425325f, 0.688191f, 0.587785f},
    {-0.716567f, 0.681718f, -0.147621f},
    {-0.500000f, 0.809017f, -0.309017f},
    {-0.525731f, 0.850651f, 0.000000f},
    {0.000000f, 0.850651f, -0.525731f},
    {-0.238856f, 0.864188f, -0.442863f},
    {0.000000f, 0.955423f, -0.295242f},
    {-0.262866f, 0.951056f, -0.162460f},
    {0.000000f, 1.000000f, 0.000000f},
    {0.000000f, 0.955423f, 0.295242f},
    {-0.262866f, 0.951056f, 0.162460f},
    {0.238856f, 0.864188f, 0.442863f},
    {0.262866f, 0.951056f, 0.162460f},
    {0.500000f, 0.809017f, 0.309017f},
    {0.238856f, 0.864188f, -0.442863f},
    {0.262866f, 0.951056f, -0.162460f},
    {0.500000f, 0.809017f, -0.309017f},
    {0.850651f, 0.525731f, 0.000000f},
    {0.716567f, 0.681718f, 0.147621f},
    {0.716567f, 0.681718f, -0.147621f},
    {0.525731f, 0.850651f, 0.000000f},
    {0.425325f, 0.688191f, 0.587785f},
    {0.864188f, 0.442863f, 0.238856f},
    {0.688191f, 0.587785f, 0.425325f},
    {0.809017f, 0.309017f, 0.500000f},
    {0.681718f, 0.147621f, 0.716567f},
    {0.587785f, 0.425325f, 0.688191f},
    {0.955423f, 0.295242f, 0.000000f},
    {1.000000f, 0.000000f, 0.000000f},
    {0.951056f, 0.162460f, 0.262866f},
    {0.850651f, -0.525731f, 0.000000f},
    {0.955423f, -0.295242f, 0.000000f},
    {0.864188f, -0.442863f, 0.238856f},
    {0.951056f, -0.162460f, 0.262866f},
    {0.809017f, -0.309017f, 0.500000f},
    {0.681718f, -0.147621f, 0.716567f},
    {0.850651f, 0.000000f, 0.525731f},
    {0.864188f, 0.442863f, -0.238856f},
    {0.809017f, 0.309017f, -0.500000f},
    {0.951056f, 0.162460f, -0.262866f},
    {0.525731f, 0.000000f, -0.850651f},
    {0.681718f, 0.147621f, -0.716567f},
    {0.681718f, -0.147621f, -0.716567f},
    {0.850651f, 0.000000f, -0.525731f},
    {0.809017f, -0.309017f, -0.500000f},
    {0.864188f, -0.442863f, -0.238856f},
    {0.951056f, -0.162460f, -0.262866f},
    {0.147621f, 0.716567f, -0.681718f},
    {0.309017f, 0.500000f, -0.809017f},
    {0.425325f, 0.688191f, -0.587785f},
    {0.442863f, 0.238856f, -0.864188f},
    {0.587785f, 0.425325f, -0.688191f},
    {0.688191f, 0.587785f, -0.425325f},
    {-0.147621f, 0.716567f, -0.681718f},
    {-0.309017f, 0.500000f, -0.809017f},
    {0.000000f, 0.525731f, -0.850651f},
    {-0.525731f, 0.000000f, -0.850651f},
    {-0.442863f, 0.238856f, -0.864188f},
    {-0.295242f, 0.000000f, -0.955423f},
    {-0.162460f, 0.262866f, -0.951056f},
    {0.000000f, 0.000000f, -1.000000f},
    {0.295242f, 0.000000f, -0.955423f},
    {0.162460f, 0.262866f, -0.951056f},
    {-0.442863f, -0.238856f, -0.864188f},
    {-0.309017f, -0.500000f, -0.809017f},
    {-0.162460f, -0.262866f, -0.951056f},
    {0.000000f, -0.850651f, -0.525731f},
    {-0.147621f, -0.716567f, -0.681718f},
    {0.147621f, -0.716567f, -0.681718f},
    {0.000000f, -0.525731f, -0.850651f},
    {0.309017f, -0.500000f, -0.809017f},
    {0.442863f, -0.238856f, -0.864188f},
    {0.162460f, -0.262866f, -0.951056f},
    {0.238856f, -0.864188f, -0.442863f},
    {0.500000f, -0.809017f, -0.309017f},
    {0.425325f, -0.688191f, -0.587785f},
    {0.716567f, -0.681718f, -0.147621f},
    {0.688191f, -0.587785f, -0.425325f},
    {0.587785f, -0.425325f, -0.688191f},
    {0.000000f, -0.955423f, -0.295242f},
    {0.000000f, -1.000000f, 0.000000f},
    {0.262866f, -0.951056f, -0.162460f},
    {0.000000f, -0.850651f, 0.525731f},
    {0.000000f, -0.955423f, 0.295242f},
    {0.238856f, -0.864188f, 0.442863f},
    {0.262866f, -0.951056f, 0.162460f},
    {0.500000f, -0.809017f, 0.309017f},
    {0.716567f, -0.681718f, 0.147621f},
    {0.525731f, -0.850651f, 0.000000f},
    {-0.238856f, -0.864188f, -0.442863f},
    {-0.500000f, -0.809017f, -0.309017f},
    {-0.262866f, -0.951056f, -0.162460f},
    {-0.850651f, -0.525731f, 0.000000f},
    {-0.716567f, -0.681718f, -0.147621f},
    {-0.716567f, -0.681718f, 0.147621f},
    {-0.525731f, -0.850651f, 0.000000f},
    {-0.500000f, -0.809017f, 0.309017f},
    {-0.238856f, -0.864188f, 0.442863f},
    {-0.262866f, -0.951056f, 0.162460f},
    {-0.864188f, -0.442863f, 0.238856f},
    {-0.809017f, -0.309017f, 0.500000f},
    {-0.688191f, -0.587785f, 0.425325f},
    {-0.681718f, -0.147621f, 0.716567f},
    {-0.442863f, -0.238856f, 0.864188f},
    {-0.587785f, -0.425325f, 0.688191f},
    {-0.309017f, -0.500000f, 0.809017f},
    {-0.147621f, -0.716567f, 0.681718f},
    {-0.425325f, -0.688191f, 0.587785f},
    {-0.162460f, -0.262866f, 0.951056f},
    {0.442863f, -0.238856f, 0.864188f},
    {0.162460f, -0.262866f, 0.951056f},
    {0.309017f, -0.500000f, 0.809017f},
    {0.147621f, -0.716567f, 0.681718f},
    {0.000000f, -0.525731f, 0.850651f},
    {0.425325f, -0.688191f, 0.587785f},
    {0.587785f, -0.425325f, 0.688191f},
    {0.688191f, -0.587785f, 0.425325f},
    {-0.955423f, 0.295242f, 0.000000f},
    {-0.951056f, 0.162460f, 0.262866f},
    {-1.000000f, 0.000000f, 0.000000f},
    {-0.850651f, 0.000000f, 0.525731f},
    {-0.955423f, -0.295242f, 0.000000f},
    {-0.951056f, -0.162460f, 0.262866f},
    {-0.864188f, 0.442863f, -0.238856f},
    {-0.951056f, 0.162460f, -0.262866f},
    {-0.809017f, 0.309017f, -0.500000f},
    {-0.864188f, -0.442863f, -0.238856f},
    {-0.951056f, -0.162460f, -0.262866f},
    {-0.809017f, -0.309017f, -0.500000f},
    {-0.681718f, 0.147621f, -0.716567f},
    {-0.681718f, -0.147621f, -0.716567f},
    {-0.850651f, 0.000000f, -0.525731f},
    {-0.688191f, 0.587785f, -0.425325f},
    {-0.587785f, 0.425325f, -0.688191f},
    {-0.425325f, 0.688191f, -0.587785f},
    {-0.425325f, -0.688191f, -0.587785f},
    {-0.587785f, -0.425325f, -0.688191f},
    {-0.688191f, -0.587785f, -0.425325f}
};

typedef struct MD2Header {
   int magic;
   int version;
   int skinWidth;
   int skinHeight;
   int frameSize;
   int numSkins;
   int numVertices;
   int numTexCoords;
   int numTriangles;
   int numGlCommands;
   int numFrames;
   int offsetSkins;
   int offsetTexCoords;
   int offsetTriangles;
   int offsetFrames;
   int offsetGlCommands;
   int offsetEnd;
} MD2Header;

typedef struct MD2Vertex {
   UInt8 vertex[3];
   UInt8 lightNormalIndex;
} MD2Vertex;

typedef struct MD2Frame {
   float scale[3];
   float translate[3];
   char name[16];
   MD2Vertex vertices[1];
} MD2Frame;

typedef struct MD2Triangle {
   short vertexIndices[3];
   short textureIndices[3];
} MD2Triangle;

typedef struct MD2TextureCoordinate {
   short s, t;
} MD2TextureCoordinate;

@implementation KeyFrameMeshLoader

- (id)load:(NSURL *)url assets:(AssetManager *)assets {
    NSData* data = [NSData dataWithContentsOfURL:url];
    MD2Header* header = (MD2Header*)data.bytes;
    MD2Triangle* triangles = (MD2Triangle*)(data.bytes + header->offsetTriangles);
    MD2TextureCoordinate* textureCoordinates = (MD2TextureCoordinate*)(data.bytes + header->offsetTexCoords);
    NSMutableArray<KeyFrame*>* frames = [NSMutableArray arrayWithCapacity:header->numFrames];
    
    for(int i = 0; i != header->numFrames; i++) {
        MD2Frame* frame = (MD2Frame*)(data.bytes + header->offsetFrames + i * header->frameSize);
        KeyFrame* keyFrame = [[KeyFrame alloc] init];
        
        for(int j = 0; j != header->numTriangles; j++) {
            for(int k = 0; k != 3; k++) {
                float s = textureCoordinates[triangles[j].textureIndices[k]].s / (float)header->skinWidth;
                float t = textureCoordinates[triangles[j].textureIndices[k]].t / (float)header->skinHeight;
                float x = frame->vertices[triangles[j].vertexIndices[k]].vertex[0] * frame->scale[0] + frame->translate[0];
                float y = frame->vertices[triangles[j].vertexIndices[k]].vertex[1] * frame->scale[1] + frame->translate[1];
                float z = frame->vertices[triangles[j].vertexIndices[k]].vertex[2] * frame->scale[2] + frame->translate[2];
                float nx = _MD2_NORMALS[frame->vertices[triangles[j].vertexIndices[k]].lightNormalIndex][0];
                float ny = _MD2_NORMALS[frame->vertices[triangles[j].vertexIndices[k]].lightNormalIndex][1];
                float nz = _MD2_NORMALS[frame->vertices[triangles[j].vertexIndices[k]].lightNormalIndex][2];
                
                [keyFrame pushVertex:(KeyFrameVertex){ { x, y, z }, { s, t }, { nx, ny, nz } }];
            }
        }
        [frames addObject:keyFrame];
    }
    return [[KeyFrameMesh alloc] initWithView:assets.view frames:frames];
}

+ (int)normalCount {
    return sizeof(_MD2_NORMALS) / 12;
}

+ (Vec3)normalAt:(int)i {
    return Vec3Make(_MD2_NORMALS[i][0], _MD2_NORMALS[i][1], _MD2_NORMALS[i][2]);
}

@end
