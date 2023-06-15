//
//  UIManager.m
//  X3D
//
//  Created by Douglas McNamara on 5/16/23.
//

#import <X3D/X3D.h>

@interface UIManager ()

@property (readonly) NSMutableDictionary<NSString*, NSView*>* keyedViews;
@property (readonly) NSMutableArray<NSView*>* views;
@property (readonly) NSPoint location;
@property (readonly) float startX;
@property (readonly) float maxH;

@end

@implementation UIManager

- (id)initWithWindow:(NSWindow*)window {
    self = [super init];
    if(self) {
        _window = window;
        
        self.backgroundColor = NSColor.grayColor;
        self.foregroundColor = NSColor.blackColor;
        self.selectionColor = NSColor.whiteColor;
        self.font = [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightLight];
        self.borderWidth = 1;
        self.cornerRadius = 8;
        self.gap = 10;
        
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

- (id)addView:(NSView*)view forKey:(NSString*)key {
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
    
    [self.views addObjectsFromArray:self.keyedViews.allValues];
}

- (void)moveTo:(NSPoint)location {
    _location = location;
    _maxH = 0;
    _startX = location.x;
}

- (void)moveRightOf:(NSString*)key gap:(float)gap {
    NSView* view = [self.keyedViews objectForKey:key];
    NSRect frame = view.frame;
    
    _location.x = frame.origin.x + frame.size.width + gap;
    _location.y = frame.origin.y;
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
        [view setHidden:YES];
    }
}

@end
