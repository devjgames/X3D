//
//  UIList.h
//  X3D
//
//  Created by Douglas McNamara on 5/17/23.
//

@interface UIManager (UIList)

- (NSNumber*)list:(NSString*)key gap:(float)gap items:(NSArray*)items size:(NSSize)size selection:(int)selection;

@end

