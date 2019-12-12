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
