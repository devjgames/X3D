//
//  Sound.h
//  X3D
//
//  Created by Douglas McNamara on 6/13/23.
//

@interface Sound : XObject

@property (readonly) AVAudioPlayer* player;

- (id)initWithURL:(NSURL*)url;

@end

@interface SoundLoader : AssetLoader

@end
