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
