//
//  Test.m
//  X3DTest
//
//  Created by Douglas McNamara on 5/16/23.
//

#import "Test.h"

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
