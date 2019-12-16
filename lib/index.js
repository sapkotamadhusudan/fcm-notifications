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

import {AppRegistry} from 'react-native';
import {
  createModuleNamespace,
  FirebaseModule,
  getFirebaseRoot,
} from '@react-native-firebase/app/lib/internal';

import {
  isAndroid,
  isFunction,
  isNumber,
  isString,
  isIOS,
  isArray,
  isNull,
  isUndefined,
} from '@react-native-firebase/app/lib/common';

import validateNotification from './validateNotification';
import validateSchedule from './validateSchedule';
import validateAndroidChannel from './validateAndroidChannel';
import validateAndroidChannelGroup from './validateAndroidChannelGroup';

import AndroidBadgeIconType from './AndroidBadgeIconType';
import AndroidCategory from './AndroidCategory';
import AndroidGroupAlertBehavior from './AndroidGroupAlertBehavior';
import AndroidPriority from './AndroidPriority';
import AndroidVisibility from './AndroidVisibility';
import AndroidRepeatInterval from './AndroidRepeatInterval';
import AndroidDefaults from './AndroidDefaults';
import AndroidImportance from './AndroidImportance';
import AndroidColor from './AndroidColor';
import AndroidStyle from './AndroidStyle';

import version from './version';

const statics = {
  AndroidBadgeIconType,
  AndroidCategory,
  AndroidGroupAlertBehavior,
  AndroidPriority,
  AndroidVisibility,
  AndroidRepeatInterval,
  AndroidDefaults,
  AndroidImportance,
  AndroidColor,
  AndroidStyle,
};

const namespace = 'notifications';

const nativeModuleName = 'RNFBNotificationsModule';

class FirebaseNotificationsModule extends FirebaseModule {

  constructor(...args) {
    super(...args);
    if (isIOS){
      this.native.jsInitialised();
    }
    this._isAutoInitEnabled = this.native.isAutoInitEnabled != null ? this.native.isAutoInitEnabled : true;
    this._isRegisteredForRemoteNotifications = this.native.isRegisteredForRemoteNotifications != null
            ? this.native.isRegisteredForRemoteNotifications
            : true;
  }


  get isAutoInitEnabled() {
    return this._isAutoInitEnabled;
  }


  get isAutoInitEnabled() {
    return this._isAutoInitEnabled;
  }

  /**
   * @platform ios
   */
  get isRegisteredForRemoteNotifications() {
    if (isAndroid) {
      return true;
    }
    return this._isRegisteredForRemoteNotifications;
  }

  setAutoInitEnabled(enabled) {
    if (!isBoolean(enabled)) {
      throw new Error(
        "firebase.messaging().setAutoInitEnabled(*) 'enabled' expected a boolean value.",
      );
    }

    this._isAutoInitEnabled = enabled;
    return this.native.setAutoInitEnabled(enabled);
  }


  getToken(authorizedEntity, scope) {
    if (!isUndefined(authorizedEntity) && !isString(authorizedEntity)) {
      throw new Error(
        "firebase.messaging().getToken(*) 'authorizedEntity' expected a string value.",
      );
    }

    if (!isUndefined(scope) && !isString(scope)) {
      throw new Error("firebase.messaging().getToken(_, *) 'scope' expected a string value.");
    }

    return this.native.getToken(
      authorizedEntity || this.app.options.messagingSenderId,
      scope || 'FCM',
    );
  }

  deleteToken(authorizedEntity, scope) {
    if (!isUndefined(authorizedEntity) && !isString(authorizedEntity)) {
      throw new Error(
        "firebase.messaging().deleteToken(*) 'authorizedEntity' expected a string value.",
      );
    }

    if (!isUndefined(scope) && !isString(scope)) {
      throw new Error("firebase.messaging().deleteToken(_, *) 'scope' expected a string value.");
    }

    return this.native.deleteToken(
      authorizedEntity || this.app.options.messagingSenderId,
      scope || 'FCM',
    );
  }


  onTokenRefresh(listener) {
    if (!isFunction(listener)) {
      throw new Error("firebase.messaging().onTokenRefresh(*) 'listener' expected a function.");
    }

    // TODO(salakar) rework internals as without this native module will never be ready (therefore never subscribes)
    this.native;

    const subscription = this.emitter.addListener('messaging_token_refresh', event => {
      const { token } = event;
      listener(token);
    });
    return () => subscription.remove();
  }

  /**
   * @platform ios
   */
  requestPermission() {
    if (isAndroid) {
      return Promise.resolve(true);
    }
    return this.native.requestPermission();
  }

  /**
 * @platform ios
 */
  registerForRemoteNotifications() {
    if (isAndroid) {
      return Promise.resolve();
    }
    this._isRegisteredForRemoteNotifications = true;
    return this.native.registerForRemoteNotifications();
  }

  /**
   * @platform ios
   */
  unregisterForRemoteNotifications() {
    if (isAndroid) {
      return Promise.resolve();
    }
    this._isRegisteredForRemoteNotifications = false;
    return this.native.unregisterForRemoteNotifications();
  }

  /**
   * @platform ios
   */
  getAPNSToken() {
    if (isAndroid) {
      return Promise.resolve(null);
    }
    return this.native.getAPNSToken();
  }

  hasPermission() {
    return this.native.hasPermission();
  }

  /**
   * @platform android
   */
  setBackgroundNotificationHandler(handler) {
    if (!isFunction(handler)) {
      throw new Error(
        "firebase.messaging().setBackgroundMessageHandler(*) 'handler' expected a function.",
      );
    }

    if (isIOS) {
      return;
    }

    AppRegistry.registerHeadlessTask('ReactNativeFirebaseNotificationHeadlessTask', () => handler);
  }

  subscribeToTopic(topic) {
    if (!isString(topic)) {
      throw new Error("firebase.messaging().subscribeToTopic(*) 'topic' expected a string value.");
    }

    if (topic.indexOf('/') > -1) {
      throw new Error('firebase.messaging().subscribeToTopic(*) \'topic\' must not include "/".');
    }

    return this.native.subscribeToTopic(topic);
  }

  unsubscribeFromTopic(topic) {
    if (!isString(topic)) {
      throw new Error(
        "firebase.messaging().unsubscribeFromTopic(*) 'topic' expected a string value.",
      );
    }

    if (topic.indexOf('/') > -1) {
      throw new Error(
        'firebase.messaging().unsubscribeFromTopic(*) \'topic\' must not include "/".',
      );
    }

    return this.native.unsubscribeFromTopic(topic);
  }

  cancelAllNotifications() {
    return this.native.cancelAllNotifications();
  }

  cancelNotification(notificationId) {
    if (!isString(notificationId)) {
      throw new Error(
        "firebase.notifications().cancelNotification(*) 'notificationId' expected a string value.",
      );
    }

    return this.native.cancelNotification(notificationId);
  }

  createChannel(channel) {
    let options;
    try {
      options = validateAndroidChannel(channel);
    } catch (e) {
      throw new Error(`firebase.notifications().createChannel(*) ${e.message}`);
    }

    if (isIOS) {
      return Promise.resolve('');
    }

    return this.native.createChannel(options).then(() => {
      return options.channelId;
    });
  }

  createChannels(channels) {
    if (!isArray(channels)) {
      throw new Error(
        "firebase.notifications().createChannels(*) 'channels' expected an array of AndroidChannel.",
      );
    }

    let options = [];
    try {
      for (let i = 0; i < channels.length; i++) {
        options[i] = validateAndroidChannel(channels[i]);
      }
    } catch (e) {
      throw new Error(
        `firebase.notifications().createChannels(*) 'channels' a channel is invalid: ${e.message}`,
      );
    }

    if (isIOS) {
      return Promise.resolve();
    }

    return this.native.createChannels(options);
  }

  createChannelGroup(channelGroup) {
    let options;
    try {
      options = validateAndroidChannelGroup(channelGroup);
    } catch (e) {
      throw new Error(`firebase.notifications().createChannelGroup(*) ${e.message}`);
    }

    if (isIOS) {
      return Promise.resolve('');
    }

    return this.native.createChannelGroup(options).then(() => {
      return options.channelGroupId;
    });
  }

  createChannelGroups(channelGroups) {
    if (!isArray(channelGroups)) {
      throw new Error(
        "firebase.notifications().createChannelGroups(*) 'channelGroups' expected an array of AndroidChannelGroup.",
      );
    }

    let options = [];
    try {
      for (let i = 0; i < channelGroups.length; i++) {
        options[i] = validateAndroidChannelGroup(channelGroups[i]);
      }
    } catch (e) {
      throw new Error(
        `firebase.notifications().createChannelGroups(*) 'channelGroups' a channel group is invalid: ${
        e.message
        }`,
      );
    }

    if (isIOS) {
      return Promise.resolve();
    }

    return this.native.createChannelGroups(options);
  }

  deleteChannel(channelId) {
    if (!isString(channelId)) {
      throw new Error(
        "firebase.notifications().deleteChannel(*) 'channelId' expected a string value.",
      );
    }

    if (isIOS) {
      return Promise.resolve();
    }

    return this.native.deleteChannel(channelId);
  }

  deleteChannelGroup(channelGroupId) {
    if (!isString(channelGroupId)) {
      throw new Error(
        "firebase.notifications().deleteChannelGroup(*) 'channelGroupId' expected a string value.",
      );
    }

    if (isIOS) {
      return Promise.resolve();
    }

    return this.native.deleteChannelGroup(channelGroupId);
  }

  displayNotification(notification) {
    let options;
    try {
      options = validateNotification(notification);
    } catch (e) {
      throw new Error(`firebase.notifications().displayNotification(*) ${e.message}`);
    }

    return this.native.displayNotification(options).then(() => {
      return options.notificationId;
    });
  }

  getBadge() {
    return this.native.getBadge();
  }

  getChannel(channelId) {
    if (!isString(channelId)) {
      throw new Error(
        "firebase.notifications().getChannel(*) 'channelId' expected a string value.",
      );
    }

    if (isIOS) {
      return Promise.resolve(null);
    }

    return this.native.getChannel(channelId);
  }

  getChannels() {
    if (isIOS) {
      return Promise.resolve([]);
    }

    return this.native.getChannels();
  }

  getChannelGroup(channelGroupId) {
    if (!isString(channelGroupId)) {
      throw new Error(
        "firebase.notifications().getChannelGroup(*) 'channelGroupId' expected a string value.",
      );
    }

    if (isIOS) {
      return Promise.resolve(null);
    }

    return this.native.getChannelGroup(channelGroupId);
  }

  getChannelGroups() {
    if (isIOS) {
      return Promise.resolve([]);
    }

    return this.native.getChannelGroups();
  }

  getInitialNotification() {
    return this.native.getInitialNotification();
  }

  getScheduledNotifications() {
    return this.native.getScheduledNotifications();
  }

  onNotification(observer) {
    if (!isFunction(observer)) {
      throw new Error("firebase.notifications().onNotification(*) 'observer' expected a function.");
    }

    const subscription = this.emitter.addListener('notifications_notification_received', observer);
    return () => {
      subscription.remove();
    };
  }

  onNotificationDisplayed(observer) {
    if (!isFunction(observer)) {
      throw new Error(
        "firebase.notifications().onNotificationDisplayed(*) 'observer' expected a function.",
      );
    }

    const subscription = this.emitter.addListener('notifications_notification_displayed', observer);
    return () => {
      subscription.remove();
    };
  }

  onNotificationOpened(observer) {
    if (!isFunction(observer)) {
      throw new Error(
        "firebase.notifications().onNotificationOpened(*) 'observer' expected a function.",
      );
    }

    const subscription = this.emitter.addListener('notifications_notification_opened', observer);
    return () => {
      subscription.remove();
    };
  }

  removeAllDeliveredNotifications() {
    return this.native.removeAllDeliveredNotifications();
  }

  removeDeliveredNotification(notificationId) {
    if (!isString(notificationId)) {
      throw new Error(
        "firebase.notifications().removeDeliveredNotification(*) 'notificationId' expected a string value.",
      );
    }

    return this.native.removeDeliveredNotification(notificationId);
  }

  scheduleNotification(notification, schedule) {
    let notificationOptions;
    try {
      notificationOptions = validateNotification(notification);
    } catch (e) {
      throw new Error(`firebase.notifications().scheduleNotification(*) ${e.message}`);
    }

    let scheduleOptions;
    try {
      scheduleOptions = validateSchedule(schedule);
    } catch (e) {
      throw new Error(`firebase.notifications().scheduleNotification(_, *) ${e.message}`);
    }

    return this.native.scheduleNotification(notificationOptions, scheduleOptions);
  }

  setBadge(badge) {
    if (!isNull(badge) || !isNumber(badge)) {
      throw new Error(
        "firebase.notifications().removeDeliveredNotification(*) 'badge' expected null or a number value.",
      );
    }

    // todo can a badge be negative?
    return this.native.setBadge(badge);
  }
}

// import { SDK_VERSION } from 'fcm-notifications';
export const SDK_VERSION = version;

// import notifications from 'fcm-notifications';
// notifications().X(...);
export default createModuleNamespace({
  statics,
  version,
  namespace,
  nativeModuleName,
  nativeEvents: [
    'messaging_token_refresh',
    'notifications_notification_received',
    'notifications_notification_displayed',
    'notifications_notification_opened'
  ],
  hasMultiAppSupport: false,
  hasCustomUrlOrRegionSupport: false,
  ModuleClass: FirebaseNotificationsModule,
});

// import notifications, { firebase } from 'fcm-notifications';
// notifications().X(...);
// firebase.notifications().X(...);
export const firebase = getFirebaseRoot();

export AndroidBadgeIconType from './AndroidBadgeIconType';
export AndroidCategory from './AndroidCategory';
export AndroidGroupAlertBehavior from './AndroidGroupAlertBehavior';
export AndroidPriority from './AndroidPriority';
export AndroidVisibility from './AndroidVisibility';
export AndroidRepeatInterval from './AndroidRepeatInterval';
export AndroidDefaults from './AndroidDefaults';
export AndroidImportance from './AndroidImportance';
export AndroidColor from './AndroidColor';
export AndroidStyle from './AndroidStyle';
