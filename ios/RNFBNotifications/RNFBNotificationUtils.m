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
 
#import "RNFBRCTEventEmitter.h"
#import "RNFBNotificationUtils.h"

// For iOS 10 we need to implement UNUserNotificationCenterDelegate to receive display
// notifications via APNS
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@import UserNotifications;
#endif



#pragma mark -
#pragma mark Constants


@implementation RNFBNotificationUtils {
    
}

#pragma mark -
#pragma mark Methods

+ (BOOL)isIOS89 {
    return floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max;
}


+ (UILocalNotification*) buildUILocalNotification:(NSDictionary *) notification
                                     withSchedule:(BOOL) withSchedule {
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    if (notification[@"body"]) {
        localNotification.alertBody = notification[@"body"];
    }
    if (notification[@"data"]) {
        localNotification.userInfo = notification[@"data"];
    }
    if (notification[@"sound"]) {
        localNotification.soundName = notification[@"sound"];
    }
    if (notification[@"title"]) {
        localNotification.alertTitle = notification[@"title"];
    }
    if (notification[@"ios"]) {
        NSDictionary *ios = notification[@"ios"];
        if (ios[@"alertAction"]) {
            localNotification.alertAction = ios[@"alertAction"];
        }
        if (ios[@"badge"]) {
            NSNumber *badge = ios[@"badge"];
            localNotification.applicationIconBadgeNumber = badge.integerValue;
        }
        if (ios[@"category"]) {
            localNotification.category = ios[@"category"];
        }
        if (ios[@"hasAction"]) {
            localNotification.hasAction = ios[@"hasAction"];
        }
        if (ios[@"launchImage"]) {
            localNotification.alertLaunchImage = ios[@"launchImage"];
        }
    }
    if (withSchedule) {
        NSDictionary *schedule = notification[@"schedule"];
        NSNumber *fireDateNumber = schedule[@"fireDate"];
        NSDate *fireDate = [NSDate dateWithTimeIntervalSince1970:([fireDateNumber doubleValue] / 1000.0)];
        localNotification.fireDate = fireDate;

        NSString *interval = schedule[@"repeatInterval"];
        if (interval) {
            if ([interval isEqualToString:@"minute"]) {
                localNotification.repeatInterval = NSCalendarUnitMinute;
            } else if ([interval isEqualToString:@"hour"]) {
                localNotification.repeatInterval = NSCalendarUnitHour;
            } else if ([interval isEqualToString:@"day"]) {
                localNotification.repeatInterval = NSCalendarUnitDay;
            } else if ([interval isEqualToString:@"week"]) {
                localNotification.repeatInterval = NSCalendarUnitWeekday;
            }
        }

    }

    return localNotification;
}

+ (UNNotificationRequest*) buildUNNotificationRequest:(NSDictionary *) notification
                                         withSchedule:(BOOL) withSchedule NS_AVAILABLE_IOS(10_0) {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    if (notification[@"body"]) {
        content.body = notification[@"body"];
    }
    if (notification[@"data"]) {
        content.userInfo = notification[@"data"];
    }
    if (notification[@"sound"]) {
        if ([@"default" isEqualToString:notification[@"sound"]]) {
            content.sound = [UNNotificationSound defaultSound];
        } else {
            content.sound = [UNNotificationSound soundNamed:notification[@"sound"]];
        }
    }
    if (notification[@"subtitle"]) {
        content.subtitle = notification[@"subtitle"];
    }
    if (notification[@"title"]) {
        content.title = notification[@"title"];
    }
    if (notification[@"ios"]) {
        NSDictionary *ios = notification[@"ios"];
        if (ios[@"attachments"]) {
            NSMutableArray *attachments = [[NSMutableArray alloc] init];
            for (NSDictionary *a in ios[@"attachments"]) {
                NSString *identifier = a[@"identifier"];
                NSURL *url = [NSURL fileURLWithPath:a[@"url"]];
                NSMutableDictionary *attachmentOptions = nil;

                if (a[@"options"]) {
                    NSDictionary *options = a[@"options"];
                    attachmentOptions = [[NSMutableDictionary alloc] init];

                    for (id key in options) {
                        if ([key isEqualToString:@"typeHint"]) {
                            attachmentOptions[UNNotificationAttachmentOptionsTypeHintKey] = options[key];
                        } else if ([key isEqualToString:@"thumbnailHidden"]) {
                            attachmentOptions[UNNotificationAttachmentOptionsThumbnailHiddenKey] = options[key];
                        } else if ([key isEqualToString:@"thumbnailClippingRect"]) {
                            attachmentOptions[UNNotificationAttachmentOptionsThumbnailClippingRectKey] = options[key];
                        } else if ([key isEqualToString:@"thumbnailTime"]) {
                            attachmentOptions[UNNotificationAttachmentOptionsThumbnailTimeKey] = options[key];
                        }
                    }
                }

                NSError *error;
                UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:identifier URL:url options:attachmentOptions error:&error];
                if (attachment) {
                    [attachments addObject:attachment];
                } else {
                    NSLog(@"Failed to create attachment: %@", error);
                }
            }
            content.attachments = attachments;
        }

        if (ios[@"badge"]) {
            content.badge = ios[@"badge"];
        }
        if (ios[@"category"]) {
            content.categoryIdentifier = ios[@"category"];
        }
        if (ios[@"launchImage"]) {
            content.launchImageName = ios[@"launchImage"];
        }
        if (ios[@"threadIdentifier"]) {
            content.threadIdentifier = ios[@"threadIdentifier"];
        }
    }

    if (withSchedule) {
        NSDictionary *schedule = notification[@"schedule"];
        NSNumber *fireDateNumber = schedule[@"fireDate"];
        NSString *interval = schedule[@"repeatInterval"];
        NSDate *fireDate = [NSDate dateWithTimeIntervalSince1970:([fireDateNumber doubleValue] / 1000.0)];

        NSCalendarUnit calendarUnit;
        if (interval) {
            if ([interval isEqualToString:@"minute"]) {
                calendarUnit = NSCalendarUnitSecond;
            } else if ([interval isEqualToString:@"hour"]) {
                calendarUnit = NSCalendarUnitMinute | NSCalendarUnitSecond;
            } else if ([interval isEqualToString:@"day"]) {
                calendarUnit = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
            } else if ([interval isEqualToString:@"week"]) {
                calendarUnit = NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
            } else {
                calendarUnit = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
            }
        } else {
            // Needs to match exactly to the second
            calendarUnit = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
        }

        NSDateComponents *components = [[NSCalendar currentCalendar] components:calendarUnit fromDate:fireDate];
        UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:interval];
        return [UNNotificationRequest requestWithIdentifier:notification[@"notificationId"] content:content trigger:trigger];
    } else {
        return [UNNotificationRequest requestWithIdentifier:notification[@"notificationId"] content:content trigger:nil];
    }
}

+ (NSDictionary*) parseUILocalNotification:(UILocalNotification *) localNotification {
    NSMutableDictionary *notification = [[NSMutableDictionary alloc] init];

    if (localNotification.alertBody) {
        notification[@"body"] = localNotification.alertBody;
    }
    if (localNotification.userInfo) {
        notification[@"data"] = localNotification.userInfo;
    }
    if (localNotification.soundName) {
        notification[@"sound"] = localNotification.soundName;
    }
    if (localNotification.alertTitle) {
         notification[@"title"] = localNotification.alertTitle;
    }

    NSMutableDictionary *ios = [[NSMutableDictionary alloc] init];
    if (localNotification.alertAction) {
        ios[@"alertAction"] = localNotification.alertAction;
    }
    if (localNotification.applicationIconBadgeNumber) {
        ios[@"badge"] = @(localNotification.applicationIconBadgeNumber);
    }
    if (localNotification.category) {
        ios[@"category"] = localNotification.category;
    }
    if (localNotification.hasAction) {
        ios[@"hasAction"] = @(localNotification.hasAction);
    }
    if (localNotification.alertLaunchImage) {
        ios[@"launchImage"] = localNotification.alertLaunchImage;
    }
    notification[@"ios"] = ios;

    return notification;
}

+ (NSDictionary*)parseUNNotificationResponse:(UNNotificationResponse *)response NS_AVAILABLE_IOS(10_0) {
     NSMutableDictionary *notificationResponse = [[NSMutableDictionary alloc] init];
     NSDictionary *notification = [self parseUNNotification:response.notification];
     notificationResponse[@"notification"] = notification;
     notificationResponse[@"action"] = response.actionIdentifier;
     if ([response isKindOfClass:[UNTextInputNotificationResponse class]]) {
         notificationResponse[@"results"] = @{@"resultKey": ((UNTextInputNotificationResponse *)response).userText};
     }

     return notificationResponse;
}

+ (NSDictionary*)parseUNNotification:(UNNotification *)notification NS_AVAILABLE_IOS(10_0) {
    return [self parseUNNotificationRequest:notification.request];
}

+ (NSDictionary*) parseUNNotificationRequest:(UNNotificationRequest *) notificationRequest NS_AVAILABLE_IOS(10_0) {
    NSMutableDictionary *notification = [[NSMutableDictionary alloc] init];

    notification[@"notificationId"] = notificationRequest.identifier;

    if (notificationRequest.content.body) {
        notification[@"body"] = notificationRequest.content.body;
    }
    if (notificationRequest.content.userInfo) {
        NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
        for (id k in notificationRequest.content.userInfo) {
            if ([k isEqualToString:@"aps"]
                || [k isEqualToString:@"gcm.message_id"]) {
                // ignore as these are handled by the OS
            } else {
                data[k] = notificationRequest.content.userInfo[k];
            }
        }
        notification[@"data"] = data;
    }
    if (notificationRequest.content.sound) {
        notification[@"sound"] = notificationRequest.content.sound;
    }
    if (notificationRequest.content.subtitle) {
        notification[@"subtitle"] = notificationRequest.content.subtitle;
    }
    if (notificationRequest.content.title) {
        notification[@"title"] = notificationRequest.content.title;
    }

    NSMutableDictionary *ios = [[NSMutableDictionary alloc] init];

    if (notificationRequest.content.attachments) {
        NSMutableArray *attachments = [[NSMutableArray alloc] init];
        for (UNNotificationAttachment *a in notificationRequest.content.attachments) {
            NSMutableDictionary *attachment = [[NSMutableDictionary alloc] init];
            attachment[@"identifier"] = a.identifier;
            attachment[@"type"] = a.type;
            attachment[@"url"] = [a.URL absoluteString];
            [attachments addObject:attachment];
        }
        ios[@"attachments"] = attachments;
    }

    if (notificationRequest.content.badge) {
        ios[@"badge"] = notificationRequest.content.badge;
    }
    if (notificationRequest.content.categoryIdentifier) {
        ios[@"category"] = notificationRequest.content.categoryIdentifier;
    }
    if (notificationRequest.content.launchImageName) {
        ios[@"launchImage"] = notificationRequest.content.launchImageName;
    }
    if (notificationRequest.content.threadIdentifier) {
        ios[@"threadIdentifier"] = notificationRequest.content.threadIdentifier;
    }
    notification[@"ios"] = ios;

    return notification;
}

+ (NSDictionary*)parseUserInfo:(NSDictionary *)userInfo {

    NSMutableDictionary *notification = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *ios = [[NSMutableDictionary alloc] init];

    for (id k1 in userInfo) {
        if ([k1 isEqualToString:@"aps"]) {
            NSDictionary *aps = userInfo[k1];
            for (id k2 in aps) {
                if ([k2 isEqualToString:@"alert"]) {
                    // alert can be a plain text string rather than a dictionary
                    if ([aps[k2] isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *alert = aps[k2];
                        for (id k3 in alert) {
                            if ([k3 isEqualToString:@"body"]) {
                                notification[@"body"] = alert[k3];
                            } else if ([k3 isEqualToString:@"subtitle"]) {
                                notification[@"subtitle"] = alert[k3];
                            } else if ([k3 isEqualToString:@"title"]) {
                                notification[@"title"] = alert[k3];
                            } else if ([k3 isEqualToString:@"loc-args"]
                                       || [k3 isEqualToString:@"loc-key"]
                                       || [k3 isEqualToString:@"title-loc-args"]
                                       || [k3 isEqualToString:@"title-loc-key"]) {
                                // Ignore known keys
                            } else {
                                NSLog(@"Unknown alert key: %@", k2);
                            }
                        }
                    } else {
                        notification[@"title"] = aps[k2];
                    }
                } else if ([k2 isEqualToString:@"badge"]) {
                    ios[@"badge"] = aps[k2];
                } else if ([k2 isEqualToString:@"category"]) {
                    ios[@"category"] = aps[k2];
                } else if ([k2 isEqualToString:@"sound"]) {
                    notification[@"sound"] = aps[k2];
                } else {
                    NSLog(@"Unknown aps key: %@", k2);
                }
            }
        } else if ([k1 isEqualToString:@"gcm.message_id"]) {
            notification[@"notificationId"] = userInfo[k1];
        } else if ([k1 isEqualToString:@"gcm.n.e"]
                   || [k1 isEqualToString:@"gcm.notification.sound2"]
                   || [k1 isEqualToString:@"google.c.a.c_id"]
                   || [k1 isEqualToString:@"google.c.a.c_l"]
                   || [k1 isEqualToString:@"google.c.a.e"]
                   || [k1 isEqualToString:@"google.c.a.udt"]
                   || [k1 isEqualToString:@"google.c.a.ts"]) {
            // Ignore known keys
        } else {
            // Assume custom data
            data[k1] = userInfo[k1];
        }
    }

    notification[@"data"] = data;
    notification[@"ios"] = ios;

    return notification;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[NOTIFICATIONS_NOTIFICATION_DISPLAYED, NOTIFICATIONS_NOTIFICATION_OPENED, NOTIFICATIONS_NOTIFICATION_RECEIVED];
}

@end
