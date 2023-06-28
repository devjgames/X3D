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
    
    MTLView* view = [[MTLView alloc] initWithView:self.window.contentView];
    
    NSArray<Test*>* tests = @[
        [[UIConfig alloc] init],
        [[KeyFrameMeshTest alloc] init],
        [[Player alloc] initWithPath:@"assets/meshes/scene1.obj" baseURL:view.assets.baseURL],
        [[FieldTest alloc] init]
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
