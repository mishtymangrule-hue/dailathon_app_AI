package com.mangrule.dailathon.presentation.notification

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import timber.log.Timber

/**
 * Handles action button clicks from call notifications (mute, hang-up).
 * Routes actions through CallCommandBus to the active DialerConnection.
 */
class CallNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            "com.mangrule.dailathon.ACTION_MUTE" -> {
                Timber.v("Mute action received from notification")
                // TODO: Route to CallCommandBus.toggleMute()
            }
            "com.mangrule.dailathon.ACTION_HANGUP" -> {
                Timber.v("Hang-up action received from notification")
                // TODO: Route to CallCommandBus.hangUp()
            }
        }
    }
}
