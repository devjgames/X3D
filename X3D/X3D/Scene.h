//
//  Scene.h
//  X3D
//
//  Created by Douglas McNamara on 5/17/23.
//

@interface Scene : XObject

@property (readonly) Node* root;

- (void)encodeWithEncoder:(id<MTLRenderCommandEncoder>)encoder size:(NSSize)size;

@end

