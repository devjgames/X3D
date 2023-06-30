//
//  Test.m
//  X3D
//
//  Created by Douglas McNamara on 6/28/23.
//

#import <X3D/X3D.h>

@implementation Test

- (void)setup:(MTLView *)view {
}

- (BOOL)nextFrame:(MTLView *)view {
    return NO;
}

- (void)tearDown {
}

- (NSString*)description {
    return NSStringFromClass(self.class);
}

@end

@interface TestFramework ()

@property (weak) NSWindow* window;
@property (weak) MTLView* view;
@property NSArray<Test*>* tests;
@property Test* test;
@property (weak) NSTimer* timer;

@end

@implementation TestFramework

- (id)initWithWindow:(NSWindow *)window view:(MTLView *)view tests:(NSArray<Test *> *)tests {
    self = [super init];
    if(self) {
        self.view = view;
        self.view.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2f, 0.2f, 0.2f, 1);
        
        self.window = window;
        
        self.tests = tests;
        self.test = nil;
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 / 60.0 target:self selector:@selector(nextFrame) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)nextFrame {
    static int index = -1;
    static BOOL fs = NO;
    
    [self.view createTextures];

    if(self.test) {
        if(![self.test nextFrame:self.view]) {
            [self.view.assets clear];
            [self.test tearDown];
            [self setTest:nil];
            
            self.view.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2f, 0.2f, 0.2f, 1);
            
            index = -1;
        }
    } else {
        id<CAMetalDrawable> drawable = [self.view.metalLayer nextDrawable];
        id result;
        
        if(drawable) {
            self.view.renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
            
            id<MTLCommandBuffer> commandBuffer = [self.view.commandQueue commandBuffer];
            id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:self.view.renderPassDescriptor];
            
            [encoder setViewport:(MTLViewport){ 0, 0, self.view.width, self.view.height, 0, 1 }];
            [encoder endEncoding];
            [commandBuffer presentDrawable:drawable];
            [commandBuffer commit];
            [commandBuffer waitUntilCompleted];
        }
        [self.view.ui begin];
        if([self.view.ui button:@"App.full.screen.button" gap:0 caption:@"Full Screen" selected:fs]) {
            [self.window toggleFullScreen:nil];
            fs = !fs;
        }
        [self.view.ui addRow:5];
        if((result = [self.view.ui list:@"App.test.list" gap:0 items:self.tests size:NSMakeSize(250, 200) selection:index])) {
            self.test = self.tests[[result intValue]];
        }
        index = -2;
        [self.view.ui end];
        
        if(self.test) {
            [self.test setup:self.view];
            
            [self.view.ui begin];
            [self.view.ui end];
            
            [self.view resetTimer];
        }
    }
    
    [self.view tick];
}

- (void)tearDown {
    [self.timer invalidate];
    
    Log(@"%i instance(s)", XObject.instances);
    
    self.tests = nil;
    if(self.test) {
        [self.test tearDown];
    }
    self.test = nil;
    
    [self.view tearDown];
    
    Log(@"%i instance(s)", XObject.instances);
}

@end

#define ZOOM 0
#define ROT 1
#define PAN_XZ 2
#define PAN_Y 3
#define MOV_XZ 4
#define MOV_Y 5
#define ROT_Y 6

#define NODE_LIST 0
#define NODE_TYPE_LIST 1
#define SCENE_LIST 2
#define NODE_EDITOR 3

@interface Editor ()

@property Scene* scene;
@property BasicEncodable* text;
@property NSMutableArray* nodeTypeNames;
@property NSMutableArray* nodeList;
@property NSMutableArray* sceneNames;
@property int selNodeType;
@property int selNode;
@property int selSceneName;
@property int editor;
@property int mode;
@property int nodeIndex;
@property NSArray* modes;
@property BOOL down;
@property int snap;
@property NSURL* sceneURL;
@property BOOL resetNodeEditor;
@property BOOL resetSnap;

- (Node*)selection;
- (void)populateNodeList;

@end

@implementation Editor

- (id)init {
    self = [super init];
    if(self) {
        int count = (int)objc_getClassList(NULL, 0);
        Class* classes = (Class*)malloc(sizeof(Class) * count);
        
        objc_getClassList(classes, count);
        
        self.nodeTypeNames = [NSMutableArray arrayWithCapacity:16];
        
        for(int i = 0; i != count; i++) {
            Class cls = classes[i];
            Class parent = cls;
            NSString* name = NSStringFromClass(cls);
            
            if(![name isEqualToString:@"EditorNode"]) {
                while(true) {
                    parent = class_getSuperclass(parent);
                    if(parent == nil) {
                        break;
                    }
                    if([NSStringFromClass(parent) isEqualToString:@"EditorNode"]) {
                        [self.nodeTypeNames addObject:name];
                        break;
                    }
                }
            }
        }
        
        self.modes = @[ @"Zoom", @"Rot", @"PanXY", @"PanY", @"MovXZ", @"MovY", @"RotY" ];
    }
    return self;
}

- (void)setup:(MTLView *)view {
    
    self.scene = nil;
    
    self.text = [[BasicEncodable alloc] initWithView:view vertexCount:1];
    self.text.texture = [view.assets load:@"assets/font.png"];
    self.text.vertexColorEnabled = YES;
    self.text.blendEnabled = YES;
    self.text.depthTestEnabled = NO;
    self.text.depthWriteEnabled = NO;
    self.text.textureSampler = NEAREST_CLAMP_TO_EDGE;
    
    [self.text createDepthAndPipelineState];
    
    view.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2f, 0.2f, 0.2f, 1);
    
    self.nodeList = [NSMutableArray arrayWithCapacity:64];
    
    NSFileManager* manager = [NSFileManager defaultManager];
    NSString* path = [[view.assets.baseURL URLByAppendingPathComponent:@"assets/scenes"] path];
    NSArray* items = [manager contentsOfDirectoryAtPath:path error:nil];
    
    self.sceneNames = [NSMutableArray arrayWithCapacity:16];
    for(NSString* item in items) {
        NSString* extension = item.pathExtension;
        NSString* name = [[item lastPathComponent] stringByDeletingPathExtension];
        
        if([extension isEqualToString:@"txt"]) {
            [self.sceneNames addObject:name];
        }
    }
    
    self.selNode = -1;
    self.selSceneName = -1;
    self.selNodeType = 0;
    self.editor = -1;
    self.mode = 0;
    self.down = NO;
    self.snap = 0;
    self.nodeIndex = -1;
    self.sceneURL = nil;
    self.resetNodeEditor = NO;
    self.resetSnap = YES;
}

- (BOOL)nextFrame:(MTLView *)view {
    id<CAMetalDrawable> drawable = [view.metalLayer nextDrawable];
    
    [self.scene.root preUpdateWithScene:self.scene view:view];
    
    if(drawable) {
        view.renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
        
        id<MTLCommandBuffer> commandBuffer = [view.commandQueue commandBuffer];
        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:view.renderPassDescriptor];
        
        [self.scene.camera calcTransforms:view.aspectRatio];
        [self.scene.root calcTransform];
        
        [encoder setViewport:(MTLViewport){ 0, 0, view.width, view.height, 0, 1 }];
        if(self.scene) {
            [self.scene bufferLights];
            [self.scene encodeWithEncoder:encoder];
        }
        [self.text encodeWithEncoder:encoder
                          projection:Mat4Ortho(0, view.width, view.height, 0, -1, 1)
                                view:Mat4Identity()
                               model:Mat4Identity()
                              lights:nil];
        [encoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
    }
    
    NSString* info = [NSString stringWithFormat:@"FPS=%i, OBJ=%i", view.frameRate, XObject.instances];
    
    [self.text clear];
    [self.text pushText:info xy:NSMakePoint(10, 10) size:NSMakeSize(8, 12) cols:100 lineSpacing:5 color:Vec4Make(1, 1, 1, 1)];
    [self.text bufferVertices];
    
    UIManager* ui = view.ui;
    BOOL quit = NO;
    
    [ui begin];
    if([ui button:@"Editor.quit.button" gap:0 caption:@"Quit" selected:NO]) {
        quit = YES;
    }
    if([ui button:@"Editor.load.button" gap:5 caption:@"Load" selected:self.editor == SCENE_LIST]) {
        self.editor = SCENE_LIST;
        self.selSceneName = -1;
    }
    if(self.scene) {
        if([ui button:@"Editor.save.scene.button" gap:5 caption:@"Save" selected:NO]) {
            [self.scene serialize:self.sceneURL view:view];
        }
        if([ui button:@"Editor.add.node.button" gap:5 caption:@"+Node" selected:self.editor == NODE_TYPE_LIST]) {
            self.editor = NODE_TYPE_LIST;
            self.selNodeType = -1;
        }
        if([ui button:@"Editor.node.list.button" gap:5 caption:@"Nodes" selected:self.editor == NODE_LIST]) {
            self.editor = NODE_LIST;
            self.selNode = self.nodeIndex;
        }
        if([ui button:@"Editor.zero.targ.button" gap:5 caption:@"Zero Target" selected:NO]) {
            Vec3 offset = self.scene.camera.eye - self.scene.camera.target;
            
            self.scene.camera.target = Vec3Make(0, 0, 0);
            self.scene.camera.eye = self.scene.camera.target + offset;
        }
        [ui field:@"Editor.snap.field" gap:5 caption:@"Snap" intValue:&_snap width:75 reset:self.resetSnap];
        self.resetSnap = NO;
        for(int i = 0; i != (int)self.modes.count; i++) {
            if([ui button:[NSString stringWithFormat:@"Editor.mode.%i.button", i] gap:5 caption:self.modes[i] selected:i == self.mode]) {
                self.mode = i;
            }
        }
        if(self.selection) {
            [ui addRow:5];
            if([ui button:@"Editor.clear.sel.button" gap:0 caption:@"Clear" selected:NO]) {
                self.nodeIndex = self.selNode = -1;
            }
            if(self.selection) {
                if([ui button:@"Editor.edit.node.button" gap:5 caption:@"Edit" selected:self.editor == NODE_EDITOR]) {
                    self.editor = NODE_EDITOR;
                    self.resetNodeEditor = YES;
                }
                if([ui button:@"Editor.zero.node.pos.button" gap:5 caption:@"Zero Pos" selected:NO]) {
                    self.selection.position = Vec3Make(0, 0, 0);
                }
                if([ui button:@"Editor.node.pos.to.targ.button" gap:5 caption:@"Pos To Target" selected:NO]) {
                    self.selection.position = self.scene.camera.target;
                }
                if([ui button:@"Editor.targ.to.node.pos.button" gap:5 caption:@"Target To Pos" selected:NO]) {
                    Vec3 offset = self.scene.camera.eye - self.scene.camera.target;
                    
                    self.scene.camera.target = self.selection.position;
                    self.scene.camera.eye = self.selection.position + offset;
                }
                if([ui button:@"Editor.zero.node.rot.button" gap:5 caption:@"Zero Rot" selected:NO]) {
                    self.selection.rotation = Mat4Identity();
                }
                if([ui button:@"Editor.node.rot.y.45.button" gap:5 caption:@"Rot Y 45" selected:NO]) {
                    self.selection.rotation = Mat4Mul(self.selection.rotation, Mat4Rotate(45, Vec3Make(0, 1, 0)));
                }
                if([ui button:@"Editor.del.node.button" gap:5 caption:@"-Node" selected:NO]) {
                    self.editor = -1;
                    [self.selection detach];
                    [self populateNodeList];
                }
            }
        }
    }
    
    id result;
    NSSize size = NSMakeSize(250, 300);
    
    if(self.editor == NODE_TYPE_LIST) {
        [ui addRow:5];
        if((result = [ui list:@"Editor.node.type.list" gap:0 items:self.nodeTypeNames size:size selection:self.selNodeType])) {
            Node* node = [[NSClassFromString(self.nodeTypeNames[[result intValue]]) alloc] init];
            
            self.editor = NODE_EDITOR;
            self.selNode = self.nodeIndex = self.scene.root.childCount;
            
            [node setup:self.scene view:view];
            
            [self.scene.root addChild:node];
            [self populateNodeList];
            
            self.nodeIndex = self.scene.root.childCount - 1;
        }
        self.selNodeType = -2;
    } else if(self.editor == NODE_LIST) {
        [ui addRow:5];
        if((result = [ui list:@"Editor.node.list" gap:0 items:self.nodeList size:size selection:self.selNode])) {
            self.nodeIndex = [result intValue];
            self.editor = NODE_EDITOR;
            self.resetNodeEditor = YES;
        }
        self.selNode = -2;
    } else if(self.editor == SCENE_LIST) {
        [ui addRow:5];
        if((result = [ui list:@"Editor.scene.list" gap:0 items:self.sceneNames size:size selection:self.selSceneName])) {
            NSString* name = self.sceneNames[[result intValue]];
            
            self.sceneURL = [view.assets.baseURL URLByAppendingPathComponent:@"assets/scenes"];
            self.sceneURL = [self.sceneURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt", name]];
            
            self.scene = [Scene deserialize:self.sceneURL view:view inDesign:YES];
            self.editor = -1;

            [self populateNodeList];
        }
        self.selSceneName = -2;
    } else if(self.editor == NODE_EDITOR) {
        [ui addRow:5];
        [self.selection handleUI:self.scene view:view reset:self.resetNodeEditor];
        self.resetNodeEditor = NO;
    }
    [ui end];
    
    if(self.scene) {
        [self.scene.root updateWithScene:self.scene view:view];
        
        if([view isButtonDown:0]) {
            Vec3 offset = self.scene.camera.eye - self.scene.camera.target;
            Vec3 f = (self.scene.camera.target - self.scene.camera.eye) * Vec3Make(1, 0, 1);
            Vec3 r = Vec3Make(0, 0, 0);
            BOOL canMoveXZ = NO;
            
            if(Vec3Length(f) > 0.0000001) {
                r = Vec3Normalize(Vec3Cross(f, Vec3Make(0, 1, 0)));
                f = Vec3Normalize(f);
                canMoveXZ = YES;
            }
            
            if(self.mode == ZOOM) {
                offset = Vec3Normalize(offset) * (Vec3Length(offset) + view.deltaY);
                self.scene.camera.eye = self.scene.camera.target + offset;
            } else if(self.mode == ROT) {
                [self.scene.camera rotate:view];
            } else if(self.mode == PAN_XZ) {
                if(canMoveXZ) {
                    self.scene.camera.target = self.scene.camera.target + f * view.deltaY + r * view.deltaX;
                    self.scene.camera.eye = self.scene.camera.target + offset;
                }
            } else if(self.mode == PAN_Y) {
                self.scene.camera.target = self.scene.camera.target + Vec3Make(0, view.deltaY, 0);
                self.scene.camera.eye = self.scene.camera.target + offset;
            } else if(self.selection) {
                if(self.selection.transform) {
                    if(self.mode == MOV_XZ) {
                        if(canMoveXZ) {
                            self.selection.transform.position = self.selection.transform.position + f * view.deltaY + r * view.deltaX;
                        }
                    } else if(self.mode == MOV_Y) {
                        self.selection.transform.position = self.selection.transform.position + Vec3Make(0, view.deltaY, 0);
                    } else if(self.mode == ROT_Y) {
                        self.selection.transform.rotation = Mat4Mul(self.selection.transform.rotation, Mat4Rotate(view.deltaX, Vec3Make(0, 1, 0)));
                    }
                }
            }
            self.down = YES;
        } else {
            if(!self.down && self.selection && (self.mode == MOV_XZ || self.mode == MOV_Y)) {
                if(self.snap > 0 && self.selection.transform) {
                    Vec3 p = self.selection.transform.position;
                    
                    p.x = (int)roundf(p.x / self.snap) * self.snap;
                    p.y = (int)roundf(p.y / self.snap) * self.snap;
                    p.z = (int)roundf(p.z / self.snap) * self.snap;
                    
                    self.selection.transform.position = p;
                }
            }
            self.down = NO;
        }
    }
    return !quit;
}

- (void)tearDown {
    self.scene = nil;
    self.text = nil;
    self.nodeList = nil;
}

- (Node*)selection {
    if(self.nodeIndex != -1) {
        return self.nodeList[self.nodeIndex];
    }
    return nil;
}

- (void)populateNodeList {
    [self.nodeList removeAllObjects];
    
    self.nodeIndex = -1;
    
    if(self.scene) {
        for(int i = 0; i != self.scene.root.childCount; i++) {
            [self.nodeList addObject:[self.scene.root childAt:i]];
        }
    }
}

@end
