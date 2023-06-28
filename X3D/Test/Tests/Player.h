//
//  CollisionTest.h
//  X3DTest
//
//  Created by Douglas McNamara on 6/13/23.
//

@interface Animator : XObject

- (void)setup:(MTLView*)view scene:(Scene*)scene node:(Node*)node lights:(NSMutableData*)lights;
- (void)animate:(MTLView*)view scene:(Scene*)scene node:(Node*)node;

@end

@interface Player : Test

- (id)initWithPath:(NSString*)path baseURL:(NSURL*)baseURL;

@end

