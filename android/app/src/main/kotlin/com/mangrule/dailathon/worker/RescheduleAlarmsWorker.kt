package com.mangrule.dailathon.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.mangrule.dailathon.data.NotificationScheduleStore
import com.mangrule.dailathon.notification.NotificationScheduler
import timber.log.Timber

/**
 * A one-shot WorkManager worker that re-schedules AlarmManager alarms
 * for all pending CRM notifications after a device reboot.
 *
 * Reads the pending notification list from [NotificationScheduleStore]
 * (a simple SharedPreferences-backed JSON store written by the Flutter side
 * via a MethodChannel, or directly by the sync logic).
 */
class RescheduleAlarmsWorker(
    private val context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        Timber.d("RescheduleAlarmsWorker: starting reschedule pass")
        return try {
            val pending = NotificationScheduleStore.getPending(context)
            Timber.d("RescheduleAlarmsWorker: found ${pending.size} pending notifications")
            for (item in pending) {
                NotificationScheduler.schedule(
                    context = context,
                    notificationId = item.id,
                    triggerAtMillis = item.scheduledAtMillis,
                    title = item.title,
                    body = item.body,
                    phoneNumber = item.phoneNumber,
                )
            }
            Result.success()
        } catch (e: Exception) {
            Timber.e(e, "RescheduleAlarmsWorker: failed")
            Result.retry()
        }
    }
}
