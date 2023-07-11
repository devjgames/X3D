//
//  ParticleSystem.h
//  X3D
//
//  Created by Douglas McNamara on 7/10/23.
//

typedef struct Particle {
    Vec3 velocity;
    Vec3 position;
    Vec3 startPosition;
    Vec2 size;
    Vec2 startSize;
    Vec2 endSize;
    Vec4 color;
    Vec4 startColor;
    Vec4 endColor;
    float time;
    float lifeSpan;
} Particle;

@interface ParticleSystem : Node

- (id)initWithView:(MTLView*)view maxParticles:(int)max;
- (void)emit:(Particle*)particle;

@end


