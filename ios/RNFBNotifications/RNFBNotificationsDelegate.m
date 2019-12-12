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

#import <React/RCTConvert.h>
#import "RNFBApp/RNFBRCTEventEmitter.h"
#import <UserNotifications/UserNotifications.h>

#import "RNFBNotificationsDelegate.h"
#import "RNFBNotificationSerializer.h"
#import "RNFBNotificationUtils.h"



@implementation RNFBNotificationDelegate{
    NSMutableDictionary<NSString *, void (^)(UIBackgroundFetchResult)> *fetchCompletionHandlers;
    NSMutableDictionary<NSString *, void(^)(void)> *completionHandlers;
}

static RNFBNotificationDelegate *theRNFBNotificationDelegate = nil;
// PRE-BRIDGE-EVENTS: Consider enabling this to allow events built up before the bridge is built to be sent to the JS side
static NSMutableArray *pendingEvents = nil;
static NSDictionary *initialNotification = nil;
static bool jsReady = FALSE;

+ (instancetype)sharedInstance {
  static dispatch_once_t once;
  static RNFBNotificationDelegate *sharedInstance;
  dispatch_once(&once, ^{
    sharedInstance = [[RNFBNotificationDelegate alloc] init];

    [FIRMessaging messaging].delegate = sharedInstance;
    [FIRMessaging messaging].shouldEstablishDirectChannel = YES;
    
  });
  return sharedInstance;
}

+ (void)configure {
    // PRE-BRIDGE-EVENTS: Consider enabling this to allow events built up before the bridge is built to be sent to the JS side
    pendingEvents = [[NSMutableArray alloc] init];
    theRNFBNotificationDelegate = [self sharedInstance];
    
}

+ (void) jsInitialised {
    jsReady = TRUE;
}

- (id)init {
    self = [super init];
    if (self != nil) {
        NSLog(@"Setting up RNFBNotificationDelegate instance");
        [self initialise];
    }
    return self;
}

- (void)initialise {
    // If we're on iOS 10 then we need to set this as a delegate for the UNUserNotificationCenter
    if (@available(iOS 10.0, *)) {
        [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    }

    // Set static instance for use from AppDelegate
    theRNFBNotificationDelegate = self;
    completionHandlers = [[NSMutableDictionary alloc] init];
    fetchCompletionHandlers = [[NSMutableDictionary alloc] init];
}

+ (NSDictionary *) InitialNotification{
    return [initialNotification copy];
}

#pragma mark -
#pragma mark UNUserNotificationCenter Methods

// *******************************************************
// ** Start AppDelegate methods
// ** iOS 8/9 Only
// *******************************************************
- (void)didReceiveLocalNotification:(nonnull UILocalNotification *)localNotification {
    if ([RNFBNotificationUtils isIOS89]) {
        NSString *event;
        if (RCTSharedApplication().applicationState == UIApplicationStateBackground) {
            event = NOTIFICATIONS_NOTIFICATION_DISPLAYED;
        } else if (RCTSharedApplication().applicationState == UIApplicationStateInactive) {
            event = NOTIFICATIONS_NOTIFICATION_OPENED;
        } else {
            event = NOTIFICATIONS_NOTIFICATION_RECEIVED;
        }

        NSDictionary *notification = [RNFBNotificationUtils parseUILocalNotification:localNotification];
        if (event == NOTIFICATIONS_NOTIFICATION_OPENED) {
            notification = @{
                             @"action": DEFAULT_ACTION,
                             @"notification": notification
                             };
        }
        [self sendJSEvent:event body:notification];
    }
}


#pragma mark -
#pragma mark FIRMessagingDelegate Methods

// ----------------------
//     TOKEN Message
// --------------------\/


// JS -> `onTokenRefresh`
- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
  [[RNFBRCTEventEmitter shared] sendEventWithName:@"messaging_token_refresh" body:@{
      @"token": fcmToken
  }];
}

// ----------------------
//      DATA Message
// --------------------\/

// JS -> `onMessage`
// Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
// To enable direct data messages, you can set [Messaging messaging].shouldEstablishDirectChannel to YES.
- (void)messaging:(nonnull FIRMessaging *)messaging didReceiveMessage:(nonnull FIRMessagingRemoteMessage *)remoteMessage {
  [[RNFBRCTEventEmitter shared] sendEventWithName:@"messaging_message_received" body:[RNFBMessagingSerializer remoteMessageToDict:remoteMessage]];
}


// Listen for background messages
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
              fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // FCM Data messages come through here if they specify content-available=true
    if (userInfo[@"aps"] && ((NSDictionary*)userInfo[@"aps"]).count == 1 && userInfo[@"aps"][@"content-available"]) {
        [[RNFBRCTEventEmitter shared] sendEventWithName:@"notifications_notification_received" body:[RNFBMessagingSerializer remoteMessageAppDataToDict:userInfo withMessageId:nil]];
          // complete immediately
          completionHandler(UIBackgroundFetchResultNoData);
        return;
    }

    NSDictionary *notification = [RNFBNotificationUtils parseUserInfo:userInfo];
    NSString *handlerKey = notification[@"notificationId"];

    NSString *event;
    if (RCTSharedApplication().applicationState == UIApplicationStateBackground) {
        event = NOTIFICATIONS_NOTIFICATION_DISPLAYED;
    } else if ([RNFBNotificationUtils isIOS89]) {
        if (RCTSharedApplication().applicationState == UIApplicationStateInactive) {
            event = NOTIFICATIONS_NOTIFICATION_OPENED;
        } else {
            event = NOTIFICATIONS_NOTIFICATION_RECEIVED;
        }
    } else {
        // On IOS 10:
        // - foreground notifications also go through willPresentNotification
        // - background notification presses also go through didReceiveNotificationResponse
        // This prevents duplicate messages from hitting the JS app
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }

//    // For onOpened events, we set the default action name as iOS 8/9 has no concept of actions
    if (event == NOTIFICATIONS_NOTIFICATION_OPENED) {
        notification = @{
            @"action": DEFAULT_ACTION,
            @"notification": notification
        };
    }

    if (handlerKey != nil) {
        fetchCompletionHandlers[handlerKey] = completionHandler;
    } else {
        completionHandler(UIBackgroundFetchResultNoData);
    }
    
    [self sendJSEvent:event body:notification];
}

// *******************************************************
// ** Finish AppDelegate methods
// *******************************************************

// *******************************************************
// ** Start UNUserNotificationCenterDelegate methods
// ** iOS 10+
// *******************************************************

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
// Handle incoming notification messages while app is in the foreground.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler NS_AVAILABLE_IOS(10_0) {
    UNNotificationTrigger *trigger = notification.request.trigger;
    BOOL isFcm = trigger && [notification.request.trigger class] == [UNPushNotificationTrigger class];
    BOOL isScheduled = trigger && [notification.request.trigger class] == [UNCalendarNotificationTrigger class];

    NSString *event;
    UNNotificationPresentationOptions options;
    NSDictionary *message = [RNFBNotificationUtils parseUNNotification:notification];

    if (isFcm || isScheduled) {
        // If app is in the background
        if (RCTSharedApplication().applicationState == UIApplicationStateBackground
            || RCTSharedApplication().applicationState == UIApplicationStateInactive) {
            // display the notification
            options = UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound;
            // notification_displayed
            event = NOTIFICATIONS_NOTIFICATION_DISPLAYED;
        } else {
            // don't show notification
            options = UNNotificationPresentationOptionNone;
            // notification_received
            event = NOTIFICATIONS_NOTIFICATION_RECEIVED;
        }
    } else {
        // Triggered by `notifications().displayNotification(notification)`
        // Display the notification
        options = UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound;
        // notification_displayed
        event = NOTIFICATIONS_NOTIFICATION_DISPLAYED;
    }

    [self sendJSEvent:event body:message];
    completionHandler(options);
}

// Handle notification messages after display notification is tapped by the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
#if defined(__IPHONE_11_0)
         withCompletionHandler:(void(^)(void))completionHandler NS_AVAILABLE_IOS(10_0) {
#else
         withCompletionHandler:(void(^)())completionHandler NS_AVAILABLE_IOS(10_0) {
#endif
     NSDictionary *message = [RNFBNotificationUtils parseUNNotificationResponse:response];
           
     NSString *handlerKey = message[@"notification"][@"notificationId"];
             
    [self sendJSEvent:NOTIFICATIONS_NOTIFICATION_OPENED body:message];

     if (handlerKey != nil) {
         completionHandlers[handlerKey] = completionHandler;
     } else {
         completionHandler();
     }
}

#endif


    // Because of the time delay between the app starting and the bridge being initialised
    // we create a temporary instance of RNFirebaseNotifications.
    // With this temporary instance, we cache any events to be sent as soon as the bridge is set on the module
    - (void)sendJSEvent:(NSString *)name body:(id)body {
        RNFBRCTEventEmitter *emitter = [RNFBRCTEventEmitter shared];
        if (emitter.bridge && jsReady) {
            [emitter sendEventWithName:name body:body];
        } else {
            if ([name isEqualToString:NOTIFICATIONS_NOTIFICATION_OPENED] && !initialNotification) {
                initialNotification = body;
            } else if ([name isEqualToString:NOTIFICATIONS_NOTIFICATION_OPENED]) {
                NSLog(@"Multiple notification open events received before the JS Notifications module has been initialised");
            }
            // PRE-BRIDGE-EVENTS: Consider enabling this to allow events built up before the bridge is built to be sent to the JS side
             //[pendingEvents addObject:@{@"name":name, @"body":body}];
        }
    }
    
@end
