//
//  Light.m
//  X3D
//
//  Created by Douglas McNamara on 8/9/23.
//

#import <X3D/X3D.h>

@implementation Light

- (id)init {
    self = [super init];
    if(self) {
        self.color = Vec4Make(1, 1, 1, 1);
    }
    return self;
}

@end

@implementation AmbientLight

- (id)init {
    self = [super init];
    if(self) {
        self.color = Vec4Make(0, 0, 0, 1);
    }
    return self;
}

@end

@implementation DirectionalLight

- (id)init {
    self = [super init];
    if(self) {
    }
    return self;
}

- (Vec3)lightDirection {
    Vec4 c = self.model.columns[2];
    
    return Vec3Make(c.x, c.y, c.z);
}

@end

@implementation PointLight

- (id)init {
    self = [super init];
    if(self) {
        self.range = 300;
    }
    return self;
}

@end
