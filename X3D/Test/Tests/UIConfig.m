//
//  UIConfig.m
//  X3DTest
//
//  Created by Douglas McNamara on 5/16/23.
//

#import "Test.h"

@implementation UIConfig

- (void)setup:(MTLView *)view {
    view.clearColor = MTLClearColorMake(0.2f, 0.2f, 0.2f, 1);
}

- (BOOL)nextFrame:(MTLView *)view {
    static BOOL round = YES;
    static BOOL dark = NO;
    static BOOL smallFont = YES;
    
    BOOL quit = NO;

    id<CAMetalDrawable> drawable = [view currentDrawable];
    
    if(drawable) {
        id<MTLCommandBuffer> commandBuffer = [view.commandQueue commandBuffer];
        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:view.currentRenderPassDescriptor];
        
        [encoder setViewport:(MTLViewport){ 0, 0, view.width, view.height, 0, 1 }];
        [encoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
    }

    [view.ui begin];
    [view.ui beginPanel:@"UIConfig.panel"];
    if([view.ui button:@"UIConfig.round.button" gap:0 caption:@"Round" selected:round]) {
        round = !round;
        if(round) {
            view.ui.cornerRadius = 8;
        } else {
            view.ui.cornerRadius = 0;
        }
    }
    if([view.ui button:@"UIConfig.dark.theme.button" gap:5 caption:@"Dark Theme" selected:dark]) {
        dark = !dark;
        if(dark) {
            view.ui.backgroundColor = [NSColor blackColor];
            view.ui.foregroundColor = [NSColor whiteColor];
            view.ui.selectionColor = [NSColor orangeColor];
            view.ui.windowColor = view.ui.backgroundColor;
        } else {
            view.ui.backgroundColor = [NSColor grayColor];
            view.ui.foregroundColor = [NSColor blackColor];
            view.ui.selectionColor = [NSColor whiteColor];
            view.ui.windowColor = [NSColor darkGrayColor];
        }
    }
    if([view.ui button:@"UIConfig.small.font.button" gap:5 caption:@"Small Font" selected:smallFont]) {
        smallFont = !smallFont;
        if(smallFont) {
            view.ui.borderWidth = 1;
            view.ui.font = [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightLight];
        } else {
            view.ui.borderWidth = 2;
            view.ui.font = [NSFont monospacedSystemFontOfSize:14 weight:NSFontWeightLight];
        }
    }
    if([view.ui button:@"UIConfig.quit.button" gap:5 caption:@"Quit" selected:NO]) {
        quit = YES;
    }
    [view.ui endPanel];
    
    [view.ui setView:view rightOf:NO panel:@"UIConfig.panel" gap:5 anchorBottomRight:NSMakeSize(5, 5)];
    
    [view.ui end];
    
    return !quit;
}

@end
