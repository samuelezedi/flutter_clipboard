#import "ClipboardChannelHandler.h"

@implementation ClipboardChannelHandler {
    FlutterEventSink _eventSink;
    NSObject<NSObjectProtocol> *_clipboardChangeObserver;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    ClipboardChannelHandler* instance = [[ClipboardChannelHandler alloc] init];
    
    FlutterMethodChannel* methodChannel = [FlutterMethodChannel
        methodChannelWithName:@"net.cubiclab.clipboard/methods"
              binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:methodChannel];
    
    FlutterEventChannel* eventChannel = [FlutterEventChannel
        eventChannelWithName:@"net.cubiclab.clipboard/events"
             binaryMessenger:[registrar messenger]];
    [eventChannel setStreamHandler:instance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"copy" isEqualToString:call.method]) {
        NSString* text = call.arguments[@"text"];
        if (text == nil || text.length == 0) {
            result([FlutterError errorWithCode:@"EMPTY_TEXT"
                                       message:@"Text cannot be empty"
                                       details:nil]);
            return;
        }
        [UIPasteboard generalPasteboard].string = text;
        result(@YES);
    } else if ([@"paste" isEqualToString:call.method]) {
        NSString* text = [UIPasteboard generalPasteboard].string ?: @"";
        result(@{@"text": text});
    } else if ([@"copyRichText" isEqualToString:call.method]) {
        NSString* text = call.arguments[@"text"] ?: @"";
        NSString* html = call.arguments[@"html"];
        if (text.length == 0 && (html == nil || html.length == 0)) {
            result([FlutterError errorWithCode:@"EMPTY_CONTENT"
                                       message:@"Either text or html must be provided"
                                       details:nil]);
            return;
        }
        if (html != nil && html.length > 0) {
            [[UIPasteboard generalPasteboard] setValue:html forPasteboardType:@"public.html"];
            if (text.length > 0) {
                [UIPasteboard generalPasteboard].string = text;
            }
        } else {
            [UIPasteboard generalPasteboard].string = text;
        }
        result(@YES);
    } else if ([@"pasteRichText" isEqualToString:call.method]) {
        NSString* text = [UIPasteboard generalPasteboard].string ?: @"";
        NSString* html = [[UIPasteboard generalPasteboard] valueForPasteboardType:@"public.html"];
        UIImage* image = [UIPasteboard generalPasteboard].image;
        NSArray<NSNumber*>* imageBytes = nil;
        if (image != nil) {
            NSData* imageData = UIImagePNGRepresentation(image);
            if (imageData != nil) {
                NSMutableArray* bytes = [NSMutableArray arrayWithCapacity:imageData.length];
                const uint8_t* dataBytes = imageData.bytes;
                for (NSUInteger i = 0; i < imageData.length; i++) {
                    [bytes addObject:@(dataBytes[i])];
                }
                imageBytes = bytes;
            }
        }
        result(@{
            @"text": text,
            @"html": html ?: [NSNull null],
            @"imageBytes": imageBytes ?: [NSNull null],
            @"timestamp": @((long long)([[NSDate date] timeIntervalSince1970] * 1000))
        });
    } else if ([@"copyImage" isEqualToString:call.method]) {
        NSArray<NSNumber*>* imageBytes = call.arguments[@"imageBytes"];
        if (imageBytes == nil || imageBytes.count == 0) {
            result([FlutterError errorWithCode:@"EMPTY_IMAGE"
                                       message:@"Image bytes cannot be empty"
                                       details:nil]);
            return;
        }
        NSMutableData* data = [NSMutableData dataWithCapacity:imageBytes.count];
        for (NSNumber* byte in imageBytes) {
            uint8_t b = [byte unsignedCharValue];
            [data appendBytes:&b length:1];
        }
        UIImage* image = [UIImage imageWithData:data];
        if (image == nil) {
            result([FlutterError errorWithCode:@"INVALID_IMAGE"
                                       message:@"Failed to decode image"
                                       details:nil]);
            return;
        }
        [UIPasteboard generalPasteboard].image = image;
        result(@YES);
    } else if ([@"pasteImage" isEqualToString:call.method]) {
        UIImage* image = [UIPasteboard generalPasteboard].image;
        if (image != nil) {
            NSData* imageData = UIImagePNGRepresentation(image);
            if (imageData != nil) {
                NSMutableArray* bytes = [NSMutableArray arrayWithCapacity:imageData.length];
                const uint8_t* dataBytes = imageData.bytes;
                for (NSUInteger i = 0; i < imageData.length; i++) {
                    [bytes addObject:@(dataBytes[i])];
                }
                result(@{@"imageBytes": bytes});
                return;
            }
        }
        result(@{@"imageBytes": [NSNull null]});
    } else if ([@"copyMultiple" isEqualToString:call.method]) {
        NSDictionary* formats = call.arguments[@"formats"];
        if (formats == nil || formats.count == 0) {
            result([FlutterError errorWithCode:@"EMPTY_FORMATS"
                                       message:@"At least one format must be provided"
                                       details:nil]);
            return;
        }
        if (formats[@"image/png"] != nil) {
            NSArray<NSNumber*>* imageBytes = formats[@"image/png"];
            if (imageBytes != nil && imageBytes.count > 0) {
                NSMutableData* data = [NSMutableData dataWithCapacity:imageBytes.count];
                for (NSNumber* byte in imageBytes) {
                    uint8_t b = [byte unsignedCharValue];
                    [data appendBytes:&b length:1];
                }
                UIImage* image = [UIImage imageWithData:data];
                if (image != nil) {
                    [UIPasteboard generalPasteboard].image = image;
                    if (formats[@"text/plain"] != nil) {
                        [UIPasteboard generalPasteboard].string = [formats[@"text/plain"] description];
                    }
                    result(@YES);
                    return;
                }
            }
        }
        if (formats[@"text/plain"] != nil) {
            [UIPasteboard generalPasteboard].string = [formats[@"text/plain"] description];
        }
        if (formats[@"text/html"] != nil) {
            [[UIPasteboard generalPasteboard] setValue:[formats[@"text/html"] description]
                                      forPasteboardType:@"public.html"];
        }
        result(@YES);
    } else if ([@"getContentType" isEqualToString:call.method]) {
        NSString* text = [UIPasteboard generalPasteboard].string ?: @"";
        NSString* html = [[UIPasteboard generalPasteboard] valueForPasteboardType:@"public.html"];
        BOOL hasImage = [UIPasteboard generalPasteboard].image != nil;
        if (hasImage && (text.length > 0 || (html != nil && html.length > 0))) {
            result(@"mixed");
        } else if (hasImage) {
            result(@"image");
        } else if (text.length == 0 && (html == nil || html.length == 0)) {
            result(@"empty");
        } else if (text.length > 0 && html != nil && html.length > 0) {
            result(@"mixed");
        } else if (html != nil && html.length > 0) {
            result(@"html");
        } else {
            result(@"text");
        }
    } else if ([@"hasData" isEqualToString:call.method]) {
        NSString* text = [UIPasteboard generalPasteboard].string ?: @"";
        result(@(text.length > 0));
    } else if ([@"clear" isEqualToString:call.method]) {
        [UIPasteboard generalPasteboard].string = @"";
        result(@YES);
    } else if ([@"getDataSize" isEqualToString:call.method]) {
        NSString* text = [UIPasteboard generalPasteboard].string ?: @"";
        result(@(text.length));
    } else if ([@"startMonitoring" isEqualToString:call.method]) {
        [self startMonitoring];
        result(@YES);
    } else if ([@"stopMonitoring" isEqualToString:call.method]) {
        [self stopMonitoring];
        result(@YES);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    [self startMonitoring];
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    _eventSink = nil;
    [self stopMonitoring];
    return nil;
}

- (void)startMonitoring {
    if (_clipboardChangeObserver != nil) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    _clipboardChangeObserver = [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidBecomeActiveNotification
                    object:nil
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification* note) {
        [weakSelf checkClipboardChange];
    }];
}

- (void)stopMonitoring {
    if (_clipboardChangeObserver != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:_clipboardChangeObserver];
        _clipboardChangeObserver = nil;
    }
}

- (void)checkClipboardChange {
    if (_eventSink == nil) {
        return;
    }
    NSString* text = [UIPasteboard generalPasteboard].string ?: @"";
    NSString* html = [[UIPasteboard generalPasteboard] valueForPasteboardType:@"public.html"];
    _eventSink(@{
        @"text": text,
        @"html": html ?: [NSNull null],
        @"timestamp": @((long long)([[NSDate date] timeIntervalSince1970] * 1000))
    });
}

@end

