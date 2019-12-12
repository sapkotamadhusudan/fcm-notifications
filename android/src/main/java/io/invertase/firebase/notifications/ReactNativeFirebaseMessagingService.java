package io.invertase.firebase.notifications;

import android.content.ComponentName;
import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;

import com.facebook.react.HeadlessJsTaskService;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import io.invertase.firebase.common.ReactNativeFirebaseEventEmitter;
import io.invertase.firebase.common.SharedUtils;

public class ReactNativeFirebaseMessagingService extends FirebaseMessagingService {
  private static final String TAG = "RNFirebaseMsgService";

  @Override
  public void onNewToken(@NonNull String token) {
    ReactNativeFirebaseEventEmitter emitter = ReactNativeFirebaseEventEmitter.getSharedInstance();
    emitter.sendEvent(ReactNativeFirebaseNotificationSerializer.newTokenToTokenEvent(token));
  }

  @Override
  public void onMessageReceived(@NonNull RemoteMessage remoteMessage) {
    Log.d(TAG, "onMessageReceived");
    ReactNativeFirebaseEventEmitter emitter = ReactNativeFirebaseEventEmitter.getSharedInstance();

    // ----------------------
    //  NOTIFICATION Message
    // --------------------\/
    //
    if (SharedUtils.isAppInForeground(this) && remoteMessage.getNotification() != null) {
      emitter.sendEvent(ReactNativeFirebaseNotificationSerializer.remoteNotificationToEvent(remoteMessage));
      return;
    }


    //  |-> ---------------------
    //    App in Background/Quit
    //   ------------------------
    try {
      Intent intent = new Intent(getApplicationContext(), ReactNativeFirebaseBGNotificationActionService.class);
      intent.putExtra("notification", remoteMessage);
      ComponentName name = getApplicationContext().startService(intent);
      if (name != null) {
        HeadlessJsTaskService.acquireWakeLockNow(getApplicationContext());
      }
    } catch (IllegalStateException ex) {
      Log.e(
        TAG,
        "Background messages only work if the message priority is set to 'high'",
        ex
      );
    }
  }
}
