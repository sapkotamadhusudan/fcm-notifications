#ifndef RNFBNotificationUtils_h
#define RNFBNotificationUtils_h

#import <FirebaseCore/FirebaseCore.h>
#import "RCTBridgeModule.h"

// For iOS 10 we need to implement UNUserNotificationCenterDelegate to receive display
// notifications via APNS
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@import UserNotifications;
#endif


@interface RNFBNotificationUtils : NSObject {}

#pragma mark -
#pragma mark Constants

extern NSString *const NOTIFICATIONS_NOTIFICATION_DISPLAYED = @"notifications_notification_displayed";
extern NSString *const NOTIFICATIONS_NOTIFICATION_OPENED = @"notifications_notification_opened";
extern NSString *const NOTIFICATIONS_NOTIFICATION_RECEIVED = @"notifications_notification_received";
extern NSString *const DEFAULT_ACTION = @"com.apple.UNNotificationDefaultActionIdentifier";

#pragma mark -
#pragma mark Methods

+ (UILocalNotification*) buildUILocalNotification:(NSDictionary *) notification withSchedule:(BOOL) withSchedule ;

+ (UNNotificationRequest*) buildUNNotificationRequest:(NSDictionary *) notification
withSchedule:(BOOL) withSchedule NS_AVAILABLE_IOS(10_0);

+ (NSDictionary*) parseUILocalNotification:(UILocalNotification *) localNotification;

+ (NSDictionary*)parseUNNotificationResponse:(UNNotificationResponse *)response NS_AVAILABLE_IOS(10_0);

+ (NSDictionary*)parseUNNotification:(UNNotification *)notification NS_AVAILABLE_IOS(10_0);

+ (NSDictionary*) parseUNNotificationRequest:(UNNotificationRequest *) notificationRequest NS_AVAILABLE_IOS(10_0);

+ (NSDictionary*)parseUserInfo:(NSDictionary *)userInfo;

+ (NSArray<NSString *> *)supportedEvents;

+ (BOOL *)isIOS89;

@end

#endif
