package com.mangrule.dailathon.notification

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.mangrule.dailathon.worker.RescheduleAlarmsWorker
import timber.log.Timber

/**
 * Listens for BOOT_COMPLETED and re-queues pending alarm scheduling via WorkManager,
 * because AlarmManager alarms are lost on device reboot.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        Timber.d("BootReceiver: device booted — enqueuing reschedule work")
        val request = OneTimeWorkRequestBuilder<RescheduleAlarmsWorker>().build()
        WorkManager.getInstance(context).enqueue(request)
    }
}
