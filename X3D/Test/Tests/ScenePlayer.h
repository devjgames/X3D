//
//  ScenePlayer.h
//  X3DTest
//
//  Created by Douglas McNamara on 6/13/23.
//

@interface ScenePlayer : Test

@property NSString* info;
@property (readonly) NSURL* url;

- (id)initWithPath:(NSString*)path baseURL:(NSURL*)baseURL;
+ (ScenePlayer*)instance;

@end

