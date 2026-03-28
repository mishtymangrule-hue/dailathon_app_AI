package com.mangrule.dailathon.vibration

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import timber.log.Timber

class DndReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != NotificationManager.ACTION_INTERRUPTION_FILTER_CHANGED) return

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return
        val filter = nm.currentInterruptionFilter
        val filterName = when (filter) {
            NotificationManager.INTERRUPTION_FILTER_ALL -> "ALL"
            NotificationManager.INTERRUPTION_FILTER_PRIORITY -> "PRIORITY"
            NotificationManager.INTERRUPTION_FILTER_NONE -> "NONE"
            NotificationManager.INTERRUPTION_FILTER_ALARMS -> "ALARMS_ONLY"
            else -> "UNKNOWN($filter)"
        }
        Timber.d("DndReceiver: Interruption filter changed to $filterName")
    }
}
