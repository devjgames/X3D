//
//  Test.h
//  X3DTest
//
//  Created by Douglas McNamara on 5/16/23.
//

#import <X3D/X3D.h>

@interface Test : XObject

- (void)setup:(MTLView*)view;
- (void)nextFrame:(MTLView*)view;
- (void)handleUI:(UIManager*)ui reset:(BOOL)reset;
- (void)tearDown;

@end

#import "HelloWorld.h"
#import "Plot.h"
#import "Map.h"

