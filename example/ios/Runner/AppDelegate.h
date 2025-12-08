#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>

@interface AppDelegate : FlutterAppDelegate<FlutterStreamHandler>
@property (nonatomic, strong) FlutterMethodChannel* clipboardMethodChannel;
@property (nonatomic, strong) FlutterEventChannel* clipboardEventChannel;
@property (nonatomic, strong) FlutterEventSink eventSink;
@end
