//
//  Test.h
//  X3D
//
//  Created by Douglas McNamara on 6/28/23.
//

@interface Test : XObject

- (void)setup:(MTLView*)view;
- (void)nextFrame:(MTLView*)view;
- (void)tearDown;

@end

@interface TestFramework : NSObject <MTKViewDelegate>

- (id)initWithWindow:(NSWindow*)window view:(MTLView*)view tests:(NSArray<Test*>*)tests;
- (void)tearDown;

@end

