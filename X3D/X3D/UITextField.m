//
//  UITextField.m
//  X3D
//
//  Created by Douglas McNamara on 6/15/23.
//

#import <X3D/X3D.h>

@interface UIField : NSTextField

@property (weak) UIManager* manager;

- (id)initWithManager:(UIManager*)manager;

@end

@implementation UIField


- (id)initWithManager:(UIManager *)manager {
    self = [super initWithFrame:NSMakeRect(0, 0, 0, 0)];
    if(self) {
        self.manager = manager;
    }
    return self;
}

- (BOOL)becomeFirstResponder {
    BOOL ok = [super becomeFirstResponder];
    
    if(ok) {
        NSTextView* textField = (NSTextView*)[self currentEditor];
        
        if([textField respondsToSelector:@selector(setInsertionPointColor:)]) {
            [textField setInsertionPointColor:self.manager.foregroundColor];
        }
    }
    return ok;
}

@end

@interface UITextField : UIView

@property (readonly, weak) UIManager* manager;
@property (readonly) NSTextField* field;
@property (readonly) NSTextField* label;
@property (readonly) NSString* changed;

- (id)initWithManager:(UIManager*)manager width:(CGFloat)width caption:(NSString*)caption;
- (NSString*)textChanged;

@end

@implementation UITextField

- (id)initWithManager:(UIManager *)manager width:(CGFloat)width caption:(NSString *)caption {
    self = [super initWithFrame:NSMakeRect(0, 0, 0, 0)];
    if(self) {
        self.wantsLayer = YES;
        
        self.layer = [CALayer layer];
        
        _manager = manager;
        _changed = nil;
        
        _field = [[UIField alloc] initWithManager:manager];
        _field.drawsBackground = NO;
        _field.editable = YES;
        _field.selectable = YES;
        _field.bordered = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSControlTextDidChangeNotification object:self.field];
        
        [_field sizeToFit];
        
        _field.frame = NSMakeRect(0, 0, width, _field.frame.size.height);
        
        _label = [NSTextField textFieldWithString:caption];
        _label.drawsBackground = NO;
        _label.editable = NO;
        _label.selectable = NO;
        _label.bezeled = NO;
        _label.bordered = NO;
        
        [self addSubview:_field];
        [self addSubview:_label];
    }
    return self;
}

- (NSString*)textChanged {
    NSString* c = self.changed;
    
    _changed = nil;
    
    return c;
}


- (void)textDidChange:(NSTextField*)field {
    _changed = self.field.stringValue;
}


@end

@implementation UIManager (UITextField)

- (NSString*)field:(NSString *)key gap:(float)gap caption:(NSString *)caption text:(NSString *)text width:(CGFloat)width reset:(BOOL)reset {
    UITextField* field = [self viewForKey:key];
    
    if(field == nil) {
        field = [self addView:[[UITextField alloc] initWithManager:self width:width caption:caption] forKey:key];
    }
    
    CGFloat w = field.field.frame.size.width;
    
    field.label.font = self.font;
    field.field.font = self.font;
    [field.label sizeToFit];
    
    if(reset) {
        field.field.stringValue = text;
        [field.field sizeToFit];
    }

    field.field.frame = NSMakeRect(self.gap, self.gap, w, field.field.frame.size.height);
    field.frame = NSMakeRect(0, 0, field.field.frame.size.width + field.label.frame.size.width + self.gap * 3, field.field.frame.size.height + self.gap * 2);
    field.label.frame = NSMakeRect(self.gap + field.field.frame.size.width + self.gap, self.gap, field.label.frame.size.width, field.label.frame.size.height);
    
    [self locate:key gap:gap];
    
    field.label.textColor = self.selectionColor;
    field.field.textColor = self.foregroundColor;
    field.layer.borderColor = self.foregroundColor.CGColor;
    field.layer.cornerRadius = self.cornerRadius;
    field.layer.borderWidth = self.borderWidth;
    field.layer.backgroundColor = self.backgroundColor.CGColor;
    
    return field.textChanged;
}

- (BOOL)field:(NSString*)key gap:(float)gap caption:(NSString*)caption intValue:(int*)value width:(CGFloat)width reset:(BOOL)reset {
    NSString* s = [self field:key gap:gap caption:caption text:[NSString stringWithFormat:@"%i", *value] width:width reset:reset];
    
    if(s) {
        *value = [s intValue];
        return YES;
    }
    return NO;
}

- (BOOL)field:(NSString*)key gap:(float)gap caption:(NSString*)caption floatValue:(float*)value width:(CGFloat)width reset:(BOOL)reset {
    NSString* s = [self field:key gap:gap caption:caption text:[NSString stringWithFormat:@"%@", [NSNumber numberWithFloat:*value]] width:width reset:reset];
    
    if(s) {
        *value = [s floatValue];
        return YES;
    }
    return NO;
}

- (BOOL)field:(NSString*)key gap:(float)gap caption:(NSString*)caption vec2Value:(Vec2*)value width:(CGFloat)width reset:(BOOL)reset {
    NSNumber* x = [NSNumber numberWithFloat:value->x];
    NSNumber* y = [NSNumber numberWithFloat:value->y];
    NSString* s = [self field:key gap:gap caption:caption text:[NSString stringWithFormat:@"%@ %@", x, y] width:width reset:reset];
    
    if(s) {
        NSArray<NSString*>* tokens = [Parser split:s delims:[NSCharacterSet whitespaceCharacterSet]];
        
        if(tokens.count == 2) {
            *value = Vec2Make(tokens[0].floatValue,
                              tokens[1].floatValue
                              );
        }
        return YES;
    }
    return NO;
}

- (BOOL)field:(NSString*)key gap:(float)gap caption:(NSString*)caption vec3Value:(Vec3*)value width:(CGFloat)width reset:(BOOL)reset {
    NSNumber* x = [NSNumber numberWithFloat:value->x];
    NSNumber* y = [NSNumber numberWithFloat:value->y];
    NSNumber* z = [NSNumber numberWithFloat:value->z];
    NSString* s = [self field:key gap:gap caption:caption text:[NSString stringWithFormat:@"%@ %@ %@", x, y, z] width:width reset:reset];
    
    if(s) {
        NSArray<NSString*>* tokens = [Parser split:s delims:[NSCharacterSet whitespaceCharacterSet]];
        
        if(tokens.count == 3) {
            *value = Vec3Make(tokens[0].floatValue,
                              tokens[1].floatValue,
                              tokens[2].floatValue
                              );
        }
        return YES;
    }
    return NO;
}

- (BOOL)field:(NSString*)key gap:(float)gap caption:(NSString*)caption vec4Value:(Vec4*)value width:(CGFloat)width reset:(BOOL)reset {
    NSNumber* x = [NSNumber numberWithFloat:value->x];
    NSNumber* y = [NSNumber numberWithFloat:value->y];
    NSNumber* z = [NSNumber numberWithFloat:value->z];
    NSNumber* w = [NSNumber numberWithFloat:value->w];
    NSString* s = [self field:key gap:gap caption:caption text:[NSString stringWithFormat:@"%@ %@ %@ %@", x, y, z, w] width:width reset:reset];
    
    if(s) {
        NSArray<NSString*>* tokens = [Parser split:s delims:[NSCharacterSet whitespaceCharacterSet]];
        
        if(tokens.count == 4) {
            *value = Vec4Make(tokens[0].floatValue,
                              tokens[1].floatValue,
                              tokens[2].floatValue,
                              tokens[3].floatValue
                              );
        }
        return YES;
    }
    return NO;
}

@end
