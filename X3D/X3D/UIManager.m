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
@property (readonly) NSMutableArray<NSView*>* views;
@property (readonly) NSPoint location;
@property (readonly) float startX;
@property (readonly) float maxH;

@end

@implementation UIManager

- (id)init {
    self = [super init];
    if(self) {
        self.backgroundColor = NSColor.grayColor;
        self.foregroundColor = NSColor.blackColor;
        self.selectionColor = NSColor.whiteColor;
        self.font = [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightLight];
        self.borderWidth = 1;
        self.cornerRadius = 8;
        self.gap = 10;
        
        _panel = [[UIPanel alloc] init];
        
        _keyedViews = [NSMutableDictionary dictionaryWithCapacity:100];
        _views = [NSMutableArray arrayWithCapacity:100];
        _location = NSMakePoint(0, 0);
        _startX = 0;
        _maxH = 0;
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
    [_panel addSubview:view];

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
    _location.x = 0;
    _location.y = 0;
    _maxH = 0;
    _startX = _location.x;
    
    [self.views addObjectsFromArray:self.keyedViews.allValues];
}

- (void)moveRightOf:(NSString *)key gap:(float)gap {
    NSView* view = [self.keyedViews objectForKey:key];
    
    _location.x = view.frame.origin.x + view.frame.size.width + gap;
    _location.y = view.frame.origin.y;
    _maxH = 0;
    _startX = _location.x;
}

- (void)addRow:(float)gap {
    _location.y += gap + _maxH;
    _location.x = _startX;
    _maxH = 0;
}

- (void)end {
    for(NSView* view in self.views) {
        if(!view.isHidden) {
            [view setHidden:YES];
        }
    }
    [self.views removeAllObjects];
    
    NSRect frame = NSMakeRect(0, 0, 0, 0);
    
    for(NSView* view in _panel.subviews) {
        if(!view.isHidden) {
            frame.size.width = MAX(frame.size.width, view.frame.origin.x + view.frame.size.width);
            frame.size.height = MAX(frame.size.height, view.frame.origin.y + view.frame.size.height);
        }
    }
    
    _panel.frame = frame;
}

+ (void)layout:(float)gap center:(NSView *)center north:(NSView *)north south:(NSView *)south east:(NSView *)east west:(NSView *)west {
    NSRect f = center.window.contentView.frame;
    
    if(north) {
        NSRect n = north.frame;
        
        n = NSMakeRect(gap, f.size.height - n.size.height - gap, n.size.width, n.size.height);
        f = NSMakeRect(f.origin.x, f.origin.y, f.size.width, f.size.height - n.size.height - gap * 2);
        
        north.frame = n;
        
        if(!north.superview) {
            [center.window.contentView addSubview:north];
        }
    }
    
    if(south) {
        NSRect s = south.frame;
        
        s = NSMakeRect(gap, gap, s.size.width, s.size.height);
        f = NSMakeRect(f.origin.x, f.origin.y + gap * 2 + s.size.height, f.size.width, f.size.height - s.size.height - gap * 2);
        
        south.frame = s;
        
        if(!south.superview) {
            [center.window.contentView addSubview:south];
        }
    }
    
    if(east) {
        NSRect e = east.frame;
        float g = (north) ? 0 : gap;
        
        e = NSMakeRect(f.size.width - e.size.width - gap, f.origin.y + g, e.size.width, e.size.height);
        f = NSMakeRect(f.origin.x, f.origin.y, f.size.width - e.size.width - gap * 2, f.size.height);
        
        east.frame = e;
        
        if(!east.superview) {
            [center.window.contentView addSubview:east];
        }
    }
    
    if(west) {
        NSRect w = west.frame;
        float g = (north) ? 0 : gap;
        
        w = NSMakeRect(gap, f.origin.y + g, w.size.width, w.size.height);
        f = NSMakeRect(f.origin.x + gap * 2 + w.size.width, f.origin.y, f.size.width - w.size.width - gap * 2, f.size.height);
        
        west.frame = w;
        
        if(!west.superview) {
            [center.window.contentView addSubview:west];
        }
    }
    
    center.frame = f;
}

@end
