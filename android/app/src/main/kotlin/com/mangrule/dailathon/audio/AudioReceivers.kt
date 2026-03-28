package com.mangrule.dailathon.audio

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import timber.log.Timber
import com.mangrule.dailathon.telecom.DialerInCallService

class HeadsetReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_HEADSET_PLUG) return
        val state = intent.getIntExtra("state", -1)
        Timber.d("HeadsetReceiver: state=$state (1=plugged, 0=unplugged)")

        val service = DialerInCallService.getInstance() ?: return
        val audioRouter = try {
            val field = service.javaClass.getDeclaredField("audioRouter")
            field.isAccessible = true
            field.get(service) as? AudioRouter
        } catch (_: Exception) { null } ?: return

        when (state) {
            1 -> {
                // Headset plugged in — route audio to wired headset
                Timber.d("HeadsetReceiver: Wired headset connected, routing audio")
                audioRouter.setSpeakerPhoneOn(false)
            }
            0 -> {
                // Headset unplugged — fall back to earpiece
                Timber.d("HeadsetReceiver: Wired headset disconnected, falling back to earpiece")
                audioRouter.setSpeakerPhoneOn(false)
            }
        }
    }
}

class BluetoothAudioReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED) return
        val state = intent.getIntExtra(AudioManager.EXTRA_SCO_AUDIO_STATE, -1)
        Timber.d("BluetoothAudioReceiver: SCO state=$state")

        when (state) {
            AudioManager.SCO_AUDIO_STATE_CONNECTED -> {
                Timber.d("BluetoothAudioReceiver: Bluetooth SCO connected")
            }
            AudioManager.SCO_AUDIO_STATE_DISCONNECTED -> {
                Timber.d("BluetoothAudioReceiver: Bluetooth SCO disconnected, falling back")
            }
            AudioManager.SCO_AUDIO_STATE_ERROR -> {
                Timber.e("BluetoothAudioReceiver: Bluetooth SCO error")
            }
        }
    }
}
