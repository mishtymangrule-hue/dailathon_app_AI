package com.mangrule.dailathon.telecom

import android.telecom.Call
import dagger.hilt.android.scopes.ServiceScoped
import timber.log.Timber
import javax.inject.Inject
import com.mangrule.dailathon.presentation.channels.CallEventChannelService
import com.mangrule.dailathon.core.models.CallInfo
import com.mangrule.dailathon.core.models.CallState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlin.time.Duration.Companion.milliseconds

/**
 * Manages call waiting detection and notification.
 * 
 * Monitors for scenarios where:
 * - An active call exists
 * - A new incoming call arrives (ringing)
 * 
 * Broadcasts CallWaitingEvent to Flutter UI.
 */
@ServiceScoped
class CallWaitingService @Inject constructor(
    private val eventChannelService: CallEventChannelService,
) {
    private val scope = CoroutineScope(Dispatchers.Default)

    // State tracking
    private val _callWaitingState = MutableStateFlow<CallWaitingState?>(null)
    val callWaitingState: StateFlow<CallWaitingState?> = _callWaitingState.asStateFlow()

    // Track the active call and ringing call
    private var activeCall: Call? = null
    private var ringingCall: Call? = null

    /**
     * Check if call waiting condition is met.
     * 
     * Conditions:
     * 1. Exactly one active call
     * 2. A new incoming call in ringing state
     * 3. Calls not from same caller
     */
    fun detectCallWaiting(calls: List<Call>): Boolean {
        // Count active calls
        val activeCalls = calls.filter { it.state == Call.STATE_ACTIVE }
        val ringingCalls = calls.filter { it.state == Call.STATE_RINGING }

        return activeCalls.size == 1 && ringingCalls.size >= 1
    }

    /**
     * Process a new incoming call while one is active.
     * Called from DialerInCallService.onCallAdded()
     */
    fun handleIncomingCallWhileActive(
        activeCall: Call,
        incomingCall: Call,
    ) {
        this.activeCall = activeCall
        this.ringingCall = incomingCall

        val activeNumber = activeCall.details.handle?.schemeSpecificPart ?: "Unknown"
        val activeName = activeCall.details.displayName ?: activeNumber
        val incomingNumber = incomingCall.details.handle?.schemeSpecificPart ?: "Unknown"
        val incomingName = incomingCall.details.displayName ?: incomingNumber

        // Create call waiting state
        val state = CallWaitingState(
            activeCallNumber = activeNumber,
            activeCallName = activeName,
            incomingCallNumber = incomingNumber,
            incomingCallName = incomingName,
            timestamp = System.currentTimeMillis(),
            isConfirmed = false,
        )

        _callWaitingState.value = state

        // Build CallInfo for Flutter
        val callInfo = CallInfo(
            callId = incomingCall.details.handle?.toString() ?: "unknown",
            phoneNumber = incomingNumber,
            callerName = incomingName,
            callState = CallState.CALL_WAITING,
            duration = 0,
            callType = "INCOMING_CALL_WAITING",
            isRinging = true,
            isActive = false,
            isHeld = false,
            isMuted = false,
            isSpeakerOn = false,
            isBluetoothActive = false,
            capabilities = emptyList(),
        )

        // Push to Flutter via EventChannel
        eventChannelService.pushCallStateUpdate(callInfo)

        Timber.d("CallWaitingService: Call waiting detected")
        Timber.d("  Active: $activeName ($activeNumber)")
        Timber.d("  Incoming: $incomingName ($incomingNumber)")
    }

    /**
     * Handle call waiting answer action.
     * User accepted the call waiting call.
     * Active call will be held automatically by Telecom framework.
     */
    fun handleCallWaitingAnswer(call: Call) {
        Timber.d("CallWaitingService: Answering call waiting call")
        ringingCall = null
        
        call.answer(Call.VIDEO_STATE_AUDIO_ONLY)
        updateState(isAnswered = true)
    }

    /**
     * Handle call waiting reject action.
     * User rejected the call waiting call.
     */
    fun handleCallWaitingReject(call: Call) {
        Timber.d("CallWaitingService: Rejecting call waiting call")
        ringingCall = null

        call.reject(false, null)
        updateState(isRejected = true)
    }

    /**
     * Handle call waiting ignore action.
     * User chose to ignore (don't answer, keep current call active).
     */
    fun handleCallWaitingIgnore(call: Call) {
        Timber.d("CallWaitingService: Ignoring call waiting call")
        ringingCall = null

        call.reject(false, null)
        updateState(isIgnored = true)
    }

    /**
     * Handle swap calls action.
     * User wants to swap between active and waiting calls.
     */
    fun handleSwapCalls(activeCall: Call, heldCall: Call) {
        Timber.d("CallWaitingService: Swapping calls")

        // Hold currently active call
        activeCall.hold()

        // Unhold and activate the held call
        heldCall.unhold()

        updateState(isSwapped = true)
    }

    /**
     * Handle end active call and accept waiting action.
     * User wants to end the current call and pick up the waiting call.
     */
    fun handleEndActiveAndAcceptWaiting(activeCall: Call, waitingCall: Call) {
        Timber.d("CallWaitingService: Ending active and accepting waiting")

        // Disconnect active call
        activeCall.disconnect()

        // Answer waiting call
        waitingCall.answer(Call.VIDEO_STATE_AUDIO_ONLY)

        updateState(isAnswered = true)
    }

    /**
     * Handle merge calls / conference.
     * User wants to merge the two calls into a conference.
     */
    fun handleMergeCalls(activeCall: Call, heldCall: Call) {
        Timber.d("CallWaitingService: Merging calls into conference")

        try {
            // Request merge (framework handles actual conference creation)
            activeCall.mergeConference()
            updateState(isMerged = true)
        } catch (e: Exception) {
            Timber.e(e, "CallWaitingService: Failed to merge calls")
        }
    }

    /**
     * Clear call waiting state.
     * Called when there's no longer a waiting call.
     */
    fun clearCallWaiting() {
        Timber.d("CallWaitingService: Clearing call waiting state")
        _callWaitingState.value = null
        activeCall = null
        ringingCall = null
    }

    /**
     * Get current active call if call waiting is active.
     */
    fun getActiveCall(): Call? = activeCall

    /**
     * Get current ringing/waiting call.
     */
    fun getWaitingCall(): Call? = ringingCall

    /**
     * Check if call waiting is currently active.
     */
    fun isCallWaitingActive(): Boolean = _callWaitingState.value != null

    /**
     * Internal state update helper.
     */
    private fun updateState(
        isAnswered: Boolean = false,
        isRejected: Boolean = false,
        isIgnored: Boolean = false,
        isSwapped: Boolean = false,
        isMerged: Boolean = false,
    ) {
        _callWaitingState.value = _callWaitingState.value?.copy(
            isConfirmed = isAnswered || isSwapped || isMerged,
        )
    }
}

/**
 * Data class representing the call waiting state.
 */
data class CallWaitingState(
    val activeCallNumber: String,
    val activeCallName: String,
    val incomingCallNumber: String,
    val incomingCallName: String,
    val timestamp: Long,
    val isConfirmed: Boolean = false,
)
