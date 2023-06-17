//
//  KeyFrameMeshTest.m
//  X3DTest
//
//  Created by Douglas McNamara on 5/17/23.
//

#import "Test.h"

@interface KeyFrameMeshTest ()

@property Scene* scene;
@property KeyFrameMesh* mesh;
@property BasicEncodable* text;
@property NSMutableData* lights;
@property NSArray<NSArray<id>*>* sequences;
@property NSMutableArray<NSString*>* sequenceNames;
@property int selSequence;
@property NSMutableArray<NSString*>* meshNames;
@property NSMutableArray<NSString*> *meshPaths;
@property int selMesh;

- (void)populateMeshes:(NSURL*)directory;

@end

@implementation KeyFrameMeshTest

- (void)setup:(MTLView *)view {
    self.scene = [[Scene alloc] init];
    self.scene.camera.eye = Vec3Make(50, 50, 50);
    
    self.mesh = nil;
    
    self.text = [[BasicEncodable alloc] initWithView:view vertexCount:1];
    self.text.texture = [view.assets load:@"assets/font.png"];
    self.text.vertexColorEnabled = YES;
    self.text.depthTestEnabled = NO;
    self.text.depthWriteEnabled = NO;
    self.text.blendEnabled = YES;
    self.text.textureSampler = NEAREST_CLAMP_TO_EDGE;
    
    [self.text createDepthAndPipelineState];
    
    self.lights = [NSMutableData dataWithCapacity:MAX_LIGHTS * sizeof(Light)];
    
    Light lights[] = {
        { { +50, 50, +50 }, { 4, 2, 0, 1 }, 150 },
        { { -50, 50, -50 }, { 0, 2, 4, 1 }, 150 }
    };
    
    [self.lights appendBytes:&lights length:sizeof(lights)];
    
    view.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2f, 0.2f, 0.2f, 1);
    
    self.sequences = [KeyFrameMesh sequences];
    self.sequenceNames = [NSMutableArray arrayWithCapacity:self.sequences.count];
    
    for(NSArray<id>* sequence in self.sequences) {
        [self.sequenceNames addObject:sequence[0]];
    }
    self.selSequence = -1;
    
    self.meshPaths = [NSMutableArray arrayWithCapacity:16];
    self.meshNames = [NSMutableArray arrayWithCapacity:16];
    
    [self populateMeshes:view.assets.baseURL];
    
    [self.meshPaths sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    for(NSString* path in self.meshPaths) {
        [self.meshNames addObject:[[path lastPathComponent] stringByDeletingPathExtension]];
    }
    self.selMesh = -1;
}

- (BOOL)nextFrame:(MTLView *)view {
    id<CAMetalDrawable> drawable = [view.metalLayer nextDrawable];
    
    if(drawable) {
        view.renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
        
        id<MTLCommandBuffer> commandBuffer = [view.commandQueue commandBuffer];
        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:view.renderPassDescriptor];
        
        [self.scene.camera calcTransforms:view.aspectRatio];
        [self.scene.root calcTransform];
        
        [encoder setViewport:(MTLViewport){ 0, 0, view.width, view.height, 0, 1 }];
        [self.scene encodeWithEncoder:encoder lights:self.lights];
        [self.text encodeWithEncoder:encoder
                          projection:Mat4Ortho(0, view.width, view.height, 0, -1, 1)
                                view:Mat4Identity()
                               model:Mat4Identity()
                              lights:self.lights];
        [encoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
    }
    
    if([view isButtonDown:0]) {
        [self.scene.camera rotate:view];
    }
    [self.scene.root updateWithScene:self.scene view:view];
    
    NSString* info = [NSString stringWithFormat:@"FPS = %i\nOBJ = %i\nESC = Quit", view.frameRate, XObject.instances];
    
    [self.text clear];
    [self.text pushText:info xy:NSMakePoint(10, 10) size:NSMakeSize(8, 12) cols:100 lineSpacing:5 color:Vec4Make(1, 1, 1, 1)];
    [self.text bufferVertices];
    
    id result;
    
    [view.ui begin];
    if(self.mesh) {
        if([view.ui button:@"KeyFrameMeshTest.warp.button" gap:0 caption:@"Warp Key Frame Mesh" selected:self.mesh.basicEncodable.warpEnabled]) {
            self.mesh.basicEncodable.warpEnabled = !self.mesh.basicEncodable.warpEnabled;
            if(self.mesh.childCount) {
                KeyFrameMesh* weapon = [self.mesh childAt:0];
                
                weapon.basicEncodable.warpEnabled = !weapon.basicEncodable.warpEnabled;
            }
        }
        [view.ui addRow:5];
    }
    if((result = [view.ui list:@"KeyFrameMeshTest.mesh.list" gap:0 items:self.meshNames size:NSMakeSize(250, 200) selection:self.selMesh])) {
        NSString* path = self.meshPaths[[result intValue]];
        
        path = [path stringByReplacingOccurrencesOfString:view.assets.baseURL.path withString:@""];
        path = [path substringToIndex:path.length];
        path = [path substringFromIndex:1];
        
        NSString* texturePath = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
        NSString* weaponPath = [[path stringByDeletingLastPathComponent]
                                stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-weapon.md2",
                                                                [[path lastPathComponent] stringByDeletingPathExtension]]];
        NSString* weaponTexturePath = [[weaponPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
        
        if(self.mesh) {
            [self.mesh detach];
        }
        self.mesh = [view.assets load:path];
        self.mesh = [[KeyFrameMesh alloc] initWithKeyFrameMesh:self.mesh];
        self.mesh.basicEncodable.lightingEnabled = YES;
        self.mesh.rotation = Mat4Rotate(-90, Vec3Make(1, 0, 0));
        [self.mesh setSequenceStart:0 end:39 speed:10 looping:YES];
        
        if([[NSFileManager defaultManager] fileExistsAtPath:[[view.assets.baseURL URLByAppendingPathComponent:texturePath] path]]) {
            self.mesh.basicEncodable.texture = [view.assets load:texturePath];
        }
        if([[NSFileManager defaultManager] fileExistsAtPath:[[view.assets.baseURL URLByAppendingPathComponent:weaponPath] path]]) {
            KeyFrameMesh* weaponMesh = [view.assets load:weaponPath];
            
            weaponMesh = [[KeyFrameMesh alloc] initWithKeyFrameMesh:weaponMesh];
            weaponMesh.basicEncodable.lightingEnabled = YES;
            
            if([[NSFileManager defaultManager] fileExistsAtPath:[[view.assets.baseURL URLByAppendingPathComponent:weaponTexturePath] path]]) {
                weaponMesh.basicEncodable.texture = [view.assets load:weaponTexturePath];
            }
            [weaponMesh setSequenceStart:0 end:39 speed:10 looping:YES];
            
            [self.mesh addChild:weaponMesh];
        }
        [self.scene.root addChild:self.mesh];
        
        self.selSequence = 0;
    }
    if(self.mesh) {
        [view.ui addRow:5];
        if((result = [view.ui list:@"KeyFrameMeshTest.sequence.list" gap:0 items:self.sequenceNames size:NSMakeSize(250, 200) selection:self.selSequence])) {
            NSArray<id>* sequence = self.sequences[[result intValue]];
            
            [self.mesh setSequenceStart:[sequence[1] intValue]
                                    end:[sequence[2] intValue]
                                  speed:[sequence[3] intValue]
                                looping:[sequence[4] boolValue]
            ];
            if(self.mesh.childCount) {
                KeyFrameMesh* mesh = [self.mesh childAt:0];
                
                [mesh setSequenceStart:[sequence[1] intValue]
                                   end:[sequence[2] intValue]
                                 speed:[sequence[3] intValue]
                               looping:[sequence[4] boolValue]
                ];
            }
        }
    }
    self.selSequence = -2;
    self.selMesh = -2;
    [view.ui end];
    
    return ![view isKeyDown:53];
}

- (void)tearDown {
    self.scene = nil;
    self.mesh = nil;
    self.text = nil;
    self.lights = nil;
    self.sequences = nil;
    self.sequenceNames = nil;
    self.meshNames = nil;
    self.meshPaths = nil;
}

- (void)populateMeshes:(NSURL *)directory {
    NSFileManager* manager = [NSFileManager defaultManager];
    NSArray* items = [manager contentsOfDirectoryAtPath:directory.path error:nil];
    BOOL dir;
    
    for(NSString* item in items) {
        NSString* path = [directory.path stringByAppendingPathComponent:item];
        
        if([item.pathExtension isEqual:@"md2"]) {
            [self.meshPaths addObject:path];
        } else if([manager fileExistsAtPath:path isDirectory:&dir]) {
            if(dir) {
                [self populateMeshes:[NSURL fileURLWithPath:path]];
            }
        }
    }
}

@end