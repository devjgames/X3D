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

@property (readonly) UIPanel* panel;
@property NSColor* foregroundColor;
@property NSColor* backgroundColor;
@property NSColor* selectionColor;
@property NSFont* font;
@property float cornerRadius;
@property float borderWidth;
@property float gap;

- (id)viewForKey:(NSString*)key;
- (id)addView:(UIView*)view forKey:(NSString*)key;
- (void)locate:(NSString*)key gap:(float)gap;
- (void)begin;
- (void)moveRightOf:(NSString*)key gap:(float)gap;
- (void)addRow:(float)gap;
- (void)end;

+ (void)layout:(float)gap center:(NSView*)center north:(NSView*)north south:(NSView*)south east:(NSView*)east west:(NSView*)west;

@end

