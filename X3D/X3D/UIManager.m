//
//  UIManager.m
//  X3D
//
//  Created by Douglas McNamara on 5/16/23.
//

#import <X3D/X3D.h>

@implementation UIView

@end

@implementation UIPanel

- (BOOL)isOpaque {
    return NO;
}

- (BOOL)isFlipped {
    return YES;
}

@end

@interface UIManager ()

@property (readonly) NSMutableDictionary<NSString*, UIView*>* keyedViews;
@property (readonly) NSMutableDictionary<NSString*, UIPanel*>* keyedPanels;
@property (readonly) NSMutableArray<NSView*>* views;
@property (readonly) NSPoint location;
@property (readonly) float startX;
@property (readonly) float maxH;
@property (readonly) NSPoint saveLocation;
@property (readonly) float saveStartX;
@property (readonly) float saveMaxH;
@property (readonly) UIPanel* panel;

@end

@implementation UIManager

- (id)initWithWindow:(NSWindow*)window {
    self = [super init];
    if(self) {
        _window = window;
        
        self.backgroundColor = NSColor.grayColor;
        self.foregroundColor = NSColor.blackColor;
        self.selectionColor = NSColor.whiteColor;
        self.font = [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightLight];
        self.borderWidth = 1;
        self.cornerRadius = 8;
        self.gap = 10;
        
        _panel = nil;
        
        _keyedViews = [NSMutableDictionary dictionaryWithCapacity:100];
        _keyedPanels = [NSMutableDictionary dictionaryWithCapacity:8];
        _views = [NSMutableArray arrayWithCapacity:100];
        _location = NSMakePoint(0, 0);
        _startX = 0;
        _maxH = 0;
        _saveLocation = _location;
        _saveStartX = _startX;
        _saveMaxH = _maxH;
        
        [self setWindowColor:[NSColor darkGrayColor]];
    }
    return self;
}

- (id)viewForKey:(NSString*)key {
    return [_keyedViews objectForKey:key];
}

- (id)addView:(UIView*)view forKey:(NSString*)key {
    if(view.superview) {
        [view removeFromSuperview];
    }
    if(_panel) {
        [_panel addSubview:view];
    } else {
        [self.window.contentView addSubview:view];
    }
    [_keyedViews setObject:view forKey:key];
    
    return view;
}

- (void)locate:(NSString*)key gap:(float)gap {
    NSView* view = [self.keyedViews objectForKey:key];
    NSRect frame = view.frame;
    
    _location.x += gap;
    frame.origin = _location;
    
    _location.x += frame.size.width;
    _maxH = MAX(frame.size.height, _maxH);
    
    view.frame = frame;

    if(view.isHidden) {
        [view setHidden:NO];
    }

    [_views removeObject:view];
}

- (void)begin {
    _location.x = 5;
    _location.y = 5;
    _maxH = 0;
    _startX = _location.x;
    
    _panel = nil;
    
    [self.views addObjectsFromArray:self.keyedPanels.allValues];
    [self.views addObjectsFromArray:self.keyedViews.allValues];
}

- (void)moveTo:(NSPoint)location {
    _location = location;
    _maxH = 0;
    _startX = location.x;
}

- (void)addRow:(float)gap {
    _location.y += gap + _maxH;
    _location.x = _startX;
    _maxH = 0;
}

- (void)beginPanel:(NSString *)key {
    _panel = [self.keyedPanels objectForKeyedSubscript:key];
    
    _saveLocation = _location;
    _saveStartX = _startX;
    _saveMaxH = _maxH;
    
    _location = NSMakePoint(0, 0);
    _startX = 0;
    _maxH = 0;
    
    if(_panel == nil) {
        [self.keyedPanels setObject:_panel = [[UIPanel alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)] forKey:key];
        [self.window.contentView addSubview:_panel];
    }
}

- (void)endPanel {
    NSRect frame = NSMakeRect(0, 0, 0, 0);
    
    for(NSView* view in _panel.subviews) {
        if(!view.isHidden) {
            frame.size.width = MAX(frame.size.width, view.frame.origin.x + view.frame.size.width);
            frame.size.height = MAX(frame.size.height, view.frame.origin.y + view.frame.size.height);
        }
    }
    
    _location = _saveLocation;
    _startX = _saveStartX;
    _maxH = _saveMaxH;
    
    frame.origin = _location;
    
    _panel.frame = frame;
    
    if(_panel.isHidden) {
        _panel.hidden = NO;
    }
    
    [_views removeObject:_panel];
    
    _panel = nil;
}

- (NSSize)panelSize:(NSString *)key {
    NSView* view = [self.keyedPanels objectForKey:key];
    
    if(view) {
        return view.frame.size;
    }
    return NSMakeSize(0, 0);
}

- (void)setPanel:(NSString *)key rightOfView:(MTLView *)view gap:(float)gap {
    UIPanel* panel = [_keyedPanels objectForKey:key];
    
    if(panel) {
        NSRect frame = panel.frame;
        
        frame.origin = NSMakePoint(view.frame.origin.x + view.frame.size.width + gap, view.frame.origin.y);
        
        panel.frame = frame;
    }
    
}

- (void)setPanel:(NSString *)key belowView:(MTLView *)view gap:(float)gap {
    UIPanel* panel = [_keyedPanels objectForKey:key];
    
    if(panel) {
        NSRect frame = panel.frame;
        
        frame.origin = NSMakePoint(view.frame.origin.x, view.frame.origin.y + view.frame.size.height + gap);
        
        panel.frame = frame;
    }
}

- (BOOL)panelIsHidden:(NSString*)key; {
    UIPanel* panel = [_keyedPanels objectForKey:key];
    
    if(panel) {
        return [panel isHidden];
    }
    return YES;
}

- (void)setView:(MTLView *)view rightOf:(BOOL)rightOf panel:(NSString *)key gap:(float)gap anchorBottomRight:(NSSize)anchor {
    NSRect frame = view.frame;
    UIPanel* panel = [_keyedPanels objectForKey:key];
    
    if(panel) {
        if(rightOf) {
            frame.origin = NSMakePoint(panel.frame.origin.x + panel.frame.size.width + gap, panel.frame.origin.y);
        } else {
            frame.origin = NSMakePoint(panel.frame.origin.x, panel.frame.origin.y + panel.frame.size.height + gap);
        }
        frame.size = NSMakeSize(self.window.contentView.frame.size.width - frame.origin.x - anchor.width, self.window.contentView.frame.size.height - frame.origin.y - anchor.height);
        
        view.frame = frame;
    }
}

- (void)end {
    for(NSView* view in self.views) {
        if(!view.isHidden) {
            [view setHidden:YES];
        }
    }
    [self.views removeAllObjects];
}

- (void)setWindowColor:(NSColor *)color {
    self.window.backgroundColor = color;
    self.window.contentView.wantsLayer = YES;
    self.window.contentView.layer.backgroundColor = color.CGColor;
}

@end
