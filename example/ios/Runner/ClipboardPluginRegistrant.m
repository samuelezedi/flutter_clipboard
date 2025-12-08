#import <Flutter/Flutter.h>
#import "ClipboardPlugin-Swift.h"

@interface ClipboardPluginRegistrant : NSObject
@end

@implementation ClipboardPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
    [ClipboardPlugin registerWithRegistrar:[registry registrarForPlugin:@"ClipboardPlugin"]];
}

@end

