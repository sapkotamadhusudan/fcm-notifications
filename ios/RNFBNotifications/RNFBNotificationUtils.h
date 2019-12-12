/*
 * Copyright (c) 2019-present Madhusudan Sapkota & Contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this library except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

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
