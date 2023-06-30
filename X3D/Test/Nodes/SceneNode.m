//
//  SceneNode.m
//  X3DTest
//
//  Created by Douglas McNamara on 6/29/23.
//

#import "SceneNode.h"

@interface SceneNode ()

@property NSString* path;
@property NSMutableArray* meshes;
@property int selMesh;
@property int editor;

- (void)load:(Scene*)scene view:(MTLView*)view;

@end

@implementation SceneNode

- (id)init {
    self = [super init];
    if(self) {
        self.path = nil;
    }
    return self;
}

- (void)setup:(Scene *)scene view:(MTLView *)view {
    [self load:scene view:view];
    
    if(scene.inDesign) {
        NSFileManager* manager = [NSFileManager defaultManager];
        NSURL* url = [view.assets.baseURL URLByAppendingPathComponent:@"assets/meshes"];
        NSArray* items = [manager contentsOfDirectoryAtPath:url.path error:nil];
    
        self.meshes = [NSMutableArray arrayWithCapacity:16];
        for(NSString* item in items) {
            NSString* extension = item.pathExtension;
            
            if([extension isEqualToString:@"obj"]) {
                [self.meshes addObject:[item.lastPathComponent stringByDeletingPathExtension]];
            }
        }
        self.selMesh = -1;
        self.editor = -1;
    }
}

- (void)onPreUpdateWithScene:(Scene *)scene view:(MTLView *)view {
    if(self.childCount > 1) {
        Node* node = [self childAt:1];
        
        node.position = scene.camera.target;
    }
}

- (void)handleUI:(Scene *)scene view:(MTLView *)view reset:(BOOL)reset {
    UIManager* ui = view.ui;
    id result;
    
    if(reset) {
        self.selMesh = self.editor = -1;
    }
    
    if([ui button:@"SceneNode.list.mesh.button" gap:0 caption:@"Meshes" selected:self.editor == 0]) {
        self.editor = 0;
        self.selMesh = -1;
    }
    if(self.editor == 0) {
        [ui addRow:5];
        if((result = [ui list:@"SceneNode.mesh.list" gap:0 items:self.meshes size:NSMakeSize(250, 300) selection:self.selMesh])) {
            self.path = [NSString stringWithFormat:@"assets/meshes/%@.obj", self.meshes[[result intValue]]];
            
            [self load:scene view:view];
            
            self.editor = -1;
        }
        self.selMesh = -2;
    }
}

- (Node*)transform {
    return nil;
}

- (NSString*)serialize:(Scene *)scene view:(MTLView *)view {
    if(self.path) {
        return self.path;
    }
    return @"";
}

- (void)deserialize:(Scene *)scene view:(MTLView *)view tokens:(NSArray<NSString *> *)tokens {
    if(tokens.count >= 3) {
        self.path = tokens[2];
    }
}

- (void)load:(Scene *)scene view:(MTLView *)view {
    if(self.childCount) {
        [self detachChildren];
    }
    if(self.path) {
        NSURL* url = [view.assets.baseURL URLByAppendingPathComponent:self.path];
        Node* node = [[[MeshLoader alloc] init] load:url assets:view.assets];
        
        for(int i = 0; i != node.childCount; i++) {
            Node* child = [node childAt:i];
            
            for(int j = 0; j != child.childCount; j++) {
                Mesh* mesh = [child childAt:j];
                
                mesh.basicEncodable.color = Vec4Make(0.5f, 0.5f, 0.5f, 1);
                
                BOOL skip = [mesh.name isEqualToString:@"torch"];
                
                mesh.collidable = !skip;
            }
        }
        [self addChild:node];
    }
    if(scene.inDesign) {
        NSURL* url = [view.assets.baseURL URLByAppendingPathComponent:@"assets/ui/ui.obj"];
        MeshLoader* loader = [[MeshLoader alloc] init];
        
        loader.center = NO;
        
        Node* node = [loader load:url assets:view.assets];
        
        node.position = scene.camera.target;
        node.scale = Vec3Make(1, 1, 1) * 2;
        
        [self addChild:node];
        
        node = node.lastChild;
        node = node.lastChild;
        node.basicEncodable.textureSampler = LINEAR_CLAMP_TO_EDGE;
    }
}

@end
