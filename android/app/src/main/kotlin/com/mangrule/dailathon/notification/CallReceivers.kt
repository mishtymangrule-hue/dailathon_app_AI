package com.mangrule.dailathon.notification

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import timber.log.Timber
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject
import com.mangrule.dailathon.domain.managers.CallOperationsManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

@AndroidEntryPoint
class IncomingCallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Timber.d("IncomingCallReceiver.onReceive: ${intent.action}")
    }
}

@AndroidEntryPoint
class AnswerCallReceiver : BroadcastReceiver() {
    @Inject
    lateinit var callOperationsManager: CallOperationsManager

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onReceive(context: Context, intent: Intent) {
        Timber.d("AnswerCallReceiver.onReceive")
        try {
            val callId = intent.getStringExtra("callId") ?: ""
            scope.launch {
                callOperationsManager.answerCall(callId)
                Timber.v("AnswerCallReceiver: answered call $callId")
            }
        } catch (e: Exception) {
            Timber.e(e, "AnswerCallReceiver: error answering call")
        }
    }
}

@AndroidEntryPoint
class DeclineCallReceiver : BroadcastReceiver() {
    @Inject
    lateinit var callOperationsManager: CallOperationsManager

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onReceive(context: Context, intent: Intent) {
        Timber.d("DeclineCallReceiver.onReceive")
        try {
            val callId = intent.getStringExtra("callId") ?: ""
            scope.launch {
                callOperationsManager.hangUpCall(callId)
                Timber.v("DeclineCallReceiver: declined call $callId")
            }
        } catch (e: Exception) {
            Timber.e(e, "DeclineCallReceiver: error declining call")
        }
    }
}

/**
 * Handles mute/unmute action from ongoing call notification.
 */
@AndroidEntryPoint
class MuteCallReceiver : BroadcastReceiver() {
    @Inject
    lateinit var callOperationsManager: CallOperationsManager

    override fun onReceive(context: Context, intent: Intent) {
        Timber.d("MuteCallReceiver.onReceive toggle mute")
        try {
            val callId = intent.getStringExtra("callId") ?: ""
            val currentlyMuted = intent.getBooleanExtra("isMuted", false)
            intent.apply {
                putExtra("isMuted", !currentlyMuted)
            }
            callOperationsManager.muteCall(callId, !currentlyMuted)
            Timber.v("MuteCallReceiver: toggled mute for $callId")
        } catch (e: Exception) {
            Timber.e(e, "MuteCallReceiver: error toggling mute")
        }
    }
}

/**
 * Handles hangup action from ongoing call notification.
 */
@AndroidEntryPoint
class HangUpCallReceiver : BroadcastReceiver() {
    @Inject
    lateinit var callOperationsManager: CallOperationsManager

    override fun onReceive(context: Context, intent: Intent) {
        Timber.d("HangUpCallReceiver.onReceive")
        try {
            val callId = intent.getStringExtra("callId") ?: ""
            callOperationsManager.hangUpCall(callId)
            Timber.v("HangUpCallReceiver: hung up call $callId")
        } catch (e: Exception) {
            Timber.e(e, "HangUpCallReceiver: error hanging up call")
        }
    }
}
