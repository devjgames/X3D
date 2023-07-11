//
//  LightMapper.m
//  X3D
//
//  Created by Douglas McNamara on 7/10/23.
//

#import <X3D/X3D.h>

@interface LightMapper ()

- (void)append:(Node*)node meshes:(NSMutableArray<Mesh*>*)meshes lights:(NSMutableArray<Node*>*)lights;

@end

@implementation LightMapper

- (void)map:(Scene *)scene view:(MTLView *)view url:(NSURL *)sceneURL rebuild:(BOOL)rebuild {
    NSMutableArray<Mesh*>* meshes = [NSMutableArray arrayWithCapacity:64];
    NSMutableArray<Node*>* lights = [NSMutableArray arrayWithCapacity:16];
    NSMutableData* data = nil;
    NSMutableData* triangles = nil;
    NSString* name = [sceneURL.lastPathComponent stringByDeletingPathExtension];
    NSURL* url = [[sceneURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", name]];
    NSString* path = [url.path stringByReplacingOccurrencesOfString:view.assets.baseURL.path withString:@""];
    NSMutableArray* tiles = [NSMutableArray arrayWithCapacity:100];
    
    [self append:scene.root meshes:meshes lights:lights];
    
    path = [path substringFromIndex:1];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:url.path] || rebuild) {
        data = [NSMutableData dataWithLength:scene.lightMapWidth * scene.lightMapHeight * 4];
        triangles = [NSMutableData dataWithCapacity:1000 * sizeof(Triangle)];
        for(Mesh* mesh in meshes) {
            if(mesh.castsShadow) {
                for(int i = 0; i != mesh.triangleCount; i++) {
                    Triangle triangle = [mesh triangleAt:i];
                    
                    [triangles appendBytes:&triangle length:sizeof(Triangle)];
                }
            }
        }
    }
    
    int x = 0;
    int y = 0;
    int maxH = 0;
    
    for(Mesh* mesh in meshes) {
        if(mesh.lightMapEnabled) {
            for(int i = 0; i != mesh.faceCount; i++) {
                if([mesh faceVertexCountAt:i] == 4) {
                    BasicVertex v1 = [mesh vertexAt:[mesh face:i vertexAt:0]];
                    BasicVertex v2 = [mesh vertexAt:[mesh face:i vertexAt:1]];
                    BasicVertex v3 = [mesh vertexAt:[mesh face:i vertexAt:2]];
                    BasicVertex v4 = [mesh vertexAt:[mesh face:i vertexAt:3]];
                    
                    v1.position = Vec3Transform(mesh.model, v1.position);
                    v2.position = Vec3Transform(mesh.model, v2.position);
                    v3.position = Vec3Transform(mesh.model, v3.position);
                    v4.position = Vec3Transform(mesh.model, v4.position);
                    v1.normal = Vec3TransformNormal(Mat4Transpose(Mat4Invert(mesh.model)), v1.normal);
                    
                    Vec3 u = v2.position - v1.position;
                    Vec3 v = v4.position - v1.position;
                    int w = (int)ceilf(Vec3Length(u) / 16) + 1;
                    int h = (int)ceilf(Vec3Length(v) / 16) + 1;
                    
                    if(x + w > scene.lightMapWidth) {
                        x = 0;
                        y += maxH;
                        maxH = 0;
                    }
                    maxH = MAX(maxH, h);
                    if(y + h > scene.lightMapHeight || x + w > scene.lightMapWidth) {
                        Log(@"Failed to allocate light map tile ...");
                        for(Mesh* mesh in meshes) {
                            if(mesh.lightMapEnabled) {
                                mesh.basicEncodable.texture2 = nil;
                                return;
                            }
                        }
                    }
                    
                    [tiles addObject:@[
                        @(x), @(y), @(w), @(h),
                        @[ @(v1.position.x), @(v1.position.y), @(v1.position.z) ],
                        @[ @(v2.position.x), @(v2.position.y), @(v2.position.z) ],
                        @[ @(v3.position.x), @(v3.position.y), @(v3.position.z) ],
                        @[ @(v4.position.x), @(v4.position.y), @(v4.position.z) ],
                        @[ @(v1.normal.x), @(v1.normal.y), @(v1.normal.z) ],
                        mesh
                    ]];
                    
                    v1 = [mesh vertexAt:[mesh face:i vertexAt:0]];
                    v2 = [mesh vertexAt:[mesh face:i vertexAt:1]];
                    v3 = [mesh vertexAt:[mesh face:i vertexAt:2]];
                    v4 = [mesh vertexAt:[mesh face:i vertexAt:3]];
                    
                    v1.textureCoordinate2 = Vec2Make((x + 0 + 0.5f) / scene.lightMapWidth, (y + 0 + 0.5f) / scene.lightMapHeight);
                    v2.textureCoordinate2 = Vec2Make((x + w - 0.5f) / scene.lightMapWidth, (y + 0 + 0.5f) / scene.lightMapHeight);
                    v3.textureCoordinate2 = Vec2Make((x + w - 0.5f) / scene.lightMapWidth, (y + h - 0.5f) / scene.lightMapHeight);
                    v4.textureCoordinate2 = Vec2Make((x + 0 + 0.5f) / scene.lightMapWidth, (y + h - 0.5f) / scene.lightMapHeight);
                    
                    [mesh setVertex:v1 at:[mesh face:i vertexAt:0]];
                    [mesh setVertex:v2 at:[mesh face:i vertexAt:1]];
                    [mesh setVertex:v3 at:[mesh face:i vertexAt:2]];
                    [mesh setVertex:v4 at:[mesh face:i vertexAt:3]];
                    
                    x += w;
                } else {
                    Log(@"Mesh face not a quad");
                }
            }
            [mesh bufferVertices];
        }
    }
    
    if(data) {
        Log(@"Rendering light map to '%@' ...", path);
        
        for(int i = 0; i != (int)data.length; i += 4) {
            ((UInt8*)data.mutableBytes)[i + 0] = 255;
            ((UInt8*)data.mutableBytes)[i + 1] = 0;
            ((UInt8*)data.mutableBytes)[i + 2] = 255;
            ((UInt8*)data.mutableBytes)[i + 3] = 255;
        }
        
        for(NSArray* tile in tiles) {
            int tx = [tile[0] intValue];
            int ty = [tile[1] intValue];
            int tw = [tile[2] intValue];
            int th = [tile[3] intValue];
            Vec3 p1 = Vec3Make([tile[4][0] floatValue],
                               [tile[4][1] floatValue],
                               [tile[4][2] floatValue]
                               );
            Vec3 p2 = Vec3Make([tile[5][0] floatValue],
                               [tile[5][1] floatValue],
                               [tile[5][2] floatValue]
                               );
            Vec3 p3 = Vec3Make([tile[6][0] floatValue],
                               [tile[6][1] floatValue],
                               [tile[6][2] floatValue]
                               );
            Vec3 p4 = Vec3Make([tile[7][0] floatValue],
                               [tile[7][1] floatValue],
                               [tile[7][2] floatValue]
                               );
            Vec3 normal = Vec3Make([tile[8][0] floatValue],
                                   [tile[8][1] floatValue],
                                   [tile[8][2] floatValue]
                                   );
            Mesh* mesh = tile[9];
            Triangle triangle;
            
            Log(@"Tile %i %i %i %i %@ ...", tx, ty, tw, th, mesh);

            for(int ix = tx; ix != tx + tw; ix++) {
                for(int iy = ty; iy != ty + th; iy++) {
                    float s = (ix - tx + 0.5f) / (float)tw;
                    float t = (iy - ty + 0.5f) / (float)th;
                    Vec3 a = p1 + s * (p2 - p1);
                    Vec3 b = p4 + s * (p3 - p4);
                    Vec3 p = a + t * (b - a);
                    Vec4 color = Vec4Make(0, 0, 0, 1);
                    float sV;
                    
                    for(Node* light in lights) {
                        Vec3 lightOffset = light.absolutePosition - p;
                        Vec3 lightNormal = Vec3Normalize(lightOffset);
                        float lDotN = MIN(1, Vec3Dot(lightNormal, normal));
                        float atten = Vec3Length(lightOffset) / light.lightRadius;
                        
                        if(lDotN > 0 && atten < 1) {
                            sV = 1;
                            if(mesh.receivesShadow) {
                                srand(1000);
                                for(int i = 0; i != scene.sampleCount; i++) {
                                    Vec3 sample = Vec3Make(rand() / (float)RAND_MAX * 2 - 1,
                                                           rand() / (float)RAND_MAX * 2 - 1,
                                                           rand() / (float)RAND_MAX * 2 - 1
                                                           );
                                    if(Vec3Length(sample) < 0.0000001) {
                                        sample = Vec3Make(0, 1, 0);
                                    }
                                    sample = Vec3Normalize(sample);
                                    
                                    Vec3 origin = p + lightNormal;
                                    Vec3 direction = light.absolutePosition + scene.sampleRadius * sample - origin;
                                    float time = Vec3Length(direction);
                                    BOOL hit = NO;
                                    
                                    direction = Vec3Normalize(direction);
                                    for(int j = 0; j != (int)(triangles.length / sizeof(Triangle)); j++) {
                                        triangle = ((Triangle*)triangles.mutableBytes)[j];
                                        if(TriangleRayIntersects(triangle, origin, direction, 0, &time)) {
                                            hit = YES;
                                            break;
                                        }
                                    }
                                    if(hit) {
                                        sV -= 1.0f / scene.sampleCount;
                                    }
                                }
                            }
                            color += sV * (1 - atten) * lDotN * mesh.basicEncodable.diffuseColor * light.lightColor;
                        }
                    }
                    
                    if(mesh.aoEnabled) {
                        int count = 0;
                        
                        srand(1000);
                        for(int i = 0; i != scene.sampleCount; i++) {
                            Vec3 sample = Vec3Make(rand() / (float)RAND_MAX * 2 - 1,
                                                   rand() / (float)RAND_MAX * 2 - 1,
                                                   rand() / (float)RAND_MAX * 2 - 1
                                                   );
                            if(Vec3Length(sample) < 0.0000001) {
                                sample = Vec3Make(0, 1, 0);
                            }
                            sample = Vec3Normalize(sample);
                            
                            if(Vec3Dot(sample, normal) > 0.1f) {
                                count++;
                            }
                        }
                        
                        srand(1000);
                        sV = 1;
                        for(int i = 0; i != scene.sampleCount; i++) {
                            Vec3 sample = Vec3Make(rand() / (float)RAND_MAX * 2 - 1,
                                                   rand() / (float)RAND_MAX * 2 - 1,
                                                   rand() / (float)RAND_MAX * 2 - 1
                                                   );
                            if(Vec3Length(sample) < 0.0000001) {
                                sample = Vec3Make(0, 1, 0);
                            }
                            sample = Vec3Normalize(sample);
                            
                            if(Vec3Dot(sample, normal) > 0.1f) {
                                Vec3 origin = p + normal;
                                Vec3 direction = sample;
                                float time = scene.aoLength;
                                BOOL hit = NO;
                                
                                for(int j = 0; j != (int)(triangles.length / sizeof(Triangle)); j++) {
                                    triangle = ((Triangle*)triangles.mutableBytes)[j];
                                    if(TriangleRayIntersects(triangle, origin, direction, 0, &time)) {
                                        hit = YES;
                                        break;
                                    }
                                }
                                if(hit) {
                                    sV = MAX(0, sV - scene.aoStrength / count);
                                }
                            }
                        }
                        color *= sV;
                    }
                    color += mesh.basicEncodable.ambientColor;
                    
                    float max = MAX(color.x, MAX(color.y, color.z));
                    
                    if(max > 1) {
                        color /= max;
                    }
                    
                    UInt8 cr = (UInt8)(color.x * 255);
                    UInt8 cg = (UInt8)(color.y * 255);
                    UInt8 cb = (UInt8)(color.z * 255);
                    int i = iy * scene.lightMapWidth * 4 + ix * 4;
                    
                    ((UInt8*)data.mutableBytes)[i + 0] = cr;
                    ((UInt8*)data.mutableBytes)[i + 1] = cg;
                    ((UInt8*)data.mutableBytes)[i + 2] = cb;
                }
            }
        }
    
        [view saveRGBA:data width:scene.lightMapWidth height:scene.lightMapHeight toPath:path];
        [view.assets unLoad:path];
    }
    
    id<MTLTexture> texture = [view.assets load:path];
    
    for(Mesh* mesh in meshes) {
        if(mesh.lightMapEnabled) {
            mesh.basicEncodable.texture2 = texture;
            mesh.basicEncodable.texture2Sampler = LINEAR_CLAMP_TO_EDGE;
        }
    }
}

- (void)append:(Node *)node meshes:(NSMutableArray<Mesh *> *)meshes lights:(NSMutableArray<Node *> *)lights {
    if([node isKindOfClass:[Mesh class]]) {
        [meshes addObject:(Mesh*)node];
    }
    if(node.isLight) {
        [lights addObject:node];
    }
    for(int i = 0; i != node.childCount; i++) {
        [self append:[node childAt:i] meshes:meshes lights:lights];
    }
}

@end
