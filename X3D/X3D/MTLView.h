//
//  MTLView.h
//  X3D
//
//  Created by Douglas McNamara on 5/15/23.
//

void Log(NSString* format, ...);

@interface XObject : NSObject

+ (int)instances;

@end

@class AssetManager;

@interface AssetLoader : XObject

- (id)load:(NSURL*)url assets:(AssetManager*)assets;

@end

@class MTLView;

@interface AssetManager : XObject

@property (readonly, weak) MTLView* view;
@property NSURL* baseURL;

- (id)initWithView:(MTLView*)view;
- (void)registerAssetLoader:(AssetLoader*)loader forExtension:(NSString*)extension;
- (id)load:(NSString*)path;
- (void)unLoad:(NSString*)path;
- (void)clear;

@end

@class UIManager;


@interface MTLView : MTKView <NSWindowDelegate>

@property (readonly) id<MTLCommandQueue> commandQueue;
@property (readonly) id<MTLLibrary> library;
@property (readonly) AssetManager* assets;
@property (readonly) float totalTime;
@property (readonly) float elapsedTime;
@property (readonly) int frameRate;
@property (readonly) int mouseX;
@property (readonly) int mouseY;
@property (readonly) int deltaX;
@property (readonly) int deltaY;

- (id)initWithView:(NSView*)view device:(id<MTLDevice>)device;
- (int)width;
- (int)height;
- (float)aspectRatio;
- (BOOL)isButtonDown:(int)button;
- (BOOL)isKeyDown:(int)key;
- (void)resetTimer;
- (void)tick;
- (void)tearDown;
- (void)saveRGBA:(NSData*)data width:(int)w height:(int)h toPath:(NSString*)path;
- (BOOL)fpsMouseEnabled;
- (void)setFpsMouseEnabled:(BOOL)enabled;

@end

@interface Parser : XObject

+ (NSArray<NSString*>*)split:(NSString*)text delims:(NSCharacterSet*)delims;

@end

