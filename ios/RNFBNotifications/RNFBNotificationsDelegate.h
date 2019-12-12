#import <Foundation/Foundation.h>

#import <Firebase/Firebase.h>
#import <React/RCTBridgeModule.h>

@interface RNFBNotificationDelegate : NSObject <FIRMessagingDelegate, UNUserNotificationCenterDelegate>

+ (_Nonnull instancetype) sharedInstance;

+ ( NSDictionary * _Nullable ) InitialNotification;

+ (void) jsInitialised;

@end
