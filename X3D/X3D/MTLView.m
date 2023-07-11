//
//  MTLView.m
//  X3D
//
//  Created by Douglas McNamara on 5/15/23.
//

#import <X3D/X3D.h>

static int _INSTANCES = 0;

void Log(NSString* format, ...) {
    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
}

@implementation XObject

- (id)init {
    self = [super init];
    if(self) {
        _INSTANCES++;
    }
    return self;
}

- (void)dealloc {
    _INSTANCES--;
}

+ (int)instances {
    return _INSTANCES;
}

@end

@implementation AssetLoader

- (id)load:(NSURL *)url assets:(AssetManager *)assets {
    return nil;
}

@end

@interface TextureLoader : AssetLoader

@property MTKTextureLoader* loader;

- (id)initWithView:(MTLView*)view;

@end

@implementation TextureLoader

- (id)initWithView:(MTLView *)view {
    self = [super init];
    if(self) {
        self.loader = [[MTKTextureLoader alloc] initWithDevice:view.device];
    }
    return self;
}

- (id)load:(NSURL *)url assets:(AssetManager *)assets {
    NSError* error = nil;
    id<MTLTexture> texture = [self.loader newTextureWithContentsOfURL:url
                                                              options:@{ MTKTextureLoaderOptionSRGB:@NO,
                                                                         MTKTextureLoaderOptionOrigin:MTKTextureLoaderOriginTopLeft,
                                                                         MTKTextureLoaderOptionGenerateMipmaps:@NO,
                                                                         MTKTextureLoaderOptionAllocateMipmaps:@NO,
                                                                      } error:&error];
    if(error) {
        Log(@"%@", error);
    }
    texture.label = [url.path stringByReplacingOccurrencesOfString:assets.baseURL.path withString:@""];
    texture.label = [texture.label substringFromIndex:1];
    
    return texture;
}

@end

@interface AssetManager ()

@property NSMutableDictionary<NSString*, id>* assets;
@property NSMutableDictionary<NSString*, AssetLoader*>* assetLoaders;

@end

@implementation AssetManager

- (id)initWithView:(MTLView *)view {
    self = [super init];
    if(self) {
        self.assets = [NSMutableDictionary dictionaryWithCapacity:128];
        self.assetLoaders = [NSMutableDictionary dictionaryWithCapacity:16];
        self.baseURL = NSBundle.mainBundle.resourceURL;
        
        _view = view;
        
        [self registerAssetLoader:[[TextureLoader alloc] initWithView:self.view] forExtension:@"png"];
        [self registerAssetLoader:[[TextureLoader alloc] initWithView:self.view] forExtension:@"jpg"];
        [self registerAssetLoader:[[KeyFrameMeshLoader alloc] init] forExtension:@"md2"];
        [self registerAssetLoader:[[SoundLoader alloc] init] forExtension:@"wav"];
        [self registerAssetLoader:[[MeshLoader alloc] init] forExtension:@"obj"];
    }
    return self;
}

- (void)registerAssetLoader:(AssetLoader *)loader forExtension:(NSString *)extension {
    Log(@"Registering asset loader %@ for extension %@ ...", NSStringFromClass(loader.class), extension);
    [self.assetLoaders setObject:loader forKey:extension];
}

- (id)load:(NSString *)path {
    id asset = [self.assets objectForKey:path];
    
    if(asset == nil) {
        Log(@"Loading asset '%@' ...", path);
        NSURL* url = [self.baseURL URLByAppendingPathComponent:path];
        [self.assets setObject:asset = [[self.assetLoaders objectForKey:path.pathExtension] load:url assets:self] forKey:path];
    }
    return asset;
}

- (void)unLoad:(NSString *)path {
    [self.assets removeObjectForKey:path];
}

- (void)clear {
    [self.assets removeAllObjects];
}

@end

@interface ContentView : NSView

@end

@implementation ContentView

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if(self) {
    }
    return self;
}

- (BOOL)isFlipped {
    return YES;
}

@end

static BOOL _KEY_STATE[400];
static BOOL _BUTTON_STATE[] = { NO, NO };

@interface MTLView ()

@property int lastX;
@property int lastY;
@property float lastTime;
@property float totalTime;
@property float seconds;
@property int frames;

@end

@implementation MTLView {
    CVDisplayLinkRef _displayLink;
    dispatch_source_t _displaySource;
}

- (id)initWithView:(NSView *)view device:(id<MTLDevice>)device {
    self = [super initWithFrame:view.frame device:device];
    if(self) {
        self.delegate = nil;
        self.wantsLayer = YES;
        
        self.autoResizeDrawable = YES;
        
        self.colorPixelFormat = MTLPixelFormatRGBA8Unorm;
        self.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
        
        self.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
        
        _commandQueue = [self.device newCommandQueue];
        
        NSURL* url = [[[NSBundle bundleForClass:MTLView.class] resourceURL] URLByAppendingPathComponent:@"default.metallib"];
        NSError* error = nil;
        
        _library = [self.device newLibraryWithURL:url error:&error];
        
        if(error) {
            Log(@"%@", error.description);
        }
        
        _assets = [[AssetManager alloc] initWithView:self];
        
        self.lastX = 0;
        self.lastY = 0;
        
        for(int i = 0; i != (int)(sizeof(_KEY_STATE) / sizeof(BOOL)); i++) {
            _KEY_STATE[i] = NO;
        }
        
        ContentView* contentView = [[ContentView alloc] initWithFrame:view.window.contentView.frame];
        
        view.window.contentView = contentView;
        view = contentView;
        
        _ui = [[UIManager alloc] initWithWindow:view.window];
        
        [view addSubview:self];
        [self becomeFirstResponder];
        [self resetTimer];
        
        view.window.delegate = self;
    }
    return self;
}

- (BOOL)canBecomeKeyView {
    return YES;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    return YES;
}

- (int)width {
    return (int)self.drawableSize.width;
}

- (int)height {
    return (int)self.drawableSize.height;
}

- (float)aspectRatio {
    return self.width / (float)self.height;
}

- (void)setMouse {
    CGPoint p = [self.window convertPointFromScreen:NSEvent.mouseLocation];
    
    _mouseX = p.x;
    _mouseY = self.height - p.y - 1;
}

- (void)mouseDown:(NSEvent *)event {
    _BUTTON_STATE[0] = YES;
    
    [self setMouse];
    
    _lastX = self.mouseX;
    _lastY = self.mouseY;
    _deltaX = 0;
    _deltaY = 0;
}

- (void)mouseUp:(NSEvent *)event {
    _BUTTON_STATE[0] = NO;
    _deltaX = 0;
    _deltaY = 0;
}

- (void)mouseDragged:(NSEvent *)event {
    [self setMouse];
    
    _deltaX = self.mouseX - _lastX;
    _deltaY = _lastY - self.mouseY;
    
    self.lastX = self.mouseX;
    self.lastY = self.mouseY;
}

- (void)rightMouseDown:(NSEvent *)event {
    _BUTTON_STATE[1] = YES;
    
    [self setMouse];
    
    _lastX = self.mouseX;
    _lastY = self.mouseY;
    _deltaX = 0;
    _deltaY = 0;
}

- (void)rightMouseUp:(NSEvent *)event {
    _BUTTON_STATE[1] = NO;
    _deltaX = 0;
    _deltaY = 0;
}

- (void)rightMouseDragged:(NSEvent *)event {
    [self setMouse];
    
    _deltaX = self.mouseX - _lastX;
    _deltaY = _lastY - self.mouseY;
    
    self.lastX = self.mouseX;
    self.lastY = self.mouseY;
}

- (void)keyDown:(NSEvent *)event {
    int key = event.keyCode;
    
    if(key >= 0 && key < (int)(sizeof(_KEY_STATE) / sizeof(BOOL))) {
        _KEY_STATE[key] = YES;
    }
}

- (void)keyUp:(NSEvent *)event {
    int key = event.keyCode;
    
    if(key >= 0 && key < (int)(sizeof(_KEY_STATE) / sizeof(BOOL))) {
        _KEY_STATE[key] = NO;
    }
}

- (BOOL)isButtonDown:(int)button {
    if(button >= 0 && button < 2) {
        return _BUTTON_STATE[button];
    }
    return NO;
}

- (BOOL)isKeyDown:(int)key {
    if(key >= 0 && key < (int)(sizeof(_KEY_STATE) / sizeof(BOOL))) {
        return _KEY_STATE[key];
    }
    return NO;
}

- (void)resetTimer {
    self.lastTime = CACurrentMediaTime();
    self.seconds = 0;
    self.frames = 0;
    
    _totalTime = 0;
    _elapsedTime = 0;
    _frameRate = 0;
}

- (void)tick {
    float now = CACurrentMediaTime();
    
    _elapsedTime = now - self.lastTime;
    _totalTime += self.elapsedTime;
    
    self.lastTime = now;
    self.seconds += self.elapsedTime;
    self.lastTime = now;
    self.frames++;
    
    if(self.seconds >= 1) {
        _frameRate = self.frames;
        
        self.frames = 0;
        self.seconds = 0;
    }
    
    _deltaX = 0;
    _deltaY = 0;
}

- (void)tearDown {
    _assets = nil;
    _ui = nil;
}

- (void)saveRGBA:(NSData *)data width:(int)w height:(int)h toPath:(NSString *)path {
    NSURL* url = [self.assets.baseURL URLByAppendingPathComponent:path];
    CIContext* context = [CIContext context];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CIImage* image = [CIImage imageWithBitmapData:data bytesPerRow:4 * w size:NSMakeSize(w, h) format:kCIFormatRGBA8 colorSpace:colorSpace];
    CGImageRef imageRef = [context createCGImage:image fromRect:NSMakeRect(0, 0, w, h)];
    CGImageDestinationRef imageDest = CGImageDestinationCreateWithURL((CFURLRef)url, (CFStringRef)UTTypePNG.identifier, 1, NULL);
    
    CGImageDestinationAddImage(imageDest, imageRef, NULL);
    CGImageDestinationFinalize(imageDest);
    
    CFRelease(imageRef);
    CFRelease(imageDest);
    CFRelease(colorSpace);
}

- (void)windowWillClose:(id)arg {
    [NSApp terminate:nil];
}

@end

@implementation Parser

+ (NSArray<NSString*>*)split:(NSString *)text delims:(NSCharacterSet *)delims {
    NSScanner* scanner = [NSScanner scannerWithString:text];
    NSMutableArray<NSString*>* tokens = [NSMutableArray arrayWithCapacity:32];
    NSString* token = nil;
    
    scanner.charactersToBeSkipped = delims;
    while([scanner scanUpToCharactersFromSet:delims intoString:&token]) {
        [tokens addObject:token];
    }
    return tokens;
}

@end
