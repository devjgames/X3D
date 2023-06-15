//
//  UIList.m
//  X3D
//
//  Created by Douglas McNamara on 5/17/23.
//

#import <X3D/X3D.h>

@interface UIListView : NSView

@end

@implementation UIListView

- (BOOL)isOpaque {
    return NO;
}

- (BOOL)isFlipped {
    return YES;
}

@end

@interface UIList : NSView

@property (readonly, weak) UIManager* manager;
@property (readonly) NSScrollView* scrollView;
@property (readonly) NSView* listView;
@property int selectedIndex;
@property (readonly) NSNumber* changed;

- (id)initWithManager:(UIManager*)manager size:(NSSize)size;
- (NSNumber*)selectionChanged;
- (void)clearChanged;

@end

@implementation UIList

- (id)initWithManager:(UIManager *)manager size:(NSSize)size {
    self = [super initWithFrame:NSMakeRect(0, 0, size.width, size.height)];
    if(self) {
        _manager = manager;
        
        self.wantsLayer = YES;
        
        _selectedIndex = -1;
        _changed = nil;
        
        _scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, size.width - manager.gap * 2, size.height - manager.gap * 2)];
        _scrollView.contentView = [[NSClipView alloc] initWithFrame:NSMakeRect(0, 0, size.width - manager.gap * 2, size.height - manager.gap * 2)];
        _scrollView.hasVerticalScroller = YES;
        
        _listView = [[UIListView alloc] initWithFrame:NSMakeRect(0, 0, size.width - manager.gap * 2, 0)];
        
        _scrollView.documentView = _listView;
        
        [self addSubview:self.scrollView];
        
        [manager.window.contentView addSubview:self];
    }
    return self;
}

- (NSNumber*)selectionChanged {
    NSNumber* c = self.changed;
    
    _changed = nil;
    
    return c;
}

- (void)clearChanged {
    _changed = nil;
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
    NSView* view = [self hitTest:self.mouseLocation];
    int i = -1;
    int j = 0;
    
    for(NSTextField* field in self.listView.subviews) {
        if(field == view) {
            i = j;
            break;
        }
        j++;
    }
    if(i != -1) {
        _changed = [NSNumber numberWithInt:i];
        _selectedIndex = i;
    }
}

@end

@implementation UIManager (UIList)

- (NSNumber*)list:(NSString *)key gap:(float)gap items:(NSArray *)items size:(NSSize)size selection:(int)selection {
    UIList* list = [self viewForKey:key];
    
    if(list == nil) {
        list = [self addView:[[UIList alloc] initWithManager:self size:size] forKey:key];
    }
    
    {
        NSRect frame = list.scrollView.frame;
        
        frame.origin.x = self.gap;
        frame.origin.y = self.gap;
        frame.size.width = list.frame.size.width - self.gap * 2;
        frame.size.height = list.frame.size.height - self.gap * 2;
        list.scrollView.frame = frame;
        
        frame = list.scrollView.contentView.frame;
        frame.size.width = list.frame.size.width - self.gap * 2;
        frame.size.height = list.frame.size.height - self.gap * 2;
        list.scrollView.contentView.frame = frame;
        
        frame = list.scrollView.documentView.frame;
        frame.size.width = list.frame.size.width - self.gap * 2;
        list.scrollView.documentView.frame = frame;
    }
    
    BOOL changed = items.count != list.listView.subviews.count;
    
    if(!changed) {
        for(int i = 0; i != (int)items.count; i++) {
            NSTextField* field = list.listView.subviews[i];
            
            if(![field.stringValue isEqualToString:[items[i] description]]) {
                changed = YES;
                break;
            }
        }
    }
    if(changed) {
        while(list.listView.subviews.count) {
            [list.listView.subviews[0] removeFromSuperview];
        }
        for(id item in items) {
            NSTextField* field = [NSTextField textFieldWithString:[NSString stringWithFormat:@"%@", item]];
            
            field.font = self.font;
            field.editable = NO;
            field.selectable = NO;
            field.drawsBackground = NO;
            field.bordered = NO;
            [list.listView addSubview:field];
        }
        [list clearChanged];
    }
    
    if(selection >= -1) {
        list.selectedIndex = selection;
        [list clearChanged];
    }
    for(int i = 0; i != (int)list.listView.subviews.count; i++) {
        NSTextField* field = list.listView.subviews[i];
        
        field.textColor = (list.selectedIndex == i) ? self.selectionColor : self.foregroundColor;
    }
    
    int y = 0;
    
    for(NSTextField* field in list.listView.subviews) {
        field.font = self.font;
        [field sizeToFit];
        
        NSRect frame = field.frame;
        
        frame.origin.x = 0;
        frame.origin.y = y;
        frame.size.width = list.listView.frame.size.width;
        
        field.frame = frame;
        
        y += frame.size.height + 5;
    }
    NSRect frame = list.listView.frame;
    
    frame.size.height = y;
    list.listView.frame = frame;
    
    [self locate:key gap:gap];
    
    list.layer.borderColor = self.foregroundColor.CGColor;
    list.layer.backgroundColor = self.backgroundColor.CGColor;
    list.layer.cornerRadius = self.cornerRadius;
    list.layer.borderWidth = self.borderWidth;
    list.scrollView.contentView.backgroundColor = self.backgroundColor;
    
    [list.layer setNeedsDisplay];
    
    return list.selectionChanged;
}

@end
