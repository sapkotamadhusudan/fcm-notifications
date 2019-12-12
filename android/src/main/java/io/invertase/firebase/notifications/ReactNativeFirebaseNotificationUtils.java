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

import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.media.RingtoneManager;
import android.net.Uri;
import android.provider.OpenableColumns;
import android.util.Log;

import androidx.annotation.Nullable;

import static io.invertase.firebase.app.ReactNativeFirebaseApp.getApplicationContext;

public class ReactNativeFirebaseNotificationUtils {


  static String getFileName(Context context, Uri uri) {
    String result = null;
    if (uri.getScheme() != null && uri.getScheme().equals("content")) {
      Cursor cursor = context.getContentResolver().query(uri, null, null, null, null);
      try {
        if (cursor != null && cursor.moveToFirst()) {
          result = cursor.getString(cursor.getColumnIndexOrThrow(OpenableColumns.DISPLAY_NAME));
        }
      } finally {
        if (cursor != null) cursor.close();
      }
    }

    if (result == null) {
      result = uri.getPath();
      if (result != null) {
        int cut = result.lastIndexOf('/');
        if (cut != -1) {
          result = result.substring(cut + 1);
        } else {
          result = "default";
        }
      }
    }

    if (result == null || result.equals("notification_sound")) result = "default";

    return result;
  }


  static Uri getSoundUri(@Nullable String sound) {
    if (sound == null) {
      return RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
    }

    if (sound.contains("://")) {
      return Uri.parse(sound);
    }

    if (sound.equalsIgnoreCase("default")) {
      return RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
    }

    Context ctx = getApplicationContext();
    int resourceId = getResIdByName(ctx, sound, "raw");

    if (resourceId == 0 && sound.contains(".")) {
      resourceId = getResIdByName(ctx, sound.substring(0, sound.lastIndexOf('.')), "raw");
    }

    // If still no resource, default
    if (resourceId == 0) {
      Log.d("RNFBNotificationUtils", "Could not find specified sound " + sound);
      return RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
    }

    return Uri.parse("android.resource://" + getApplicationContext().getPackageName() + "/" + resourceId);
  }

  public static int getResIdByName(Context ctx, String name, String defType){
    return ctx.getResources().getIdentifier(name, defType, ctx.getPackageName());
  }

  public static Class getLaunchActivityClass(Context ctx){
    String packageName = ctx.getPackageName();
    Intent launchIntent = ctx.getPackageManager().getLaunchIntentForPackage(packageName);

    try {
      return Class.forName(launchIntent.getComponent().getClassName());
    } catch (NullPointerException | ClassNotFoundException e) {
      Log.e("RNFNotificationUtils", "Failed to get main activity class", e);
      return null;
    }
  }
}
