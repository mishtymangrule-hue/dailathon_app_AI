package com.mangrule.dailathon.presentation.notification

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import timber.log.Timber
import com.mangrule.dailathon.telecom.DialerInCallService

/**
 * Handles action button clicks from call notifications (mute, hang-up).
 */
class CallNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            "com.mangrule.dailathon.ACTION_MUTE" -> {
                Timber.v("Mute action received from notification")
                DialerInCallService.getInstance()?.let { service ->
                    val current = service.callAudioState?.isMuted ?: false
                    service.setMuted(!current)
                }
            }
            "com.mangrule.dailathon.ACTION_HANGUP" -> {
                Timber.v("Hang-up action received from notification")
                DialerInCallService.getInstance()?.let { service ->
                    service.calls?.firstOrNull()?.disconnect()
                }
            }
        }
    }
}
