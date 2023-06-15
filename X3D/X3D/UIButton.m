//
//  UIButton.m
//  X3D
//
//  Created by Douglas McNamara on 5/16/23.
//

#import <X3D/X3D.h>

@interface UIButton : NSView

@property (readonly, weak) UIManager* manager;
@property (readonly) NSTextField* field;
@property (readonly) BOOL changed;
@property (readonly) BOOL down;

- (id)initWithManager:(UIManager*)manager caption:(NSString*)caption;
- (BOOL)clicked;

@end

@implementation UIButton

- (id)initWithManager:(UIManager *)manager caption:(NSString *)caption {
    self = [super initWithFrame:NSMakeRect(0, 0, 0, 0)];
    if(self) {
        self.wantsLayer = YES;
        _manager = manager;
        _changed = NO;
        _down = NO;
        
        _field = [NSTextField textFieldWithString:caption];
        _field.drawsBackground = NO;
        _field.editable = NO;
        _field.selectable = NO;
        _field.bordered = NO;
        
        [self addSubview:_field];
        [manager.window.contentView addSubview:self];
    }
    return self;
}

- (BOOL)clicked {
    BOOL c = self.changed;
    
    _changed = NO;
    
    return c;
}

- (BOOL)canBecomeKeyView {
    return YES;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    return YES;
}

- (NSPoint)mouseLocation {
    return [self.window convertPointFromScreen:NSEvent.mouseLocation];
}

- (void)mouseDown:(NSEvent *)event {
    if([self hitTest:self.mouseLocation]) {
        _down = YES;
    }
}

- (void)mouseUp:(NSEvent *)event {
    if([self hitTest:self.mouseLocation]) {
        _changed = YES;
    }
    _down = NO;
}

@end

@implementation UIManager (UIButton)

- (BOOL)button:(NSString *)key gap:(float)gap caption:(NSString *)caption selected:(BOOL)selected {
    UIButton* button = [self viewForKey:key];
    
    if(button == nil) {
        button = [self addView:[[UIButton alloc] initWithManager:self caption:caption] forKey:key];
    }
    button.field.font = self.font;
    [button.field sizeToFit];
    
    button.frame = NSMakeRect(0, 0, button.field.frame.size.width + self.gap * 2, button.field.frame.size.height + self.gap * 2);
    button.field.frame = NSMakeRect(self.gap, self.gap, button.field.frame.size.width, button.field.frame.size.height);
    
    [self locate:key gap:gap];
    
    NSColor* color = nil;
    
    if(selected) {
        color = (button.down) ? self.foregroundColor : self.selectionColor;
    } else {
        color = (button.down) ? self.selectionColor : self.foregroundColor;
    }
    button.field.textColor = color;
    button.layer.borderColor = color.CGColor;
    button.layer.backgroundColor = self.backgroundColor.CGColor;
    button.layer.cornerRadius = self.cornerRadius;
    button.layer.borderWidth = self.borderWidth;
    
    [button.layer setNeedsDisplay];
    
    return button.clicked;
}

@end
