//
//  UIConfig.m
//  X3DTest
//
//  Created by Douglas McNamara on 5/16/23.
//

#import "Test.h"

@implementation UIConfig

- (void)setup:(MTLView *)view {
    view.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2f, 0.2f, 0.2f, 1);
}

- (BOOL)nextFrame:(MTLView *)view {
    static BOOL round = YES;
    static BOOL invertColors = NO;
    static BOOL smallFont = YES;
    
    BOOL quit = NO;
    
    id<CAMetalDrawable> drawable = [view.metalLayer nextDrawable];
    
    if(drawable) {
        view.renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
        
        id<MTLCommandBuffer> commandBuffer = [view.commandQueue commandBuffer];
        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:view.renderPassDescriptor];
        
        [encoder setViewport:(MTLViewport){ 0, 0, view.width, view.height, 0, 1 }];
        [encoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
    }

    [view.ui begin];
    if([view.ui button:@"UIConfig.round.button" gap:0 caption:@"Round" selected:round]) {
        round = !round;
        if(round) {
            view.ui.cornerRadius = 8;
        } else {
            view.ui.cornerRadius = 0;
        }
    }
    if([view.ui button:@"UIConfig.invert.colors.button" gap:5 caption:@"Invert Colors" selected:invertColors]) {
        NSColor* color = view.ui.backgroundColor;
        
        view.ui.backgroundColor = view.ui.foregroundColor;
        view.ui.foregroundColor = color;
        
        invertColors = !invertColors;
    }
    if([view.ui button:@"UIConfig.small.font.button" gap:5 caption:@"Small Font" selected:smallFont]) {
        smallFont = !smallFont;
        if(smallFont) {
            view.ui.borderWidth = 1;
            view.ui.font = [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightLight];
        } else {
            view.ui.borderWidth = 2;
            view.ui.font = [NSFont monospacedSystemFontOfSize:14 weight:NSFontWeightLight];
        }
    }
    if([view.ui button:@"UIConfig.quit.button" gap:5 caption:@"Quit" selected:NO]) {
        quit = YES;
    }
    [view.ui end];
    
    return !quit;
}

@end
