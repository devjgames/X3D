//
//  Sound.m
//  X3D
//
//  Created by Douglas McNamara on 6/13/23.
//

#import <X3D/X3D.h>

@implementation Sound

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if(self) {
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    }
    return self;
}

@end

@implementation SoundLoader

- (id)load:(NSURL *)url assets:(AssetManager *)assets {
    return [[Sound alloc] initWithURL:url];
}

@end
