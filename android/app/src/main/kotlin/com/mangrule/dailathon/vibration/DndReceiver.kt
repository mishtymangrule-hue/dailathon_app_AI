package com.mangrule.dailathon.vibration

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import timber.log.Timber

class DndReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Timber.d("DndReceiver.onReceive: ${intent.action}")
    }
}
