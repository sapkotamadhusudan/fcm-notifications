
#import <React/RCTConvert.h>
#import <RNFBApp/RNFBSharedUtils.h>
#import <RNFBApp/RNFBRCTEventEmitter.h>
#import <GoogleUtilities/GULAppDelegateSwizzler.h>

#import "RNFBMessagingAppDelegateInterceptor.h"
#import "RNFBNotificationSerializer.h"
#import "RNFBNotificationUtils.h"

@implementation RNFBMessagingAppDelegateInterceptor{
    NSMutableDictionary<NSString *, void (^)(UIBackgroundFetchResult)> *fetchCompletionHandlers;
    NSMutableDictionary<NSString *, void(^)(void)> *completionHandlers;
}

// PRE-BRIDGE-EVENTS: Consider enabling this to allow events built up before the bridge is built to be sent to the JS side
// static NSMutableArray *pendingEvents = nil;
static NSDictionary *initialNotification = nil;
static bool jsReady = FALSE;

+ (instancetype)sharedInstance {
  static dispatch_once_t once;
  static RNFBMessagingAppDelegateInterceptor *sharedInstance;
  dispatch_once(&once, ^{
    sharedInstance = [[RNFBMessagingAppDelegateInterceptor alloc] init];
    [GULAppDelegateSwizzler proxyOriginalDelegateIncludingAPNSMethods];
    [GULAppDelegateSwizzler registerAppDelegateInterceptor:sharedInstance];
  });
  return sharedInstance;
}

- (void)initialise {
    // If we're on iOS 10 then we need to set this as a delegate for the UNUserNotificationCenter
    if (@available(iOS 10.0, *)) {
        [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    }

    // Set static instance for use from AppDelegate
    completionHandlers = [[NSMutableDictionary alloc] init];
    fetchCompletionHandlers = [[NSMutableDictionary alloc] init];
}

// used to temporarily store a promise instance to resolve calls to `registerForRemoteNotifications`
- (void)setPromiseResolve:(RCTPromiseResolveBlock)resolve andPromiseReject:(RCTPromiseRejectBlock)reject {
  _registerPromiseResolver = resolve;
  _registerPromiseRejecter = reject;
}

// called when `registerForRemoteNotifications` completes successfully
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  if (_registerPromiseResolver != nil) {
    _registerPromiseResolver(@([RCTConvert BOOL:@([UIApplication sharedApplication].isRegisteredForRemoteNotifications)]));
    _registerPromiseResolver = nil;
    _registerPromiseRejecter = nil;
  }
}

// called when `registerForRemoteNotifications` fails to complete
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  if (_registerPromiseRejecter != nil) {
    [RNFBSharedUtils rejectPromiseWithNSError:_registerPromiseRejecter error:error];
    _registerPromiseResolver = nil;
    _registerPromiseRejecter = nil;
  }
}

// APNS - only called on iOS versions less than v10 (which isn't officially supported, added here for ease later on)
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
     NSLog(@"RNFNotification less than v10 %@", userInfo);
  // send message event for remote notifications that have also have data
  if (userInfo[@"aps"] && ((NSDictionary *) userInfo[@"aps"]).count >= 1 && userInfo[@"aps"][@"content-available"]) {
    [[RNFBRCTEventEmitter shared] sendEventWithName:@"messaging_message_received" body:[RNFBMessagingSerializer remoteMessageAppDataToDict:userInfo withMessageId:nil]];
  }
}

// APNS - only called on iOS versions greater than or equal to v10 (this one is officially supported)
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    NSLog(@"RNFNotification %@", userInfo);
  // send message event for remote notifications that have also have data
  if (userInfo[@"aps"] && ((NSDictionary *) userInfo[@"aps"]).count >= 1 && userInfo[@"aps"][@"content-available"]) {
    [[RNFBRCTEventEmitter shared] sendEventWithName:@"messaging_message_received" body:[RNFBMessagingSerializer remoteMessageAppDataToDict:userInfo withMessageId:nil]];
    // complete immediately
    completionHandler(UIBackgroundFetchResultNoData);
  }
}
@end
