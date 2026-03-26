package com.mangrule.dailathon.presentation.notifications

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import dagger.hilt.android.qualifiers.ApplicationContext
import timber.log.Timber
import com.mangrule.dailathon.presentation.activities.IncomingCallActivity
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages incoming call notifications with full-screen intent support.
 * Handles API level differences (21-34) for notification display.
 */
@Singleton
class IncomingCallNotificationManager @Inject constructor(
  @ApplicationContext private val context: Context,
) {
  companion object {
    private const val CHANNEL_ID = "incoming_calls"
    private const val NOTIFICATION_ID = 1001
  }

  private val notificationManager =
    context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

  init {
    createNotificationChannel()
  }

  private fun createNotificationChannel() {
    // Only needed on API 26+
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val channel = NotificationChannel(
        CHANNEL_ID,
        "Incoming Calls",
        NotificationManager.IMPORTANCE_MAX,
      ).apply {
        description = "Notifications for incoming phone calls"
        enableVibration(true)
        setShowBadge(true)

        // Set ringtone
        val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
        val audioAttributes = AudioAttributes.Builder()
          .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
          .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
          .build()
        setSound(soundUri, audioAttributes)

        // Light settings
        lightColor = Color.GREEN
        enableLights(true)
      }
      notificationManager.createNotificationChannel(channel)
      Timber.v("Created notification channel for incoming calls")
    }
  }

  /**
   * Show incoming call notification with full-screen intent.
   */
  fun showIncomingCallNotification(
    phoneNumber: String,
    displayName: String? = null,
    callId: String? = null,
  ) {
    try {
      val title = displayName ?: phoneNumber
      val subtext = if (displayName != null) phoneNumber else "Incoming Call"

      // Intent to open incoming call activity
      val fullScreenIntent = Intent(context, IncomingCallActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        putExtra("phoneNumber", phoneNumber)
        putExtra("displayName", displayName)
        putExtra("callId", callId)
      }

      // Pending intent with immutable flags (required on API 31+)
      val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
      } else {
        PendingIntent.FLAG_UPDATE_CURRENT
      }
      val fullScreenPendingIntent = PendingIntent.getActivity(
        context,
        0,
        fullScreenIntent,
        flags,
      )

      // Build notification
      val notification = NotificationCompat.Builder(context, CHANNEL_ID)
        .setSmallIcon(android.R.drawable.ic_dialog_info) // TODO: Replace with custom icon
        .setContentTitle(title)
        .setContentText(subtext)
        .setSubText("Incoming call")
        .setAutoCancel(false)
        .setCategory(NotificationCompat.CATEGORY_CALL)
        .setPriority(NotificationCompat.PRIORITY_MAX)
        .setFullScreenIntent(fullScreenPendingIntent, true)

      // Add answer action
      val answerIntent = Intent(context, IncomingCallActivity::class.java).apply {
        action = "com.mangrule.dailathon.ANSWER_CALL"
        putExtra("phoneNumber", phoneNumber)
        putExtra("displayName", displayName)
        putExtra("callId", callId)
      }
      val answerPendingIntent = PendingIntent.getActivity(
        context,
        1,
        answerIntent,
        flags,
      )
      notification.addAction(
        android.R.drawable.ic_menu_call,
        "Answer",
        answerPendingIntent,
      )

      // Add decline action
      val declineIntent = Intent(context, IncomingCallActivity::class.java).apply {
        action = "com.mangrule.dailathon.DECLINE_CALL"
        putExtra("phoneNumber", phoneNumber)
        putExtra("displayName", displayName)
        putExtra("callId", callId)
      }
      val declinePendingIntent = PendingIntent.getActivity(
        context,
        2,
        declineIntent,
        flags,
      )
      notification.addAction(
        android.R.drawable.ic_menu_close_clear_cancel,
        "Decline",
        declinePendingIntent,
      )

      // Show notification
      notificationManager.notify(NOTIFICATION_ID, notification.build())
      Timber.v("Showing incoming call notification: phone=$phoneNumber, name=$displayName")
    } catch (e: Exception) {
      Timber.e(e, "Error showing incoming call notification")
    }
  }

  /**
   * Cancel incoming call notification.
   */
  fun cancelIncomingCallNotification() {
    try {
      notificationManager.cancel(NOTIFICATION_ID)
      Timber.v("Cancelled incoming call notification")
    } catch (e: Exception) {
      Timber.e(e, "Error cancelling notification")
    }
  }

  /**
   * Update notification with new information.
   */
  fun updateIncomingCallNotification(
    phoneNumber: String,
    displayName: String? = null,
    duration: Long = 0,
  ) {
    try {
      val title = displayName ?: phoneNumber
      val durationText = if (duration > 0) {
        " (${duration}s)"
      } else {
        ""
      }

      val notification = NotificationCompat.Builder(context, CHANNEL_ID)
        .setSmallIcon(android.R.drawable.ic_dialog_info)
        .setContentTitle(title)
        .setContentText("Ringing$durationText")
        .setSubText(phoneNumber)
        .setAutoCancel(false)
        .setCategory(NotificationCompat.CATEGORY_CALL)
        .setPriority(NotificationCompat.PRIORITY_MAX)
        .build()

      notificationManager.notify(NOTIFICATION_ID, notification)
      Timber.v("Updated incoming call notification")
    } catch (e: Exception) {
      Timber.e(e, "Error updating notification")
    }
  }
}
