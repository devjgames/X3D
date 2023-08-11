//
//  Test.m
//  X3D
//
//  Created by Douglas McNamara on 6/28/23.
//

#import <X3D/X3D.h>

@implementation Test

- (void)setup:(MTLView *)view {
}

- (void)nextFrame:(MTLView *)view {
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

@end

@implementation TestFramework

- (id)initWithWindow:(NSWindow *)window view:(MTLView *)view tests:(NSArray<Test *> *)tests {
    self = [super init];
    if(self) {
        self.view = view;
        self.view.clearColor = MTLClearColorMake(0.75f, 0.75f, 0.75f, 1);
        
        self.window = window;
        
        self.tests = tests;
        self.test = nil;
        
        if(tests.count) {
            self.test = tests[0];
            
            [self.test setup:view];
        }
        
        view.delegate = self;
    }
    return self;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
}

- (void)drawInMTKView:(MTKView *)view {
    static int index = 0;
    static BOOL fs = NO;
    static BOOL round = YES;
    static BOOL dark = NO;
    static BOOL smallFont = YES;
    
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

    [self.view.ui begin];
    
    [self.view.ui beginPanel:@"TestFramework.empty"];
    [self.view.ui endPanel];
    
    [self.view.ui beginPanel:@"TestFramework.panel"];
    if((result = [self.view.ui list:@"TestFramework.test.list" gap:0 items:self.tests size:NSMakeSize(250, 400) selection:index])) {
        
        [self.view.assets clear];
        
        if(self.test) {
            [self.test tearDown];
        }
        self.view.currentRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.75f, 0.75f, 0.75f, 1);
        self.view.fpsMouseEnabled = NO;
        self.test = self.tests[[result intValue]];
        
        [self.test setup:self.view];
    }
    index = -2;
    [self.view.ui addRow:5];
    if([self.view.ui button:@"TestFramework.full.screen.button" gap:0 caption:@"Full Screen" selected:fs]) {
        [self.window toggleFullScreen:nil];
        fs = !fs;
    }
    [self.view.ui addRow:5];
    if([self.view.ui button:@"TestFramework.round.button" gap:0 caption:@"Round" selected:round]) {
        round = !round;
        if(round) {
            self.view.ui.cornerRadius = 8;
        } else {
            self.view.ui.cornerRadius = 0;
        }
    }
    [self.view.ui addRow:5];
    if([self.view.ui button:@"TestFramework.dark.theme.button" gap:0 caption:@"Dark Theme" selected:dark]) {
        dark = !dark;
        if(dark) {
            self.view.ui.backgroundColor = [NSColor colorWithRed:0.15f green:0.15f blue:0.15f alpha:1];
            self.view.ui.foregroundColor = [NSColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:1];
            self.view.ui.selectionColor = [NSColor whiteColor];
            self.view.ui.windowColor = [NSColor colorWithRed:0.05f green:0.05f blue:0.05f alpha:1];
        } else {
            self.view.ui.backgroundColor = [NSColor grayColor];
            self.view.ui.foregroundColor = [NSColor blackColor];
            self.view.ui.selectionColor = [NSColor whiteColor];
            self.view.ui.windowColor = [NSColor darkGrayColor];
        }
    }
    [self.view.ui addRow:5];
    if([self.view.ui button:@"TestFramework.small.font.button" gap:0 caption:@"Small Font" selected:smallFont]) {
        smallFont = !smallFont;
        if(smallFont) {
            self.view.ui.borderWidth = 1;
            self.view.ui.font = [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightLight];
        } else {
            self.view.ui.borderWidth = 2;
            self.view.ui.font = [NSFont monospacedSystemFontOfSize:14 weight:NSFontWeightLight];
        }
    }
    [self.view.ui endPanel];
    
    NSSize size = [self.view.ui panelSize:@"TestFramework.panel"];

    [self.view.ui moveTo:NSMakePoint(0, 0)];
    [self.view.ui setView:self.view rightOf:NO panel:@"TestFramework.empty" gap:0 anchorBottomRight:NSMakeSize(size.width + 10, 5)];
    
    [self.view.ui setPanel:@"TestFramework.panel" rightOfView:self.view gap:5];
    
    if(self.test) {
        [self.test nextFrame:self.view];
    }
    
    [self.view tick];
}

- (void)tearDown {
    self.view.delegate = nil;
    
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

