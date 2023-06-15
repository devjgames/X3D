//
//  UIManager.h
//  X3D
//
//  Created by Douglas McNamara on 5/16/23.
//

@interface UIManager : XObject

@property (readonly, weak) NSWindow* window;
@property NSColor* foregroundColor;
@property NSColor* backgroundColor;
@property NSColor* selectionColor;
@property NSFont* font;
@property float cornerRadius;
@property float borderWidth;
@property float gap;

- (id)initWithWindow:(NSWindow*)window;
- (id)viewForKey:(NSString*)key;
- (id)addView:(NSView*)view forKey:(NSString*)key;
- (void)locate:(NSString*)key gap:(float)gap;
- (void)begin;
- (void)moveTo:(NSPoint)location;
- (void)moveRightOf:(NSString*)key gap:(float)gap;
- (void)addRow:(float)gap;
- (void)end;

@end

