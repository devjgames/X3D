//
//  Sprite.h
//  X3D
//
//  Created by Douglas McNamara on 8/9/23.
//


@interface Sprite : XObject

@property (readonly) id<MTLTexture> texture;

- (id)initWithView:(MTLView*)view texture:(id<MTLTexture>)texture;
- (void)begin;
- (void)pushSrc:(NSRect)src dst:(NSRect)dst color:(Vec4)color;
- (void)pustText:(NSString*)text cw:(int)cw ch:(int)ch columns:(int)cols scale:(int)scale lineSpacing:(int)spacing location:(NSPoint)location color:(Vec4)color;
- (void)end;
- (void)encodeWithEncoder:(id<MTLRenderCommandEncoder>)encoder size:(NSSize)size;

@end
