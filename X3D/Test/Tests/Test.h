//
//  Test.h
//  X3DTest
//
//  Created by Douglas McNamara on 5/16/23.
//

#import <X3D/X3D.h>

@interface Test : XObject

- (void)setup:(MTLView*)view;
- (BOOL)nextFrame:(MTLView*)view;
- (void)tearDown;

@end

#import "UIConfig.h"
#import "KeyFrameMeshTest.h"
#import "CollisionTest.h"
#import "FieldTest.h"

@interface TestFramework : NSObject

- (id)initWithWindow:(NSWindow*)window view:(MTLView*)view tests:(NSArray<Test*>*)tests;
- (void)tearDown;

@end

