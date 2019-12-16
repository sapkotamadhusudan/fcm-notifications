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
