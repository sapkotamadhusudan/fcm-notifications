#import "RNFBNotificationSerializer.h"

@implementation RNFBMessagingSerializer

+ (NSString *)APNSTokenFromNSData:(NSData *)tokenData {
  const char *data = [tokenData bytes];

  NSMutableString *token = [NSMutableString string];
  for (NSInteger i = 0; i < tokenData.length; i++) {
    [token appendFormat:@"%02.2hhX", data[i]];
  }

  return [token copy];
}

+ (NSDictionary *)remoteMessageToDict:(FIRMessagingRemoteMessage *)remoteMessage {
  return [self remoteMessageAppDataToDict:remoteMessage.appData withMessageId:remoteMessage.messageID];
}


+ (NSDictionary *)remoteMessageAppDataToDict:(NSDictionary *)appData withMessageId:(nullable NSString *)messageId {
  NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
  NSMutableDictionary *message = [[NSMutableDictionary alloc] init];

  if (messageId != nil) {
    message[@"messageId"] = messageId;
  }

  for (id key in appData) {
    // messageId
    if ([key isEqualToString:@"gcm.message_id"] || [key isEqualToString:@"google.message_id"] || [key isEqualToString:@"message_id"]) {
      message[@"messageId"] = appData[key];
      continue;
    }

    // messageType
    if ([key isEqualToString:@"message_type"]) {
      message[@"messageType"] = appData[key];
      continue;
    }

    // collapseKey
    if ([key isEqualToString:@"collapse_key"]) {
      message[@"collapseKey"] = appData[key];
      continue;
    }

    // from
    if ([key isEqualToString:@"from"]) {
      message[@"from"] = appData[key];
      continue;
    }

    // sentTime
    if ([key isEqualToString:@"google.c.a.ts"]) {
      message[@"sentTime"] = appData[key];
    }

    // to
    if ([key isEqualToString:@"to"] || [key isEqualToString:@"google.to"]) {
      message[@"to"] = appData[key];
    }

    // skip keys that shouldn't be included
    if ([key isEqualToString:@"notification"] || [key hasPrefix:@"gcm."] || [key hasPrefix:@"google."]) {
      continue;
    }

    data[key] = appData[key];
  }

  message[@"data"] = data;
  return message;
}

@end
