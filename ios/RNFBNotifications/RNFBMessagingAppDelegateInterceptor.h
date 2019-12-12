
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <Firebase/Firebase.h>
#import <React/RCTBridgeModule.h>

NS_ASSUME_NONNULL_BEGIN


@interface RNFBMessagingAppDelegateInterceptor : NSObject <UIApplicationDelegate>

@property _Nullable RCTPromiseRejectBlock registerPromiseRejecter;
@property _Nullable RCTPromiseResolveBlock registerPromiseResolver;

+ (instancetype)sharedInstance;

- (void)setPromiseResolve:(RCTPromiseResolveBlock)resolve andPromiseReject:(RCTPromiseRejectBlock)reject;

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler;

@end

NS_ASSUME_NONNULL_END
