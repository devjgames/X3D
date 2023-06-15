//
//  UITextField.h
//  X3D
//
//  Created by Douglas McNamara on 6/15/23.
//

@interface UIManager (UITextField)

- (NSString*)field:(NSString*)key gap:(float)gap caption:(NSString*)caption text:(NSString*)text width:(CGFloat)width reset:(BOOL)reset;
- (BOOL)field:(NSString*)key gap:(float)gap caption:(NSString*)caption intValue:(int*)value width:(CGFloat)width reset:(BOOL)reset;
- (BOOL)field:(NSString*)key gap:(float)gap caption:(NSString*)caption floatValue:(float*)value width:(CGFloat)width reset:(BOOL)reset;
- (BOOL)field:(NSString*)key gap:(float)gap caption:(NSString*)caption vec2Value:(Vec2*)value width:(CGFloat)width reset:(BOOL)reset;
- (BOOL)field:(NSString*)key gap:(float)gap caption:(NSString*)caption vec3Value:(Vec3*)value width:(CGFloat)width reset:(BOOL)reset;
- (BOOL)field:(NSString*)key gap:(float)gap caption:(NSString*)caption vec4Value:(Vec4*)value width:(CGFloat)width reset:(BOOL)reset;

@end

