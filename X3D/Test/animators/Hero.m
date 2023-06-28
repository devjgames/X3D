//
//  Hero.m
//  X3DTest
//
//  Created by Douglas McNamara on 6/28/23.
//

#import "Hero.h"

@implementation Hero

- (void)setup:(MTLView *)view scene:(Scene *)scene node:(Node *)node lights:(NSMutableData *)lights {
    Light l[] = {
        { node.position + Vec3Make(50, 50, 50), { 2, 1, 0, 1 }, 200 },
        { node.position - Vec3Make(50, 50, 50), { 0, 1, 2, 1 }, 200 },
    };
    
    [lights appendBytes:l length:sizeof(l)];
    
    node = [node childAt:0];
    node.basicEncodable.lightingEnabled = YES;
    node.basicEncodable.ambientColor = Vec4Make(0.5f, 0.5f, 0.5f, 1);
}

- (void)animate:(MTLView *)view scene:(Scene *)scene node:(Node *)node {
    [scene.camera rotate:view];
}

@end
