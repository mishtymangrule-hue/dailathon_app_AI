package com.mangrule.dailathon.audio

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import timber.log.Timber

class HeadsetReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Timber.d("HeadsetReceiver.onReceive: ${intent.action}")
    }
}

class BluetoothAudioReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Timber.d("BluetoothAudioReceiver.onReceive: ${intent.action}")
    }
}
