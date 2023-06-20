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
