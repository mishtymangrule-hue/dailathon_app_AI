package com.mangrule.dailathon.presentation.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import com.mangrule.dailathon.presentation.activities.MainActivity
import timber.log.Timber

const val CHANNEL_MISSED = "missed_calls"

fun createMissedChannel(context: Context) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val channel = NotificationChannel(
            CHANNEL_MISSED,
            "Missed Calls",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Alerts for unanswered incoming calls"
            setShowBadge(true)
            enableLights(true)
            lightColor = Color.RED
        }
        context.getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }
}

object MissedCallNotification {

    private var notificationId = 2000

    fun show(context: Context, callerName: String, callerNumber: String) {
        val callBackIntent = Intent(Intent.ACTION_CALL,
            Uri.fromParts("tel", callerNumber, null)).apply {
            setPackage(context.packageName)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        val callBackPi = PendingIntent.getActivity(
            context, notificationId, callBackIntent,
            pendingIntentFlags()
        )

        val openLogIntent = Intent(context, MainActivity::class.java).apply {
            putExtra("route", "/recents")
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openLogPi = PendingIntent.getActivity(
            context, notificationId + 1000, openLogIntent,
            pendingIntentFlags()
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_MISSED)
            .setSmallIcon(android.R.drawable.sym_call_missed)
            .setContentTitle("Missed call")
            .setContentText(callerName.ifBlank { callerNumber })
            .setSubText(callerNumber.takeIf { callerName.isNotBlank() })
            .setContentIntent(openLogPi)
            .setAutoCancel(true)
            .addAction(android.R.drawable.sym_action_call, "Call Back", callBackPi)
            .setCategory(NotificationCompat.CATEGORY_MISSED_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setColor(Color.RED)
            .build()

        context.getSystemService(NotificationManager::class.java)
            .notify(notificationId, notification)
        
        Timber.v("Missed call notification: $callerName ($callerNumber)")
        notificationId++
    }

    fun clearAll(context: Context) {
        context.getSystemService(NotificationManager::class.java)
            .cancelAll()
        Timber.v("Cleared all missed call notifications")
    }

    private fun pendingIntentFlags() =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else
            PendingIntent.FLAG_UPDATE_CURRENT
}
