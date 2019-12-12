#import <Foundation/Foundation.h>

#import <React/RCTBridgeModule.h>
#import <Firebase/Firebase.h>

@interface RNFBMessagingSerializer : NSObject

+ (NSString *)APNSTokenFromNSData:(NSData *)tokenData;

+ (NSDictionary *)remoteMessageToDict:(FIRMessagingRemoteMessage *)remoteMessage;

+ (NSDictionary *)remoteMessageAppDataToDict:(NSDictionary *)appData withMessageId:(nullable NSString *)messageId;

@end
