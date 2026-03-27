package com.mangrule.dailathon.presentation.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.mangrule.dailathon.presentation.activities.MainActivity
import timber.log.Timber

const val CHANNEL_ONGOING = "ongoing_call"

fun createOngoingChannel(context: Context) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val channel = NotificationChannel(
            CHANNEL_ONGOING,
            "Ongoing Call",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shown during an active call"
            setShowBadge(false)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        }
        context.getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }
}

object OngoingCallNotification {

    const val NOTIFICATION_ID = 1001
    private const val ACTION_MUTE = "com.mangrule.dailathon.ACTION_MUTE"
    private const val ACTION_HANGUP = "com.mangrule.dailathon.ACTION_HANGUP"

    fun build(
        context: Context,
        callerName: String,
        callerNumber: String,
        isMuted: Boolean,
        elapsedSeconds: Int
    ): android.app.Notification {
        val returnToCallIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/in-call")
        }
        val contentPendingIntent = PendingIntent.getActivity(
            context, 0, returnToCallIntent,
            pendingIntentFlags()
        )

        val muteIntent = Intent(ACTION_MUTE).also { it.setPackage(context.packageName) }
        val mutePendingIntent = PendingIntent.getBroadcast(
            context, 1, muteIntent, pendingIntentFlags()
        )

        val hangupIntent = Intent(ACTION_HANGUP).also { it.setPackage(context.packageName) }
        val hangupPendingIntent = PendingIntent.getBroadcast(
            context, 2, hangupIntent, pendingIntentFlags()
        )

        val muteLabel = if (isMuted) "Unmute" else "Mute"
        val muteIcon = if (isMuted) android.R.drawable.ic_lock_silent_mode else android.R.drawable.ic_btn_speak_now
        val elapsedLabel = formatElapsed(elapsedSeconds)

        return NotificationCompat.Builder(context, CHANNEL_ONGOING)
            .setSmallIcon(android.R.drawable.sym_call_incoming)
            .setContentTitle(callerName.ifBlank { callerNumber })
            .setContentText("Active call · $elapsedLabel")
            .setSubText(callerNumber.takeIf { callerName.isNotBlank() })
            .setContentIntent(contentPendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setUsesChronometer(true)
            .setWhen(System.currentTimeMillis() - (elapsedSeconds * 1000L))
            .addAction(muteIcon, muteLabel, mutePendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Hang Up", hangupPendingIntent)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }

    fun update(
        context: Context,
        callerName: String,
        callerNumber: String,
        isMuted: Boolean,
        elapsedSeconds: Int
    ) {
        val nm = context.getSystemService(NotificationManager::class.java)
        val elapsedLabel = formatElapsed(elapsedSeconds)
        nm.notify(NOTIFICATION_ID, build(context, callerName, callerNumber, isMuted, elapsedSeconds))
        Timber.v("Updated ongoing call notification: $callerName ($elapsedLabel)")
    }

    fun cancel(context: Context) {
        context.getSystemService(NotificationManager::class.java)
            .cancel(NOTIFICATION_ID)
        Timber.v("Cancelled ongoing call notification")
    }

    private fun pendingIntentFlags() =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else
            PendingIntent.FLAG_UPDATE_CURRENT

    private fun formatElapsed(totalSeconds: Int): String {
        val m = totalSeconds / 60
        val s = totalSeconds % 60
        return "%02d:%02d".format(m, s)
    }
}
