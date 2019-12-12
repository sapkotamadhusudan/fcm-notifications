package io.invertase.firebase.notifications;

import android.content.Intent;

import androidx.annotation.Nullable;

import com.facebook.react.HeadlessJsTaskService;
import com.facebook.react.jstasks.HeadlessJsTaskConfig;

import io.invertase.firebase.common.ReactNativeFirebaseJSON;

import static io.invertase.firebase.notifications.ReactNativeFirebaseBGNotificationActionReceiver.isBackgroundNotificationIntent;

public class ReactNativeFirebaseBGNotificationActionService extends HeadlessJsTaskService {

  private static final long TIMEOUT_DEFAULT = 60000;
  private static final String TIMEOUT_JSON_KEY = "notification_android_headless_task_timeout";
  private static final String TASK_KEY = "ReactNativeFirebaseNotificationHeadlessTask";

  @Override
  protected @Nullable
  HeadlessJsTaskConfig getTaskConfig(Intent intent) {
    if (!isBackgroundNotificationIntent(intent) || intent.getExtras() == null) return null;

    return new HeadlessJsTaskConfig(
      TASK_KEY,
      ReactNativeFirebaseNotificationSerializer.remoteNotificationToWritableMap(intent.getExtras()),
      ReactNativeFirebaseJSON.getSharedInstance().getLongValue(TIMEOUT_JSON_KEY, TIMEOUT_DEFAULT),
      true
    );
  }
}
