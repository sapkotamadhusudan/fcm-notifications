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

import android.util.Log;

import androidx.core.app.NotificationManagerCompat;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.iid.FirebaseInstanceId;
import com.google.firebase.messaging.FirebaseMessaging;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

import io.invertase.firebase.common.ReactNativeFirebaseModule;

public class ReactNativeFirebaseNotificationsModule extends ReactNativeFirebaseModule {
  private static final String TAG = "Notifications";

  ReactNativeFirebaseNotificationsModule(ReactApplicationContext reactContext) {
    super(reactContext, TAG);
  }

  @ReactMethod
  public void subscribeToTopic(String topic, Promise promise) {
    FirebaseMessaging.getInstance()
      .subscribeToTopic(topic)
      .addOnCompleteListener(task -> {
        if (task.isSuccessful()) {
          promise.resolve(task.getResult());
        } else {
          rejectPromiseWithExceptionMap(promise, task.getException());
        }
      });
  }

  @ReactMethod
  public void unsubscribeFromTopic(String topic, Promise promise) {
    FirebaseMessaging.getInstance()
      .unsubscribeFromTopic(topic)
      .addOnCompleteListener(task -> {
        if (task.isSuccessful()) {
          promise.resolve(task.getResult());
        } else {
          rejectPromiseWithExceptionMap(promise, task.getException());
        }
      });
  }

  @ReactMethod
  public void setAutoInitEnabled(Boolean enabled, Promise promise) {
    Tasks
      .call(getExecutor(), () -> {
        FirebaseMessaging.getInstance().setAutoInitEnabled(enabled);
        return null;
      })
      .addOnCompleteListener(task -> {
        if (task.isSuccessful()) {
          promise.resolve(FirebaseMessaging.getInstance().isAutoInitEnabled());
        } else {
          rejectPromiseWithExceptionMap(promise, task.getException());
        }
      });
  }

  @ReactMethod
  public void getToken(String authorizedEntity, String scope, Promise promise) {
    Tasks
      .call(getExecutor(), () -> FirebaseInstanceId.getInstance().getToken(authorizedEntity, scope))
      .addOnCompleteListener(task -> {
        if (task.isSuccessful()) {
          promise.resolve(task.getResult());
        } else {
          rejectPromiseWithExceptionMap(promise, task.getException());
        }
      });
  }

  @ReactMethod
  public void deleteToken(String authorizedEntity, String scope, Promise promise) {
    Tasks
      .call(getExecutor(), () -> {
        FirebaseInstanceId.getInstance().deleteToken(authorizedEntity, scope);
        return null;
      })
      .addOnCompleteListener(task -> {
        if (task.isSuccessful()) {
          promise.resolve(task.getResult());
        } else {
          rejectPromiseWithExceptionMap(promise, task.getException());
        }
      });
  }

  @ReactMethod
  public void hasPermission(Promise promise) {
    Tasks
      .call(getExecutor(), () -> NotificationManagerCompat.from(getReactApplicationContext()).areNotificationsEnabled())
      .addOnCompleteListener(task -> {
        if (task.isSuccessful()) {
          promise.resolve(task.getResult());
        } else {
          rejectPromiseWithExceptionMap(promise, task.getException());
        }
      });
  }

  @ReactMethod
  public void displayNotification(ReadableMap notificationRaw, Promise promise) {
    Tasks.call(getExecutor(), () -> {
      ReactNativeFirebaseNotification nativeFirebaseNotification = ReactNativeFirebaseNotification.fromReadableMap(notificationRaw);
      nativeFirebaseNotification.displayNotification();
      return nativeFirebaseNotification;
    }).addOnCompleteListener(task -> {
      if (task.isSuccessful()) {
        promise.resolve(Objects.requireNonNull(task.getResult()).toWritableMap());
      } else {
        Exception exception = task.getException();
        Log.e(TAG, "Error displaying a notification", exception);
        if (exception instanceof InvalidNotificationParameterException) {
          InvalidNotificationParameterException notificationParameterException = (InvalidNotificationParameterException) exception;
          rejectPromiseWithCodeAndMessage(promise, notificationParameterException.getCode(), notificationParameterException.getMessage(), notificationParameterException.getMessage());
        } else {
          rejectPromiseWithExceptionMap(promise, exception);
        }
      }
    });
  }

  @ReactMethod
  public void createChannel(ReadableMap channelMap, Promise promise) {
    try {
      ReactNativeFirebaseNotificationChannel.createChannel(channelMap);
    } catch (Throwable t) {
      Log.e(TAG, "FSAGFSDG", t);
      // do nothing - most likely a NoSuchMethodError for < v4 support lib
    }
    promise.resolve(null);
  }

  @ReactMethod
  public void createChannelGroup(ReadableMap channelGroupMap, Promise promise) {
    try {
      ReactNativeFirebaseNotificationChannel.createChannelGroup(channelGroupMap);
    } catch (Throwable t) {
      // do nothing - most likely a NoSuchMethodError for < v4 support lib
    }
    promise.resolve(null);
  }

  @ReactMethod
  public void createChannelGroups(ReadableArray channelGroupsArray, Promise promise) {
    try {
      ReactNativeFirebaseNotificationChannel.createChannelGroups(channelGroupsArray);
    } catch (Throwable t) {
      // do nothing - most likely a NoSuchMethodError for < v4 support lib
    }
    promise.resolve(null);
  }

  @ReactMethod
  public void createChannels(ReadableArray channelsArray, Promise promise) {
    try {
      ReactNativeFirebaseNotificationChannel.createChannels(channelsArray);
    } catch (Throwable t) {
      // do nothing - most likely a NoSuchMethodError for < v4 support lib
    }
    promise.resolve(null);
  }

  @ReactMethod
  public void deleteChannelGroup(String channelId, Promise promise) {
    try {
      ReactNativeFirebaseNotificationChannel.deleteChannelGroup(channelId);
      promise.resolve(null);
    } catch (NullPointerException e) {
      promise.reject(
        "notifications/channel-group-not-found",
        "The requested NotificationChannelGroup does not exist, have you created it?"
      );
    }
  }

  @ReactMethod
  public void deleteChannel(String channelId, Promise promise) {
    try {
      ReactNativeFirebaseNotificationChannel.deleteChannel(channelId);
    } catch (Throwable t) {
      // do nothing - most likely a NoSuchMethodError for < v4 support lib
    }
    promise.resolve(null);
  }

  @ReactMethod
  public void getChannel(String channelId, Promise promise) {
    try {
      promise.resolve(ReactNativeFirebaseNotificationChannel.getChannel(channelId));
      return;
    } catch (Throwable t) {
      // do nothing - most likely a NoSuchMethodError for < v4 support lib
    }
    promise.resolve(null);
  }

  @ReactMethod
  public void getChannels(Promise promise) {
    try {
      promise.resolve(ReactNativeFirebaseNotificationChannel.getChannels());
      return;
    } catch (Throwable t) {
      // do nothing - most likely a NoSuchMethodError for < v4 support lib
    }
    promise.resolve(Collections.emptyList());
  }

  @ReactMethod
  public void getChannelGroup(String channelGroupId, Promise promise) {
    try {
      promise.resolve(ReactNativeFirebaseNotificationChannel.getChannelGroup(channelGroupId));
      return;
    } catch (Throwable t) {
      // do nothing - most likely a NoSuchMethodError for < v4 support lib
    }
    promise.resolve(null);
  }

  @ReactMethod
  public void getChannelGroups(Promise promise) {
    try {
      promise.resolve(ReactNativeFirebaseNotificationChannel.getChannelGroups());
      return;
    } catch (Throwable t) {
      // do nothing - most likely a NoSuchMethodError for < v4 support lib
    }
    promise.resolve(Collections.emptyList());
  }

  @Override
  public Map<String, Object> getConstants() {
    final Map<String, Object> constants = new HashMap<>();
    constants.put(
      "isAutoInitEnabled",
      FirebaseMessaging.getInstance().isAutoInitEnabled()
    );
    return constants;
  }
}
