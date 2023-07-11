//
//  ParticleSystem.m
//  X3D
//
//  Created by Douglas McNamara on 7/10/23.
//

#import <X3D/X3D.h>

@interface ParticleSystem ()

@property int max;
@property NSMutableData* particles;
@property NSMutableData* temp;

@end

@implementation ParticleSystem

- (id)initWithView:(MTLView *)view maxParticles:(int)max {
    self = [super init];
    if(self) {
        self.max = max;
        self.particles = [NSMutableData dataWithCapacity:max * sizeof(Particle)];
        self.temp = [NSMutableData dataWithCapacity:max * sizeof(Particle)];
        self.encodable = [[BasicEncodable alloc] initWithView:view vertexCount:max * 6];
    }
    return self;
}

- (void)emit:(Particle *)particle {
    if(self.particles.length / sizeof(Particle) < self.max) {
        [self.particles appendBytes:particle length:sizeof(Particle)];
    }
}

- (void)onUpdateWithScene:(Scene *)scene view:(MTLView *)view {
    self.temp.length = 0;
    
    for(int i = 0; i != (int)(self.particles.length / sizeof(Particle)); i++) {
        Particle p = ((Particle*)self.particles.mutableBytes)[i];
        float seconds = view.totalTime - p.time;
        
        if(seconds < p.lifeSpan) {
            float amount = seconds / p.lifeSpan;
            
            p.position = p.startPosition + seconds * p.velocity;
            p.color = p.startColor + amount * (p.endColor - p.startColor);
            p.size = p.startSize + amount * (p.endSize - p.startSize);
            [self.temp appendBytes:&p length:sizeof(Particle)];
        }
    }
    
    NSMutableData* data = self.particles;
    
    self.particles = self.temp;
    self.temp = data;
    
    data.length = 0;
    
    Mat4 m = Mat4Invert(Mat4Mul(scene.camera.view, self.model));
    Vec3 r = Vec3Make(m.columns[0].x, m.columns[0].y, m.columns[0].z);
    Vec3 u = Vec3Make(m.columns[1].x, m.columns[1].y, m.columns[1].z);
    
    [self.basicEncodable clear];
    for(int i = 0; i != (int)(self.particles.length / sizeof(Particle)); i++) {
        Particle p = ((Particle*)self.particles.mutableBytes)[i];
        Vec3 p1 = p.position - r * p.size.x / 2 - u * p.size.y / 2;
        Vec3 p2 = p.position - r * p.size.x / 2 + u * p.size.y / 2;
        Vec3 p3 = p.position + r * p.size.x / 2 + u * p.size.y / 2;
        Vec3 p4 = p.position + r * p.size.x / 2 - u * p.size.y / 2;
        Vec4 c = p.color;
    
        [self.basicEncodable pushVertex:Vertex(p1.x, p1.y, p1.z, 0, 0, 0, 0, 0, 0, 0, c.x, c.y, c.z, c.w)];
        [self.basicEncodable pushVertex:Vertex(p2.x, p2.y, p2.z, 0, 1, 0, 0, 0, 0, 0, c.x, c.y, c.z, c.w)];
        [self.basicEncodable pushVertex:Vertex(p3.x, p3.y, p3.z, 1, 1, 0, 0, 0, 0, 0, c.x, c.y, c.z, c.w)];
        [self.basicEncodable pushVertex:Vertex(p3.x, p3.y, p3.z, 1, 1, 0, 0, 0, 0, 0, c.x, c.y, c.z, c.w)];
        [self.basicEncodable pushVertex:Vertex(p4.x, p4.y, p4.z, 1, 0, 0, 0, 0, 0, 0, c.x, c.y, c.z, c.w)];
        [self.basicEncodable pushVertex:Vertex(p1.x, p1.y, p1.z, 0, 0, 0, 0, 0, 0, 0, c.x, c.y, c.z, c.w)];
    }
    [self.basicEncodable bufferVertices];
}

@end
