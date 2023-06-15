//
//  AppDelegate.m
//  X3DTest
//
//  Created by Douglas McNamara on 5/15/23.
//

#import "AppDelegate.h"
#import "Test.h"

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;
@property (weak) MTLView* view;
@property NSArray<Test*>* tests;
@property Test* test;
@property (weak) NSTimer* timer;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    MTLView* view = [[MTLView alloc] initWithWindow:self.window];
    
    self.view = view;
    self.view.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2f, 0.2f, 0.2f, 1);
    
    self.tests = @[
        [[UIConfig alloc] init],
        [[KeyFrameMeshTest alloc] init],
        [[LightMapperTest alloc] init],
        [[CollisionTest alloc] init],
        [[FieldTest alloc] init]
    ];
    self.test = nil;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 / 60.0 target:self selector:@selector(nextFrame) userInfo:nil repeats:YES];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    
    [self.timer invalidate];
    
    Log(@"%i instance(s)", XObject.instances);
    
    self.tests = nil;
    if(self.test) {
        [self.test tearDown];
    }
    self.test = nil;
    
    [self.view destroy];
    
    Log(@"%i instance(s)", XObject.instances);
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (void)nextFrame {
    static int index = -1;
    
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

@end
