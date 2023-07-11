//
//  LightMapper.h
//  X3D
//
//  Created by Douglas McNamara on 7/10/23.
//


@interface LightMapper : XObject

- (void)map:(Scene*)scene view:(MTLView*)view url:(NSURL*)sceneURL rebuild:(BOOL)rebuild;

@end

