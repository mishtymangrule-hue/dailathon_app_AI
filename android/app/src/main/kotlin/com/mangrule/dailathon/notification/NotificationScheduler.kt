package com.mangrule.dailathon.notification

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import timber.log.Timber

/**
 * Schedules exact-time alarms for CRM-driven notifications using AlarmManager.
 *
 * Each notification is keyed by a stable requestCode derived from the notification id
 * so that re-scheduling the same id replaces the old alarm.
 */
object NotificationScheduler {

    fun schedule(context: Context, notificationId: String, triggerAtMillis: Long,
                 title: String, body: String, phoneNumber: String?) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!alarmManager.canScheduleExactAlarms()) {
                Timber.w("NotificationScheduler: SCHEDULE_EXACT_ALARM not granted; skipping $notificationId")
                return
            }
        }

        val intent = buildIntent(context, notificationId, title, body, phoneNumber)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            notificationId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        try {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent,
            )
            Timber.d("NotificationScheduler: scheduled '$notificationId' at $triggerAtMillis")
        } catch (e: SecurityException) {
            Timber.e(e, "NotificationScheduler: could not schedule alarm for $notificationId")
        }
    }

    fun cancel(context: Context, notificationId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = buildIntent(context, notificationId, "", "", null)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            notificationId.hashCode(),
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        ) ?: return
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
        Timber.d("NotificationScheduler: cancelled '$notificationId'")
    }

    private fun buildIntent(context: Context, notificationId: String,
                            title: String, body: String, phoneNumber: String?): Intent =
        Intent(context, NotificationAlarmReceiver::class.java).apply {
            putExtra(NotificationAlarmReceiver.EXTRA_ID, notificationId)
            putExtra(NotificationAlarmReceiver.EXTRA_TITLE, title)
            putExtra(NotificationAlarmReceiver.EXTRA_BODY, body)
            if (phoneNumber != null) putExtra(NotificationAlarmReceiver.EXTRA_PHONE, phoneNumber)
        }
}
