//
//  NPC.m
//  X3DTest
//
//  Created by Douglas McNamara on 7/16/23.
//

#import "NPC.h"

@interface NPC ()

@property NSMutableArray<NSString*>* meshNames;
@property int selMesh;
@property int meshIndex;
@property NSString* path;

- (void)loadMesh:(MTLView*)view;

@end

@implementation NPC

- (id)init {
    self = [super init];
    if(self) {
        self.meshNames = [NSMutableArray arrayWithCapacity:16];
        self.selMesh = -2;
        self.meshIndex = -1;
        self.path = @"@";
        
        NSArray* items = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSBundle.mainBundle.resourceURL.path stringByAppendingPathComponent:@"assets/md2"] error:nil];
        
        for(NSString* item in items) {
            if([item.pathExtension isEqualToString:@"md2"]) {
                [self.meshNames addObject:[item.lastPathComponent stringByDeletingPathExtension]];
            }
        }
        [self.meshNames sortUsingSelector:@selector(compare:)];
    }
    return self;
}

- (void)handleUI:(Scene *)scene view:(MTLView *)view reset:(BOOL)reset {
    if(reset) {
        self.selMesh = self.meshIndex;
    }
    
    id result;
    
    if((result = [view.ui list:@"NPC.mesh.list" gap:0 items:self.meshNames size:NSMakeSize(200, 200) selection:self.selMesh])) {
        NSString* name = self.meshNames[[result intValue]];
        
        self.path = @"assets/md2";
        self.path = [[self.path stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"md2"];
        
        [self loadMesh:view];
    }
    self.selMesh = -2;
}

- (NSString*)serialize:(Scene *)scene view:(MTLView *)view {
    Vec4 f = self.rotation.columns[2];
    
    return [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@",
            [NSNumber numberWithFloat:self.position.x],
            [NSNumber numberWithFloat:self.position.y],
            [NSNumber numberWithFloat:self.position.z],
            [NSNumber numberWithFloat:f.x],
            [NSNumber numberWithFloat:f.z],
            self.path];
}

- (void)deserialize:(Scene *)scene view:(MTLView *)view tokens:(NSArray<NSString *> *)tokens {
    Vec3 u = Vec3Make(0, 1, 0);
    Vec3 f = Vec3Normalize(Vec3Make(tokens[5].floatValue, 0, tokens[6].floatValue));
    Vec3 r = Vec3Normalize(Vec3Cross(u, f));
    
    self.position = Vec3Make(tokens[2].floatValue, tokens[3].floatValue, tokens[4].floatValue);
    self.rotation = Mat4Make(r.x, u.x, f.x, 0,
                             r.y, u.y, f.y, 0,
                             r.z, u.z, f.z, 0,
                             0, 0, 0,1
                             );
    
    self.path = tokens[7];

    [self loadMesh:view];
}

- (void)loadMesh:(MTLView *)view {
    [self detachChildren];
    
    if(![self.path isEqualToString:@"@"]) {
        KeyFrameMesh* mesh = [view.assets load:self.path];
        NSString* name = [self.path.lastPathComponent stringByDeletingPathExtension];
        NSString* texPath = [[self.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", name]];
        NSUInteger i = [self.meshNames indexOfObject:name];
        
        if(i == NSNotFound) {
            self.meshIndex = -1;
        } else {
            self.meshIndex = (int)i;
        }
        
        mesh = [[KeyFrameMesh alloc] initWithKeyFrameMesh:mesh];
        mesh.basicEncodable.texture = [view.assets load:texPath];
        mesh.basicEncodable.lightingEnabled = YES;
        mesh.basicEncodable.ambientColor = Vec4Make(0.2f, 0.2f, 0.6f, 1);
        mesh.rotation = Mat4Rotate(-90, Vec3Make(1, 0, 0));
        mesh.position = Vec3Make(0, -[mesh frameBoundsAt:0].min.z, 0);
        [mesh setSequenceStart:0 end:39 speed:10 looping:YES];
        
        [self addChild:mesh];
    }
}

@end
