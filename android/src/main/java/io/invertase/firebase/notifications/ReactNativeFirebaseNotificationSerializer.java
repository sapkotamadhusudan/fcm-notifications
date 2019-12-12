package io.invertase.firebase.notifications;

import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import androidx.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.google.firebase.messaging.RemoteMessage;

import java.util.Map;
import java.util.Set;

import io.invertase.firebase.common.ReactNativeFirebaseEvent;
import io.invertase.firebase.common.SharedUtils;

import static io.invertase.firebase.app.ReactNativeFirebaseApp.getApplicationContext;
import static io.invertase.firebase.common.SharedUtils.getResId;

public class ReactNativeFirebaseNotificationSerializer {

  private static final String KEY_TOKEN = "token";
  private static final String KEY_COLLAPSE_KEY = "collapseKey";
  private static final String KEY_DATA = "data";
  private static final String KEY_FROM = "from";
  private static final String KEY_MESSAGE_ID = "messageId";
  private static final String KEY_MESSAGE_TYPE = "messageType";
  private static final String KEY_SENT_TIME = "sentTime";
  private static final String KEY_ERROR = "error";
  private static final String KEY_TO = "to";
  private static final String KEY_TTL = "ttl";

  private static final String EVENT_MESSAGE_SENT = "messaging_message_sent";
  private static final String EVENT_MESSAGES_DELETED = "messaging_message_deleted";
  private static final String EVENT_MESSAGE_RECEIVED = "messaging_message_received";
  private static final String EVENT_MESSAGE_SEND_ERROR = "messaging_message_send_error";
  private static final String EVENT_NEW_TOKEN = "messaging_token_refresh";


  // Notification Keys
    private static final String KEY_TITLE = "title";
    private static final String KEY_BODY = "body";
    private static final String KEY_ICON = "icon";
    private static final String KEY_IMAGE_URL = "imageUrl";
    private static final String KEY_SOUND_URL = "soundUrl";
    private static final String KEY_TAG = "tag";
    private static final String KEY_COLOR = "color";
    private static final String KEY_CLICK_ACTION = "clickAction";
    private static final String KEY_CHANNEL_ID = "channelId";
    private static final String KEY_LINK = "link";
    private static final String KEY_TICKER = "ticker";
    private static final String KEY_STICKY = "sticky";
    private static final String KEY_LOCAL_ONLY = "localOnly";
    private static final String KEY_DEFAULT_SOUND = "defaultSound";
    private static final String KEY_DEFAULT_VIBRATING_SETTING = "defaultVibratingSetting";
    private static final String KEY_DEFAULT_LIGHT_SETTING = "defaultLightSetting";
    private static final String KEY_NOTIFICATION_PRIORITY = "notificationPriority";
    private static final String KEY_NOTIFICATION_COUNT = "notificationCount";
    private static final String KEY_VISIBILITY = "visibility";
    private static final String KEY_NOTIFICATION_SOUND = "notificationSound";
    private static final String KEY_EVENT_TIME = "eventTime";
    private static final String KEY_VIBRATE_TIMINGS = "vibrateTimings";
    private static final String KEY_LIGHT_SETTING = "lightSettings";
  
    private static final String EVENT_NOTIFICATION_RECEIVED = "notifications_notification_received";

  private static final String KEY_ACTION = "action";
  private static final String KEY_NOTIFICATION = "notification";
  private static final String KEY_NOTIFICATION_ID = "notificationId";
  private static final String KEY_RESULT = "result";
  private static final String ACTION_BACKGROUND_NOTIFICATION = "io.invertase.firebase.notifications.BackgroundAction";

  private static final String EVENT_NOTIFICATION_OPENED = "notifications_notification_opened";
  private static final String EVENT_NOTIFICATION_DISPLAYED = "notifications_notification_displayed";

  static WritableMap remoteNotificationToWritableMap(Bundle extras) {
    WritableMap notificationMap = Arguments.makeNativeMap(extras.getBundle("notification"));
    WritableMap notificationOpenMap = Arguments.createMap();
    notificationOpenMap.putString(KEY_ACTION, extras.getString(KEY_ACTION));
    notificationOpenMap.putMap(KEY_NOTIFICATION, notificationMap);

    Bundle extrasBundle = extras.getBundle(KEY_RESULT);
    if (extrasBundle != null) {
      WritableMap results = Arguments.makeNativeMap(extrasBundle);
      notificationOpenMap.putMap(KEY_RESULT, results);
    }

    return notificationMap;
  }

  static ReactNativeFirebaseEvent createRemoteNotificationDisplayedEvent(WritableMap notification){
    return new ReactNativeFirebaseEvent(EVENT_NOTIFICATION_DISPLAYED, notification);
  }

  static ReactNativeFirebaseEvent createRemoteNotificationOpenedEvent(Bundle notification){
    return new ReactNativeFirebaseEvent(EVENT_NOTIFICATION_OPENED, remoteNotificationToWritableMap(notification));
  }

  static PendingIntent createBroadcastIntent(Context context, Bundle notification, String action) {
    String notificationId = notification.getString(KEY_NOTIFICATION_ID) + action;
    Intent intent = new Intent(context, ReactNativeFirebaseBGNotificationActionReceiver.class);

    intent.putExtra(KEY_ACTION, action);
    intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
    intent.putExtra(KEY_NOTIFICATION, notification);
    intent.setAction(ACTION_BACKGROUND_NOTIFICATION);

    return PendingIntent.getBroadcast(
      context,
      notificationId.hashCode(),
      intent,
      PendingIntent.FLAG_UPDATE_CURRENT
    );
  }

  static PendingIntent createIntent(
    Context context,
    Class intentClass,
    Bundle notification,
    String action
  ) {
    Intent intent = new Intent(context, intentClass);
    intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
    intent.putExtras(notification);

    if (action != null) {
      intent.setAction(action);
    }

    String notificationId = notification.getString(KEY_NOTIFICATION_ID);
    return PendingIntent.getActivity(
      context,
      notificationId.hashCode(),
      intent,
      PendingIntent.FLAG_UPDATE_CURRENT
    );
  }

  
  static ReactNativeFirebaseEvent newTokenToTokenEvent(String newToken) {
    WritableMap eventBody = Arguments.createMap();
    eventBody.putString(KEY_TOKEN, newToken);
    return new ReactNativeFirebaseEvent("EVENT_NEW_TOKEN", eventBody);
  }

  static WritableMap remoteMessageToWritableMap(RemoteMessage remoteMessage) {
    WritableMap messageMap = Arguments.createMap();
    WritableMap dataMap = Arguments.createMap();

    if (remoteMessage.getCollapseKey() != null) {
      messageMap.putString(KEY_COLLAPSE_KEY, remoteMessage.getCollapseKey());
    }

    if (remoteMessage.getFrom() != null) {
      messageMap.putString(KEY_FROM, remoteMessage.getFrom());
    }

    if (remoteMessage.getTo() != null) {
      messageMap.putString(KEY_TO, remoteMessage.getTo());
    }

    if (remoteMessage.getMessageId() != null) {
      messageMap.putString(KEY_MESSAGE_ID, remoteMessage.getMessageId());
    }

    if (remoteMessage.getMessageType() != null) {
      messageMap.putString(KEY_MESSAGE_TYPE, remoteMessage.getMessageType());
    }

    if (remoteMessage.getData().size() > 0) {
      Set<Map.Entry<String, String>> entries = remoteMessage.getData().entrySet();
      for (Map.Entry<String, String> entry : entries) {
        dataMap.putString(entry.getKey(), entry.getValue());
      }
    }

    messageMap.putMap(KEY_DATA, dataMap);
    messageMap.putDouble(KEY_TTL, remoteMessage.getTtl());
    messageMap.putDouble(KEY_SENT_TIME, remoteMessage.getSentTime());
    return messageMap;
  }

  static ReactNativeFirebaseEvent remoteNotificationToEvent(RemoteMessage remoteMessage) {
    return new ReactNativeFirebaseEvent(EVENT_NOTIFICATION_RECEIVED, remoteNotificationToWritableMap(remoteMessage));
  }

  static WritableMap remoteNotificationToWritableMap(RemoteMessage remoteMessage) {
    RemoteMessage.Notification notification = remoteMessage.getNotification();

    WritableMap notificationMap = Arguments.createMap();
    WritableMap dataMap = Arguments.createMap();

    String title = getNotificationTitle(notification);
    if (title != null) {
      notificationMap.putString(KEY_TITLE, title);
    }

    String body = getNotificationBody(notification);
    if (body != null) {
      notificationMap.putString(KEY_BODY, body);
    }

    if (notification.getIcon() != null){
      notificationMap.putString(KEY_ICON, notification.getIcon());
    }

    if (notification.getChannelId() != null){
      notificationMap.putString(KEY_CHANNEL_ID, notification.getChannelId());
    }

    if (notification.getIcon() != null) {
      notificationMap.putString(KEY_MESSAGE_ID, notification.getIcon());
    }

    if (notification.getImageUrl() != null) {
      notificationMap.putString(KEY_IMAGE_URL, notification.getImageUrl().toString());
    }

    if (notification.getSound() != null) {
      notificationMap.putString(KEY_SOUND_URL, notification.getSound());
    }

    if (notification.getTag() != null) {
      notificationMap.putString(KEY_TAG, notification.getTag());
    }

    if (notification.getColor() != null) {
      notificationMap.putString(KEY_COLOR, notification.getColor());
    }

    if (notification.getClickAction() != null) {
      notificationMap.putString(KEY_CLICK_ACTION, notification.getClickAction());
    }

    if (notification.getLink() != null) {
      notificationMap.putString(KEY_LINK, notification.getLink().toString());
    }

    if (notification.getTicker() != null) {
      notificationMap.putString(KEY_TICKER, notification.getTicker());
    }

    if (notification.getNotificationPriority() != null) {
      notificationMap.putInt(KEY_NOTIFICATION_PRIORITY, notification.getNotificationPriority());
    }

    if (notification.getVisibility() != null) {
      notificationMap.putInt(KEY_VISIBILITY, notification.getVisibility());
    }

    if (notification.getNotificationCount() != null) {
      notificationMap.putInt(KEY_NOTIFICATION_COUNT, notification.getNotificationCount());
    }

    if (notification.getSound() != null){
      notificationMap.putString(KEY_NOTIFICATION_SOUND, notification.getSound());
    }

    if (notification.getEventTime() != null) {
      notificationMap.putDouble(KEY_EVENT_TIME, notification.getEventTime());
    }

    if (notification.getLightSettings() != null) {
      WritableArray lightSetting = Arguments.createArray();
      for (int i = 0; i < notification.getLightSettings().length; i++) {
        lightSetting.pushInt(notification.getLightSettings()[i]);
      }
      notificationMap.putArray(KEY_LIGHT_SETTING, lightSetting);
    }

    if (notification.getVibrateTimings() != null) {
      WritableArray vibrateTimings = Arguments.createArray();
      for (int i = 0; i < notification.getVibrateTimings().length; i++) {
        vibrateTimings.pushDouble(notification.getVibrateTimings()[i]);
      }
      notificationMap.putArray(KEY_VIBRATE_TIMINGS, vibrateTimings);
    }

    if (remoteMessage.getData().size() > 0) {
      Set<Map.Entry<String, String>> entries = remoteMessage.getData().entrySet();
      for (Map.Entry<String, String> entry : entries) {
        dataMap.putString(entry.getKey(), entry.getValue());
      }
    }


    notificationMap.putMap(KEY_DATA, dataMap);
    notificationMap.putDouble(KEY_TTL, remoteMessage.getTtl());
    notificationMap.putDouble(KEY_SENT_TIME, remoteMessage.getSentTime());

    notificationMap.putBoolean(KEY_STICKY, notification.getSticky());
    notificationMap.putBoolean(KEY_LOCAL_ONLY, notification.getLocalOnly());
    notificationMap.putBoolean(KEY_DEFAULT_SOUND, notification.getDefaultSound());
    notificationMap.putBoolean(KEY_DEFAULT_VIBRATING_SETTING, notification.getDefaultVibrateSettings());
    notificationMap.putBoolean(KEY_DEFAULT_LIGHT_SETTING, notification.getDefaultLightSettings());


    return notificationMap;
  }

  static RemoteMessage remoteNotificationFromReadableMap(ReadableMap readableMap) {
    RemoteMessage.Builder builder = new RemoteMessage.Builder(readableMap.getString("KEY_TO"));


    return builder.build();
  }

  private static  @Nullable
  String getNotificationBody(RemoteMessage.Notification notification) {
    String body = notification.getBody();
    String bodyLocKey = notification.getBodyLocalizationKey();
    if (bodyLocKey != null) {
      String[] bodyLocArgs = notification.getBodyLocalizationArgs();
      Context ctx = getApplicationContext();
      int resId = getResId(ctx, bodyLocKey);
      return ctx
        .getResources()
        .getString(resId, (Object[]) bodyLocArgs);
    } else {
      return body;
    }
  }

  private static  @Nullable
  String getNotificationTitle(RemoteMessage.Notification notification) {
    String title = notification.getTitle();
    String titleLocKey = notification.getTitleLocalizationKey();
    if (titleLocKey != null) {
      String[] titleLocArgs = notification.getTitleLocalizationArgs();
      Context ctx = getApplicationContext();
      int resId = getResId(ctx, titleLocKey);
      return ctx
        .getResources()
        .getString(resId, (Object[]) titleLocArgs);
    } else {
      return title;
    }
  }
}
