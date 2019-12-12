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

import android.app.RemoteInput;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;

import androidx.annotation.RequiresApi;

import com.facebook.react.HeadlessJsTaskService;

import io.invertase.firebase.common.ReactNativeFirebaseEventEmitter;
import io.invertase.firebase.common.SharedUtils;

public class ReactNativeFirebaseBGNotificationActionReceiver extends BroadcastReceiver {

  private static final String KEY_REMOTE_INPUT_RESULT = "result";
  private ReactNativeFirebaseEventEmitter eventEmitter = ReactNativeFirebaseEventEmitter.getSharedInstance();

  static boolean isBackgroundNotificationIntent(Intent intent) {
    return intent.getExtras() != null && intent.hasExtra("action") && intent.hasExtra("notification");
  }

  @Override
  public void onReceive(Context context, Intent intent) {
    if (!isBackgroundNotificationIntent(intent) || intent.getExtras() == null) return;

    if (SharedUtils.isAppInForeground(context)) {
      eventEmitter.sendEvent(ReactNativeFirebaseNotificationSerializer.createRemoteNotificationOpenedEvent(intent.getExtras()));
    } else {
      Intent serviceIntent = new Intent(context, ReactNativeFirebaseBGNotificationActionService.class);
      serviceIntent.putExtras(intent.getExtras());

      if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT_WATCH) {
        serviceIntent.putExtra(KEY_REMOTE_INPUT_RESULT, getRemoteInputBundle(intent));
      }

      ComponentName name = context.startService(serviceIntent);
      if (name != null) HeadlessJsTaskService.acquireWakeLockNow(context);
    }
  }

  @RequiresApi(Build.VERSION_CODES.KITKAT_WATCH)
  private Bundle getRemoteInputBundle(Intent intent) {
    return RemoteInput.getResultsFromIntent(intent);
  }
}
