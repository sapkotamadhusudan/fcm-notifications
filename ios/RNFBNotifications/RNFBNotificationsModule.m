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
 
#import <RNFBNotificationsModule.h>

#if __has_include(<FirebaseMessaging/FIRMessaging.h>)
#import <React/RCTUtils.h>
#import <React/RCTConvert.h>
#import <Firebase/Firebase.h>
#import <RNFBApp/RNFBSharedUtils.h>
#import <RNFBApp/RNFBRCTEventEmitter.h>
#import <UserNotifications/UserNotifications.h>

#import <RNFBNotificationsDelegate.h>
#import <RNFBNotificationUtils.h>
#import <RNFBNotificationSerializer.h>
#import <RNFBMessagingAppDelegateInterceptor.h>


@implementation RNFBNotificationsModule

#pragma mark -
#pragma mark Module Setup

RCT_EXPORT_MODULE();

- (id)init{
    self = [super init];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      // ensure shared instances are initialized early
      [RNFBNotificationDelegate sharedInstance];
      [RNFBMessagingAppDelegateInterceptor sharedInstance];
    });
    return self;
  }

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
  }

+ (BOOL)requiresMainQueueSetup {
    return YES;
  }

- (NSDictionary *)constantsToExport {
  NSMutableDictionary *constants = [NSMutableDictionary new];
  constants[@"isAutoInitEnabled"] = @([RCTConvert BOOL:@([FIRMessaging messaging].autoInitEnabled)]);
  constants[@"isRegisteredForRemoteNotifications"] = @([RCTConvert BOOL:@([[UIApplication sharedApplication] isRegisteredForRemoteNotifications])]);
  return constants;
}


#pragma mark -
#pragma mark Firebase Notifications Methods

RCT_EXPORT_METHOD(setAutoInitEnabled:
  (BOOL) enabled
    :(RCTPromiseResolveBlock) resolve
    :(RCTPromiseRejectBlock) reject
) {
  @try {
    [FIRMessaging messaging].autoInitEnabled = enabled;
  } @catch (NSException *exception) {
    return [RNFBSharedUtils rejectPromiseWithExceptionDict:reject exception:exception];
  }

  return resolve([NSNull null]);
}

RCT_EXPORT_METHOD(getToken:
  (NSString *) authorizedEntity
    :(NSString *) scope
    :(RCTPromiseResolveBlock) resolve
    :(RCTPromiseRejectBlock) reject
) {
  if ([UIApplication sharedApplication].isRegisteredForRemoteNotifications == NO) {
    [RNFBSharedUtils rejectPromiseWithUserInfo:reject userInfo:(NSMutableDictionary *) @{
        @"code": @"unregistered",
        @"message": @"You must be registered for remote notifications before calling get token, see messaging().registerForRemoteNotifications() or requestPermission().",
    }];
    return;
  }

NSDictionary *options = nil;
  if ([FIRMessaging messaging].APNSToken) {
    options = @{@"apns_token": [FIRMessaging messaging].APNSToken};
  }

  [[FIRInstanceID instanceID] tokenWithAuthorizedEntity:authorizedEntity scope:scope options:options handler:^(NSString *_Nullable identity, NSError *_Nullable error) {
    if (error) {
      [RNFBSharedUtils rejectPromiseWithNSError:reject error:error];
    } else {
      resolve(identity);
    }
  }];
}

RCT_EXPORT_METHOD(deleteToken:
  (NSString *) authorizedEntity
    :(NSString *) scope
    :(RCTPromiseResolveBlock) resolve
    :(RCTPromiseRejectBlock) reject
) {
  [[FIRInstanceID instanceID] deleteTokenWithAuthorizedEntity:authorizedEntity scope:scope handler:^(NSError *_Nullable error) {
    if (error) {
      [RNFBSharedUtils rejectPromiseWithNSError:reject error:error];
    } else {
      resolve([NSNull null]);
    }
  }];
}

RCT_EXPORT_METHOD(getAPNSToken:
  (RCTPromiseResolveBlock) resolve
    : (RCTPromiseRejectBlock) reject
) {
  NSData *apnsToken = [FIRMessaging messaging].APNSToken;
  if (apnsToken) {
    resolve([RNFBMessagingSerializer APNSTokenFromNSData:apnsToken]);
  } else {
    resolve([NSNull null]);
  }
}

RCT_EXPORT_METHOD(requestPermission:
  (RCTPromiseResolveBlock) resolve
    :(RCTPromiseRejectBlock) reject
) {
  if (RCTRunningInAppExtension()) {
    [RNFBSharedUtils rejectPromiseWithUserInfo:reject userInfo:[@{
        @"code": @"unavailable-in-extension",
        @"message": @"requestPermission can not be called in App Extensions"} mutableCopy]];
    return;
  }

  RCTPromiseResolveBlock customResolver = ^(id result) {
    if (@available(iOS 10.0, *)) {
      UNAuthorizationOptions authOptions;
      if (@available(iOS 12.0, *)) {
        authOptions = UNAuthorizationOptionProvisional | UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
      } else {
        authOptions = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
      }

      [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:authOptions completionHandler:^(BOOL granted, NSError *_Nullable error) {
        if (error) {
          [RNFBSharedUtils rejectPromiseWithNSError:reject error:error];
        } else {
          resolve(@([RCTConvert BOOL:@(granted)]));
        }
      }];
    } else {
      // TODO community iOS 9 support could be added here with `registerUserNotificationSettings:settings` & `didRegisterUserNotificationSettings`
      [RNFBSharedUtils rejectPromiseWithUserInfo:reject userInfo:[@{
          @"code": @"unsupported-platform-version",
          @"message": @"requestPermission call failed; minimum supported version requirement not met (iOS 10)."} mutableCopy]];
    }
  };

  if ([UIApplication sharedApplication].isRegisteredForRemoteNotifications == YES) {
    customResolver(nil);
  } else {
    [[RNFBMessagingAppDelegateInterceptor sharedInstance] setPromiseResolve:customResolver andPromiseReject:reject];
    dispatch_async(dispatch_get_main_queue(), ^{
      [[UIApplication sharedApplication] registerForRemoteNotifications];
    });
  }
}

RCT_EXPORT_METHOD(registerForRemoteNotifications:
  (RCTPromiseResolveBlock) resolve
    : (RCTPromiseRejectBlock) reject
) {
  if ([UIApplication sharedApplication].isRegisteredForRemoteNotifications == YES) {
    return resolve(@([RCTConvert BOOL:@(YES)]));
  }

  [[RNFBMessagingAppDelegateInterceptor sharedInstance] setPromiseResolve:resolve andPromiseReject:reject];
  [[UIApplication sharedApplication] registerForRemoteNotifications];
}


RCT_EXPORT_METHOD(unregisterForRemoteNotifications:
  (RCTPromiseResolveBlock) resolve
    :(RCTPromiseRejectBlock) reject
) {
  [[UIApplication sharedApplication] unregisterForRemoteNotifications];
  resolve(nil);
}

RCT_EXPORT_METHOD(hasPermission:
  (RCTPromiseResolveBlock) resolve
    :(RCTPromiseRejectBlock) reject
) {
  if (@available(iOS 10.0, *)) {
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *_Nonnull settings) {
      BOOL hasPermission = [RCTConvert BOOL:@(settings.authorizationStatus >= UNAuthorizationStatusAuthorized)];
      resolve(@(hasPermission));
    }];
  } else {
    // TODO community iOS 9 support could be added here via application `currentUserNotificationSettings`.types != UIUserNotificationTypeNone
    [RNFBSharedUtils rejectPromiseWithUserInfo:reject userInfo:[@{
        @"code": @"unsupported-platform-version",
        @"message": @"hasPermission call failed; minimum supported version requirement not met (iOS 10)."} mutableCopy]];
  }
}

RCT_EXPORT_METHOD(subscribeToTopic:
  (NSString *) topic
    :(RCTPromiseResolveBlock) resolve
    :(RCTPromiseRejectBlock) reject
) {
  [[FIRMessaging messaging] subscribeToTopic:topic completion:^(NSError *error) {
    if (error) {
      [RNFBSharedUtils rejectPromiseWithNSError:reject error:error];
    } else {
      resolve(nil);
    }
  }];
}

RCT_EXPORT_METHOD(unsubscribeFromTopic:
  (NSString *) topic
    :(RCTPromiseResolveBlock) resolve
    :(RCTPromiseRejectBlock) reject
) {
  [[FIRMessaging messaging] unsubscribeFromTopic:topic completion:^(NSError *error) {
    if (error) {
      [RNFBSharedUtils rejectPromiseWithNSError:reject error:error];
    } else {
      resolve(nil);
    }
  }];
}

#pragma mark -
#pragma mark Firebase Local Notifications Methods

RCT_EXPORT_METHOD(displayNotification:(NSDictionary*) notification
                             resolver:(RCTPromiseResolveBlock)resolve
                             rejecter:(RCTPromiseRejectBlock)reject) {
    if ([RNFBNotificationUtils isIOS89]) {
        UILocalNotification* notif = [RNFBNotificationUtils buildUILocalNotification:notification withSchedule:false];
        [RCTSharedApplication() presentLocalNotificationNow:notif];
        resolve(nil);
    } else {
        if (@available(iOS 10.0, *)) {
            UNNotificationRequest* request = [RNFBNotificationUtils buildUNNotificationRequest:notification withSchedule:false];
            [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (!error) {
                    resolve(nil);
                } else{
                    reject(@"notifications/display_notification_error", @"Failed to display notificaton", error);
                }
            }];
        }
    }
}

RCT_EXPORT_METHOD(cancelNotification:(NSString*) notificationId
                            resolver:(RCTPromiseResolveBlock)resolve
                            rejecter:(RCTPromiseRejectBlock)reject) {
    if ([RNFBNotificationUtils isIOS89]) {
        for (UILocalNotification *notification in RCTSharedApplication().scheduledLocalNotifications) {
            NSDictionary *notificationInfo = notification.userInfo;
            if ([notificationId isEqualToString:notificationInfo[@"notificationId"]]) {
                [RCTSharedApplication() cancelLocalNotification:notification];
            }
        }
    } else {
        if (@available(iOS 10.0, *)) {
            UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
            if (notificationCenter != nil) {
                [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:@[notificationId]];
            }
        }
    }
    resolve(nil);
}


RCT_EXPORT_METHOD(cancelAllNotifications:(RCTPromiseResolveBlock)resolve
                                rejecter:(RCTPromiseRejectBlock)reject) {
    if ([RNFBNotificationUtils isIOS89]) {
        [RCTSharedApplication() cancelAllLocalNotifications];
    } else {
        if (@available(iOS 10.0, *)) {
            UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
            if (notificationCenter != nil) {
                [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
            }
        }
    }
    resolve(nil);
}

RCT_EXPORT_METHOD(getBadge: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        resolve(@([RCTSharedApplication() applicationIconBadgeNumber]));
    });
}



RCT_EXPORT_METHOD(getInitialNotification:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    // Check if we've cached an initial notification as this will contain the accurate action
    NSDictionary * _Nullable  initialNotification = [RNFBNotificationDelegate InitialNotification];
    
    
    if (initialNotification) {
        resolve(initialNotification);
    }
    
    RCTBridge *bridge = [[RNFBRCTEventEmitter shared] bridge];
    if (bridge != nil && bridge.launchOptions[UIApplicationLaunchOptionsLocalNotificationKey]) {
        UILocalNotification *localNotification = bridge.launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
        
        resolve(@{
            @"action": DEFAULT_ACTION,
            @"notification": [RNFBNotificationUtils parseUILocalNotification:localNotification]
        });
    }
    else if (bridge != nil && bridge.launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        NSDictionary *remoteNotification = bridge.launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
        resolve(@{
                  @"action": DEFAULT_ACTION,
                  @"notification": [RNFBNotificationUtils parseUserInfo:remoteNotification]
                  });
    } else {
        resolve(nil);
    }
}

RCT_EXPORT_METHOD(removeAllDeliveredNotifications:(RCTPromiseResolveBlock)resolve
                                         rejecter:(RCTPromiseRejectBlock)reject) {
    if ([RNFBNotificationUtils isIOS89]) {
        // No such functionality on iOS 8/9
    } else {
        if (@available(iOS 10.0, *)) {
            UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
            if (notificationCenter != nil) {
                [[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
            }
        }
    }
    resolve(nil);
}

RCT_EXPORT_METHOD(removeDeliveredNotification:(NSString*) notificationId
                                     resolver:(RCTPromiseResolveBlock)resolve
                                     rejecter:(RCTPromiseRejectBlock)reject) {
    if ([RNFBNotificationUtils isIOS89]) {
        // No such functionality on iOS 8/9
    } else {
        if (@available(iOS 10.0, *)) {
            UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
            if (notificationCenter != nil) {
                [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:@[notificationId]];
            }
        }
    }
    resolve(nil);
}


RCT_EXPORT_METHOD(scheduleNotification:(NSDictionary*) notification
                              resolver:(RCTPromiseResolveBlock)resolve
                              rejecter:(RCTPromiseRejectBlock)reject) {
    if ([RNFBNotificationUtils isIOS89]) {
        UILocalNotification* notif = [RNFBNotificationUtils buildUILocalNotification:notification withSchedule:true];
        [RCTSharedApplication() scheduleLocalNotification:notif];
        resolve(nil);
    } else {
        if (@available(iOS 10.0, *)) {
            UNNotificationRequest* request = [RNFBNotificationUtils buildUNNotificationRequest:notification withSchedule:true];
            [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (!error) {
                    resolve(nil);
                } else{
                    reject(@"notification/schedule_notification_error", @"Failed to schedule notificaton", error);
                }
            }];
        }
    }
}

RCT_EXPORT_METHOD(setBadge:(NSInteger) number
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [RCTSharedApplication() setApplicationIconBadgeNumber:number];
        resolve(nil);
    });
}

RCT_EXPORT_METHOD(jsInitialised:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    [RNFBNotificationDelegate jsInitialised];
    resolve(nil);
}

@end

#else
@implementation RNFirebaseNotifications
@end
#endif
