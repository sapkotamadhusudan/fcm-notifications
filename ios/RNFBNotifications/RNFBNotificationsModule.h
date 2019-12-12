#ifndef RNFBNotificationsModule_h
#define RNFBNotificationsModule_h


#import <Foundation/Foundation.h>

#if __has_include(<FirebaseMessaging/FirebaseMessaging.h>)
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <Firebase/Firebase.h>

@interface RNFBNotificationsModule : NSObject <RCTBridgeModule, FIRMessagingDelegate>

@end

#else
@interface RNFBNotificationsModule : NSObject
@end
#endif

#endif
