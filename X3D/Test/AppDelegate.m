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
@property UIManager* ui;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    [NSApp activateIgnoringOtherApps:YES];
    
    MTLView* view = [[MTLView alloc] initWithView:self.window.contentView device:MTLCreateSystemDefaultDevice()];
    
    self.view = view;
    self.view.clearColor = MTLClearColorMake(0.75f, 0.75f, 0.75f, 1);

    self.tests = @[
        [[HelloWorld alloc] init],
        [[Plot alloc] init],
        [[Map alloc] initWithPath:@"assets/maps/map1.obj" position:Vec3Make(0, 64, 0) direction:Vec2Make(1, -1) ambientColor:Vec4Make(0.7f, 0.7f, 0.7f, 1)]
    ];

    if(self.tests.count) {
        self.test = self.tests[0];
        
        [self.test setup:view];
    }
    
    self.window.backgroundColor = NSColor.darkGrayColor;
    
    self.ui = [[UIManager alloc] init];
    
    view.delegate = self;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    
    self.view.delegate = nil;
    
    Log(@"%i instance(s)", XObject.instances);
    
    self.tests = nil;
    if(self.test) {
        [self.test tearDown];
    }
    self.test = nil;
    
    self.ui = nil;
    
    [self.view tearDown];
    
    Log(@"%i instance(s)", XObject.instances);
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
}

- (void)drawInMTKView:(MTKView *)view {
    static int index = 0;
    static BOOL fs = NO;
    static BOOL reset = YES;
    
    id result;
    
    if(!self.test) {
        
        id<CAMetalDrawable> drawable = [self.view currentDrawable];
        
        if(drawable) {
            self.view.currentRenderPassDescriptor.colorAttachments[0].texture = drawable.texture;
            
            id<MTLCommandBuffer> commandBuffer = [self.view.commandQueue commandBuffer];
            id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:self.view.currentRenderPassDescriptor];
            
            [encoder setViewport:(MTLViewport){ 0, 0, self.view.width, self.view.height, 0, 1 }];
            [encoder endEncoding];
            [commandBuffer presentDrawable:drawable];
            [commandBuffer commit];
            [commandBuffer waitUntilCompleted];
        }
    }

    [self.ui begin];
    if((result = [self.ui list:@"app.test.list" gap:0 items:self.tests size:NSMakeSize(250, 200) selection:index])) {
        
        [self.view.assets clear];
        
        if(self.test) {
            [self.test tearDown];
        }
        self.view.currentRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.75f, 0.75f, 0.75f, 1);
        self.view.fpsMouseEnabled = NO;
        self.test = self.tests[[result intValue]];
        
        [self.test setup:self.view];
        
        reset = YES;
    }
    index = -2;
    [self.ui addRow:5];
    if([self.ui button:@"app.full.screen.button" gap:0 caption:@"Full Screen" selected:fs]) {
        [self.window toggleFullScreen:nil];
        fs = !fs;
    }
    if(self.test) {
        [self.test handleUI:self.ui reset:reset];
        
        reset = NO;
    }
    [self.ui end];
    
    [UIManager layout:5 center:self.view north:nil south:nil east:self.ui.panel west:nil];
    
    if(self.test) {
        [self.test nextFrame:self.view];
    }
    
    [self.view tick];
}

@end
