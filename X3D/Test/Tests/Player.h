//
//  CollisionTest.h
//  X3DTest
//
//  Created by Douglas McNamara on 6/13/23.
//

@interface Player : Test

@property NSString* info;

- (id)initWithPath:(NSString*)path baseURL:(NSURL*)baseURL;
+ (Player*)instance;

@end

