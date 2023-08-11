//
//  Camera.h
//  X3D
//
//  Created by Douglas McNamara on 8/9/23.
//


@interface Camera : Node

@property (readonly) BOOL active;
@property (readonly) Mat4 projection;

- (void)calcProjection:(float)aspectRatio;
- (void)activate;

@end
