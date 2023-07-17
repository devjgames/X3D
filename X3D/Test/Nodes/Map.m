//
//  Map.m
//  X3DTest
//
//  Created by Douglas McNamara on 6/29/23.
//

#import "Map.h"
#import "ScenePlayer.h"

@interface Map ()

@property NSString* path;
@property NSMutableArray* meshes;
@property int selMesh;
@property int editor;
@property MeshLoader* loader;
@property int selLight;
@property int lightIndex;
@property NSMutableArray* lights;
@property BOOL resetLightEditor;

- (void)load:(Scene*)scene view:(MTLView*)view;
- (void)populateLights;
- (Node*)loadUI:(MTLView*)view;

@end

@implementation Map

- (id)init {
    self = [super init];
    if(self) {
        self.path = nil;
        self.loader = [[MeshLoader alloc] init];
        
        [self addChild:[[Node alloc] init]];
        [self addChild:[[Node alloc] init]];
        [self addChild:[[Node alloc] init]];
        [self addChild:[[Node alloc] init]];
    }
    return self;
}

- (Node*)transform {
    if(self.lightIndex == -1) {
        return nil;
    }
    return [[self childAt:2] childAt:self.lightIndex];
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
        self.resetLightEditor = NO;

        self.lights = [NSMutableArray arrayWithCapacity:16];
        
        [self populateLights];
    }
    srand(1000);
}

- (void)onPreUpdateWithScene:(Scene *)scene view:(MTLView *)view {
    if(scene.inDesign) {
        Node* node = [self childAt:1];
        
        node.position = scene.camera.target;
    }
    
    Node* torches = [self childAt:3];
    
    for(int i = 0; i != torches.childCount; i++) {
        ParticleSystem* particles = [torches childAt:i];
        Particle p;
        float ss = 4 + rand() / (float)RAND_MAX * 8;
        float es = 1 + rand() / (float)RAND_MAX * 2;
        float sc = 0.05f + rand() / (float)RAND_MAX * 0.1f;
        float ec = 0;
        
        p.velocity = Vec3Make(0, 6 + rand() / (float)RAND_MAX * 12, 0);
        p.startPosition = Vec3Make(-2 + rand() / (float)RAND_MAX * 4, 0, -2 + rand() / (float)RAND_MAX * 4);
        p.position = p.startPosition;
        p.time = view.totalTime;
        p.lifeSpan = 0.5f + rand() / (float)RAND_MAX * 2;
        p.startSize = Vec2Make(ss, ss);
        p.endSize = Vec2Make(es, es);
        p.size = p.startSize;
        p.startColor = Vec4Make(sc, sc, sc, 1);
        p.endColor = Vec4Make(ec, ec, ec, 1);
        p.color = p.startColor;
        
        [particles emit:&p];
    }
}

- (void)handleUI:(Scene *)scene view:(MTLView *)view reset:(BOOL)reset {
    UIManager* ui = view.ui;
    id result;
    
    if(reset) {
        self.selMesh = self.editor = self.selLight = self.lightIndex -1;
        self.resetLightEditor = YES;
    }
    
    if([ui button:@"SceneNode.list.mesh.button" gap:0 caption:@"Meshes" selected:self.editor == 0]) {
        self.editor = 0;
        self.selMesh = -1;
    }
    [ui addRow:5];
    if([ui button:@"SceneNode.list.lights.button" gap:0 caption:@"Lights" selected:self.editor == 1]) {
        self.editor = 1;
        self.selLight = self.lightIndex;
    }
    if([ui button:@"SceneNode.add.light.button" gap:5 caption:@"+Light" selected:false]) {
        Node* light = [[Node alloc] init];
        Node* lights = [self childAt:2];
        int index = lights.childCount;
        
        light.isLight = YES;
        light.name = @"Light";
        
        [[self childAt:2] addChild:light];
        
        [self populateLights];
        
        [light addChild:[self loadUI:view]];
        
        self.lightIndex = index;
        self.editor = 2;
        
        self.resetLightEditor = YES;
    }
    [ui addRow:5];
    if([ui button:@"SceneNode.map.button" gap:0 caption:@"Map" selected:NO]) {
        [[[LightMapper alloc] init] map:scene view:view url:[Editor instance].sceneURL rebuild:YES];
    }
    if([ui button:@"SceneNode.clear.map.button" gap:5 caption:@"Clear Map" selected:NO]) {
        Node* node = [self childAt:0];
        
        node = [node childAt:0];
        for(int i = 0; i != node.childCount; i++) {
            Node* child = [node childAt:i];
            
            for(int j = 0; j != child.childCount; j++) {
                Node* node = [child childAt:j];
                
                node.basicEncodable.texture2 = nil;
            }
        }
    }
    if(self.editor == 0) {
        [ui addRow:5];
        if((result = [ui list:@"SceneNode.mesh.list" gap:0 items:self.meshes size:NSMakeSize(250, 300) selection:self.selMesh])) {
            self.path = [NSString stringWithFormat:@"assets/meshes/%@.obj", self.meshes[[result intValue]]];
            
            [self load:scene view:view];
            
            self.editor = -1;
        }
        self.selMesh = -2;
    } else if(self.editor == 1) {
        [ui addRow:5];
        if((result = [ui list:@"SceneNode.light.list" gap:0 items:self.lights size:NSMakeSize(250, 300) selection:self.selLight])) {
            self.lightIndex = [result intValue];
            self.editor = 2;
            
            self.resetLightEditor = YES;
        }
        self.selLight =  -2;
    } else if(self.editor == 2) {
        Node* light = self.transform;
        Vec4 c = light.lightColor;
        float r = light.lightRadius;
        
        [ui addRow:5];
        [ui field:@"SceneNode.light.color.field" gap:0 caption:@"L Color" vec4Value:&c width:100 reset:self.resetLightEditor];
        [ui addRow:5];
        [ui field:@"SceneNode.light.radius.field" gap:0 caption:@"L Radius" floatValue:&r width:50 reset:self.resetLightEditor];
        
        light.lightColor = c;
        light.lightRadius = r;
        
        [ui addRow:5];
        if([ui button:@"SceneNode.light.del.button" gap:0 caption:@"-Light" selected:NO]) {
            [light detach];
            
            [self populateLights];
            
            self.editor = -1;
        }
        self.resetLightEditor = NO;
    }
}

- (NSString*)serialize:(Scene *)scene view:(MTLView *)view {
    NSMutableString* s = [NSMutableString stringWithCapacity:1000];
    
    if(self.path) {
        [s appendString:self.path];
    } else {
        [s appendString:@"@"];
    }
    Node* lights = [self childAt:2];
    
    [s appendFormat:@" %i %i %@ %@ %@ %i",
     scene.lightMapWidth,
     scene.lightMapHeight,
     [NSNumber numberWithFloat:scene.aoStrength],
     [NSNumber numberWithFloat:scene.aoLength],
     [NSNumber numberWithFloat:scene.sampleRadius],
     scene.sampleCount
    ];
    
    for(int i = 0; i != lights.childCount; i++) {
        Node* light = [lights childAt:i];
        Vec3 p = light.position;
        Vec4 c = light.lightColor;
        float r = light.lightRadius;
        
        [s appendFormat:@" L:%@:%@:%@:%@:%@:%@:%@:%@",
         [NSNumber numberWithFloat:p.x],
         [NSNumber numberWithFloat:p.y],
         [NSNumber numberWithFloat:p.z],
         [NSNumber numberWithFloat:c.x],
         [NSNumber numberWithFloat:c.y],
         [NSNumber numberWithFloat:c.z],
         [NSNumber numberWithFloat:c.w],
         [NSNumber numberWithFloat:r]
        ];
    }
    return s;
}

- (void)deserialize:(Scene *)scene view:(MTLView *)view tokens:(NSArray<NSString *> *)tokens {
    if([tokens[2] isEqualToString:@"@"]) {
        self.path = nil;
    } else {
        self.path = tokens[2];
    }
    
    Node* lights = [self childAt:2];
    
    scene.lightMapWidth = [tokens[3] intValue];
    scene.lightMapHeight = [tokens[4] intValue];
    scene.aoStrength = [tokens[5] floatValue];
    scene.aoLength = [tokens[6] floatValue];
    scene.sampleRadius = [tokens[7] floatValue];
    scene.sampleCount = [tokens[8] intValue];
    
    for(int i = 9; i != (int)tokens.count; i++) {
        NSArray<NSString*>* tokens2 = [Parser split:tokens[i] delims:[NSCharacterSet characterSetWithCharactersInString:@":"]];
        
        if([tokens2[0] isEqualToString:@"L"]) {
            Node* light = [[Node alloc] init];
            
            light.isLight = YES;
            light.position = Vec3Make([tokens2[1] floatValue],
                                      [tokens2[2] floatValue],
                                      [tokens2[3] floatValue]
                                      );
            light.lightColor = Vec4Make([tokens2[4] floatValue],
                                        [tokens2[5] floatValue],
                                        [tokens2[6] floatValue],
                                        [tokens2[7] floatValue]
                                        );
            light.lightRadius = [tokens2[8] floatValue];
            light.name = @"Light";
            
            [lights addChild:light];
            
            if(scene.inDesign) {
                [light addChild:[self loadUI:view]];
            }
        }
    }
}

- (void)load:(Scene *)scene view:(MTLView *)view {
    [[self childAt:0] detachChildren];
    [[self childAt:1] detachChildren];
    [[self childAt:3] detachChildren];
    
    if(self.path) {
        NSURL* url = [view.assets.baseURL URLByAppendingPathComponent:self.path];
        
        self.loader.center = YES;
        
        Node* node = [self.loader load:url assets:view.assets];
        
        [node calcTransform];
        
        for(int i = 0; i != node.childCount; i++) {
            Node* child = [node childAt:i];
            
            for(int j = 0; j != child.childCount; j++) {
                Mesh* mesh = [child childAt:j];
                
                mesh.basicEncodable.ambientColor = Vec4Make(0.2f, 0.2f, 0.2f, 1);
                mesh.lightMapEnabled = YES;
                mesh.castsShadow = YES;
                
                BOOL skip = [mesh.name isEqualToString:@"torch"];
                
                mesh.collidable = !skip;
                
                if(skip) {
                    for(int i = 0; i != mesh.faceCount; i++) {
                        BasicVertex v = [mesh vertexAt:[mesh face:i vertexAt:0]];
                        
                        if(v.normal.y > 0.9f) {
                            ParticleSystem* particles = [[ParticleSystem alloc] initWithView:view maxParticles:200];
                            
                            particles.zOrder = 10;
                            particles.basicEncodable.depthWriteEnabled = NO;
                            particles.basicEncodable.blendEnabled = YES;
                            particles.basicEncodable.additiveBlend = YES;
                            particles.basicEncodable.vertexColorEnabled = YES;
                            particles.basicEncodable.texture = [view.assets load:@"assets/particles/fire.png"];
                            particles.basicEncodable.textureSampler = LINEAR_CLAMP_TO_EDGE;
                            
                            [particles.basicEncodable createDepthAndPipelineState];
                            
                            BoundingBox b = BoundingBoxEmpty();
                            
                            for(int j = 0; j != [mesh faceVertexCountAt:i]; j++) {
                                v = [mesh vertexAt:[mesh face:i vertexAt:j]];
                                b = BoundingBoxAddPoint(b, Vec3Transform(mesh.model, v.position));
                            }
                            
                            particles.position = BoundingBoxCalcCenter(b);
                            
                            [[self childAt:3] addChild:particles];
                        }
                    }
                }
            }
        }
        [[self childAt:0] addChild:node];
    }
    if(scene.inDesign) {
        Node* parent = [self childAt:1];
        Node* ui = [self loadUI:view];
        
        parent.position = scene.camera.target;
 
        [[self childAt:1] addChild:ui];
        
        [[[LightMapper alloc] init] map:scene view:view url:[Editor instance].sceneURL rebuild:NO];
    } else {
        [[[LightMapper alloc] init] map:scene view:view url:[ScenePlayer instance].url rebuild:NO];
    }
}

- (void)populateLights {
    [self.lights removeAllObjects];
    
    self.lightIndex = -1;
    self.selLight = -1;
    
    Node* lights = [self childAt:2];
    
    for(int i = 0; i != lights.childCount; i++) {
        [self.lights addObject:[lights childAt:i]];
    }
}

- (Node*)loadUI:(MTLView *)view {
    Log(@"Loading SceneNode UI ...");
    
    NSURL* url = [view.assets.baseURL URLByAppendingPathComponent:@"assets/ui/ui.obj"];
    
    self.loader.center = NO;
    
    Node* ui = [self.loader load:url assets:view.assets];
    Node* node = ui.lastChild;
    
    node = node.lastChild;
    node.basicEncodable.textureSampler = LINEAR_CLAMP_TO_EDGE;
    
    return ui;
}

@end
