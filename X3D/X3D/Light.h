//
//  Light.h
//  X3D
//
//  Created by Douglas McNamara on 8/9/23.
//


@interface Light : Node

@property Vec4 color;

@end

@interface AmbientLight : Light

@end

@interface DirectionalLight : Light

- (Vec3)lightDirection;

@end


@interface PointLight : Light

@property float range;

@end
