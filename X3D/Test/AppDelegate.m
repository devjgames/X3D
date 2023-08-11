//
//  AppDelegate.m
//  X3DTest
//
//  Created by Douglas McNamara on 5/15/23.
//

#import "AppDelegate.h"
#import "Test.h"

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;
@property (strong) TestFramework* framework;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    [NSApp activateIgnoringOtherApps:YES];
    
    MTLView* view = [[MTLView alloc] initWithView:self.window.contentView device:MTLCreateSystemDefaultDevice()];

    NSArray<Test*>* tests = @[
        [[HelloWorld alloc] init],
        [[Plot alloc] init],
        [[Map alloc] initWithPath:@"assets/maps/map1.obj" position:Vec3Make(0, 64, 0) direction:Vec2Make(1, -1) ambientColor:Vec4Make(0.7f, 0.7f, 0.7f, 1)]
    ];
    
    self.framework = [[TestFramework alloc] initWithWindow:self.window view:view tests:tests];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    
    [self.framework tearDown];
    
    self.framework = nil;
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

@end
