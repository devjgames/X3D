//
//  UIManager.h
//  X3D
//
//  Created by Douglas McNamara on 5/16/23.
//

@interface UIPanel : NSView

@end

@interface UIView : NSView

@end

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
- (id)addView:(UIView*)view forKey:(NSString*)key;
- (void)locate:(NSString*)key gap:(float)gap;
- (void)begin;
- (void)moveTo:(NSPoint)location;
- (void)addRow:(float)gap;
- (void)beginPanel:(NSString*)key;
- (void)endPanel;
- (NSSize)panelSize:(NSString*)key;
- (void)setPanel:(NSString*)key rightOfView:(MTLView*)view gap:(float)gap;
- (void)setPanel:(NSString*)key belowView:(MTLView*)view gap:(float)gap;
- (BOOL)panelIsHidden:(NSString*)key;
- (void)setView:(MTLView*)view rightOf:(BOOL)rightOf panel:(NSString*)key gap:(float)gap anchorBottomRight:(NSSize)anchor;
- (void)end;
- (void)setWindowColor:(NSColor *)color;

@end

