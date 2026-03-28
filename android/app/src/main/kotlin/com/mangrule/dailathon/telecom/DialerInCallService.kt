package com.mangrule.dailathon.telecom

import android.telecom.Call
import android.telecom.CallAudioState
import android.telecom.InCallService
import dagger.hilt.android.AndroidEntryPoint
import timber.log.Timber
import javax.inject.Inject
import com.mangrule.dailathon.presentation.channels.CallEventChannelService
import com.mangrule.dailathon.core.models.CallInfo
import com.mangrule.dailathon.core.models.CallState
import com.mangrule.dailathon.core.models.DisconnectCauseMapper
import com.mangrule.dailathon.core.models.toMap
import com.mangrule.dailathon.domain.managers.ProximitySensorManager
import com.mangrule.dailathon.presentation.notification.OngoingCallNotification
import com.mangrule.dailathon.presentation.notification.createOngoingChannel
import com.mangrule.dailathon.multisim.SimManager
import kotlin.time.Duration.Companion.seconds

/**
 * DialerInCallService binds to active calls and provides UI control.
 * This is where we handle:
 * - Hold/Unhold
 * - Merge/Conference operations
 * - Call swap
 * - Mute/audio control
 * 
 * Note: This service must have IN_CALL_SERVICE_UI metadata set to true in manifest.
 */
@AndroidEntryPoint
class DialerInCallService : InCallService() {
    companion object {
        private var instance: DialerInCallService? = null

        fun getInstance(): DialerInCallService? = instance
    }

    @Inject
    lateinit var vibrationManager: com.mangrule.dailathon.vibration.CallVibrationManager

    @Inject
    lateinit var audioRouter: com.mangrule.dailathon.audio.AudioRouter

    @Inject
    lateinit var eventChannelService: CallEventChannelService

    @Inject
    lateinit var callWaitingService: CallWaitingService

    @Inject
    lateinit var proximitySensorManager: ProximitySensorManager

    @Inject
    lateinit var simManager: SimManager

    // Track active calls in this InCallService
    private val activeCalls = mutableListOf<Call>()
    private var activeCall: Call? = null
    private var heldCall: Call? = null

    // Track call start times for duration calculation
    private val callStartTimes = mutableMapOf<Call, Long>()

    override fun onCreate() {
        super.onCreate()
        instance = this
        createOngoingChannel(applicationContext)
        Timber.v("DialerInCallService created and registered as singleton")
    }

    override fun onDestroy() {
        OngoingCallNotification.cancel(applicationContext)
        proximitySensorManager.stop()
        instance = null
        Timber.v("DialerInCallService destroyed")
        super.onDestroy()
    }

    // ========== LIFECYCLE ==========

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        Timber.d("DialerInCallService.onCallAdded: state=${call.state}, handle=${call.details.handle}")

        activeCalls.add(call)

        // Detect call waiting scenario: new call arriving while another is active
        val existingActiveCall = activeCalls.filterNot { it == call }
            .firstOrNull { it.state == Call.STATE_ACTIVE }

        if (existingActiveCall != null && call.state == Call.STATE_RINGING) {
            // This is a CALL WAITING event - use dedicated service
            Timber.d("DialerInCallService: CALL WAITING detected - new incoming call while active")
            callWaitingService.handleIncomingCallWhileActive(existingActiveCall, call)
            pushCallListEvent() // notify Flutter of the waiting call
        } else {
            // Normal call event - push regular state update
            updateCallState(call)
            pushCallListEvent()
        }

        // Register listener to track state changes
        call.registerCallback(
            object : Call.Callback() {
                override fun onStateChanged(call: Call, newState: Int) {
                    Timber.d("DialerInCallService: call state changed to $newState")
                    
                    // If call waiting call state changes, clear the call waiting state
                    if (newState == Call.STATE_ACTIVE || newState == Call.STATE_DISCONNECTED) {
                        callWaitingService.clearCallWaiting()
                    }
                    
                    updateCallState(call)
                    pushCallListEvent()
                    updateDeviceLifecycleState()
                    updateOngoingNotification()
                }

                override fun onDetailsChanged(call: Call, details: Call.Details) {
                    Timber.d("DialerInCallService: call details changed")
                }

                override fun onConferenceableCallsChanged(
                    call: Call,
                    conferenceableCalls: MutableList<Call>,
                ) {
                    Timber.d("DialerInCallService: conferenceable calls changed (${conferenceableCalls.size})")
                }


                override fun onCallDestroyed(call: Call) {
                    Timber.d("DialerInCallService: call destroyed")
                    activeCalls.remove(call)
                    callStartTimes.remove(call)
                    updateDeviceLifecycleState()
                    updateOngoingNotification()
                }
            }
        )

        updateDeviceLifecycleState()
        updateOngoingNotification()
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        Timber.d("DialerInCallService.onCallRemoved: state=${call.state}")

        activeCalls.remove(call)
        if (activeCall == call) activeCall = null
        if (heldCall == call) heldCall = null
        callStartTimes.remove(call)

        pushCallListEvent()
        updateDeviceLifecycleState()
        updateOngoingNotification()
    }

    override fun onCallAudioStateChanged(state: CallAudioState?) {
        super.onCallAudioStateChanged(state)
        Timber.d(
            "DialerInCallService.onCallAudioStateChanged: " +
                    "route=${state?.route}"
        )
        // Push updated audio state to Flutter
        pushCallListEvent()
        updateOngoingNotification()
    }

    // ========== CALL STATE MANAGEMENT ==========

    private fun updateCallState(call: Call) {
        when (call.state) {
            Call.STATE_ACTIVE -> {
                activeCall = call
                // Record start time when call becomes active
                if (!callStartTimes.containsKey(call)) {
                    callStartTimes[call] = android.os.SystemClock.elapsedRealtime()
                }
            }
            Call.STATE_HOLDING -> {
                heldCall = call
            }
            Call.STATE_DIALING, Call.STATE_RINGING -> {
                // Call not yet finalized
            }
            Call.STATE_DISCONNECTED -> {
                activeCalls.remove(call)
            }
        }
    }

    private fun updateDeviceLifecycleState() {
        val hasActiveLikeCall = activeCalls.any {
            it.state == Call.STATE_ACTIVE ||
                it.state == Call.STATE_DIALING ||
                it.state == Call.STATE_CONNECTING ||
                it.state == Call.STATE_RINGING
        }

        if (hasActiveLikeCall) {
            proximitySensorManager.start()
        } else {
            proximitySensorManager.stop()
        }
    }

    private fun updateOngoingNotification() {
        val call = activeCalls.firstOrNull { it.state == Call.STATE_ACTIVE }
        if (call == null) {
            OngoingCallNotification.cancel(applicationContext)
            return
        }

        val number = call.details.handle?.schemeSpecificPart ?: "Unknown"
        val name = call.details.callerDisplayName?.toString()
            ?: call.details.contactDisplayName?.toString()
            ?: number
        val muted = callAudioState?.isMuted ?: false
        val startTime = callStartTimes[call]
        val elapsed = if (startTime != null) {
            ((android.os.SystemClock.elapsedRealtime() - startTime) / 1000).toInt()
        } else {
            0
        }

        OngoingCallNotification.update(
            context = applicationContext,
            callerName = name,
            callerNumber = number,
            isMuted = muted,
            elapsedSeconds = elapsed,
        )
    }

    // ========== CONFERENCE OPERATIONS ==========

    /**
     * Merge the active and held calls into a conference.
     */
    fun mergeActiveCalls() {
        val active = activeCalls.firstOrNull { it.state == Call.STATE_ACTIVE }
        val held = activeCalls.firstOrNull { it.state == Call.STATE_HOLDING }

        if (active != null && held != null) {
            Timber.d("DialerInCallService.mergeActiveCalls")
            try {
                active.conference(held)
            } catch (e: Exception) {
                Timber.e(e, "Error merging calls")
            }
        } else {
            Timber.w("DialerInCallService.mergeActiveCalls: cannot merge (active=$active, held=$held)")
        }
    }

    /**
     * Swap the active and held calls.
     */
    fun swapCalls() {
        val active = activeCalls.firstOrNull { it.state == Call.STATE_ACTIVE }
        val held = activeCalls.firstOrNull { it.state == Call.STATE_HOLDING }

        if (active != null && held != null) {
            Timber.d("DialerInCallService.swapCalls")
            try {
                active.hold()
                held.unhold()
            } catch (e: Exception) {
                Timber.e(e, "Error swapping calls")
            }
        } else {
            Timber.w("DialerInCallService.swapCalls: cannot swap (active=$active, held=$held)")
        }
    }

    /**
     * Check if merge is possible (one active, one held).
     */
    fun canMerge(): Boolean {
        val hasActive = activeCalls.any { it.state == Call.STATE_ACTIVE }
        val hasHeld = activeCalls.any { it.state == Call.STATE_HOLDING }
        return hasActive && hasHeld
    }

    /**
     * Check if swap is possible.
     */
    fun canSwap(): Boolean {
        return canMerge()
    }

    // ========== CALL LIST MANAGEMENT ==========

    fun getActiveCalls(): List<Call> {
        return activeCalls.toList()
    }

    fun getActiveCall(): Call? {
        return activeCall
    }

    fun getHeldCall(): Call? {
        return heldCall
    }

    /**
     * Get call by ID (caller handle).
     * Returns first call matching the handle, or null if not found.
     */
    fun getCallById(callId: String): Call? {
        return activeCalls.firstOrNull { call ->
            call.details.handle?.schemeSpecificPart == callId ||
                    call.details.handle?.toString() == callId
        }
    }

    /**
     * Get first ringing (incoming) call.
     */
    fun getFirstRingingCall(): Call? {
        return activeCalls.firstOrNull { it.state == Call.STATE_RINGING }
    }

    /**
     * Get first active (connected) call.
     */
    fun getFirstActiveCall(): Call? {
        return activeCalls.firstOrNull { it.state == Call.STATE_ACTIVE }
    }

    /**
     * Get first held call.
     */
    fun getFirstHeldCall(): Call? {
        return activeCalls.firstOrNull { it.state == Call.STATE_HOLDING }
    }

    /**
     * Get first call in any state (prioritize active > ringing > dialing > held > other).
     */
    fun getFirstCall(): Call? {
        return getFirstActiveCall()
            ?: getFirstRingingCall()
            ?: activeCalls.firstOrNull { it.state == Call.STATE_DIALING }
            ?: getFirstHeldCall()
            ?: activeCalls.firstOrNull()
    }

    // ========== EVENT PUSHING ==========

    /**
     * Push a call waiting event to Flutter.
     * Called when a new incoming call arrives while another call is active.
     */
    // ── Helper: build CallInfo for a single Call ──────────────────────────────

    private fun buildCallInfo(call: Call): CallInfo {
        val audioState = callAudioState
        val muted = audioState?.isMuted ?: false
        val speaker = audioState?.route == CallAudioState.ROUTE_SPEAKER
        val bluetooth = audioState?.route == CallAudioState.ROUTE_BLUETOOTH

        val callState = when (call.state) {
            Call.STATE_ACTIVE                               -> CallState.ACTIVE
            Call.STATE_RINGING                             -> CallState.RINGING
            Call.STATE_DIALING                             -> CallState.DIALING
            Call.STATE_HOLDING                             -> CallState.HELD
            Call.STATE_DISCONNECTED, Call.STATE_DISCONNECTING -> CallState.DISCONNECTED
            Call.STATE_CONNECTING                          -> CallState.CONNECTING
            else                                           -> CallState.UNKNOWN
        }

        val startTime = callStartTimes[call]
        val durationSecs = if (startTime != null)
            ((android.os.SystemClock.elapsedRealtime() - startTime) / 1000).toInt()
        else 0

        val resolvedSimSlot = resolveSimSlot(call)

        val isOutgoing = call.details.callDirection == Call.Details.DIRECTION_OUTGOING
        val direction = if (isOutgoing) "OUTGOING" else "INCOMING"
        val callStateStr = callState.name

        val disconnectCauseStr = if (call.state == Call.STATE_DISCONNECTED)
            classifyDisconnectCause(call.details.disconnectCause)
        else null

        val disconnectedByStr = if (call.state == Call.STATE_DISCONNECTED)
            DisconnectCauseMapper.mapDisconnectedBy(
                call.details.disconnectCause, callStateStr, direction
            ).name
        else null

        val wasAnswered = durationSecs > 0
        val unansweredReasonStr = if (call.state == Call.STATE_DISCONNECTED && !wasAnswered)
            DisconnectCauseMapper.mapUnansweredReason(call.details.disconnectCause, direction)
        else null

        return CallInfo(
            callId = call.details.handle?.schemeSpecificPart ?: "",
            number = call.details.handle?.schemeSpecificPart ?: "",
            state = callState,
            duration = durationSecs.seconds,
            isOutgoing = isOutgoing,
            isMuted = muted,
            isBluetoothAudio = bluetooth,
            isSpeakerEnabled = speaker,
            isHeld = call.state == Call.STATE_HOLDING,
            simSlot = resolvedSimSlot,
            disconnectCause = disconnectCauseStr,
            disconnectedBy = disconnectedByStr,
            unansweredReason = unansweredReasonStr,
        )
    }

    private fun resolveSimSlot(call: Call): Int {
        return try {
            val accountId = call.details.accountHandle?.id.orEmpty()
            val subscriptionId = when {
                accountId.startsWith("SIM_") -> accountId.removePrefix("SIM_").toIntOrNull()
                else -> accountId.toIntOrNull()
            }

            if (subscriptionId == null) return 0

            val slot = simManager.getActiveSimSlots()
                .firstOrNull { it.subscriptionId == subscriptionId }
                ?.slotIndex

            slot ?: 0
        } catch (_: Exception) {
            0
        }
    }

    // ── Push consolidated MultiCallState map to Flutter ────────────────────────

    private fun pushCallListEvent() {
        try {
            // Select primary call: DIALING/CONNECTING > ACTIVE > RINGING > DISCONNECTED
            val primaryCall = activeCalls.firstOrNull {
                it.state == Call.STATE_DIALING || it.state == Call.STATE_CONNECTING
            } ?: activeCalls.firstOrNull { it.state == Call.STATE_ACTIVE }
              ?: activeCalls.firstOrNull { it.state == Call.STATE_RINGING }
              ?: activeCalls.firstOrNull { it.state == Call.STATE_DISCONNECTED }

            val heldCall = activeCalls.firstOrNull { it.state == Call.STATE_HOLDING }

            // Call waiting: a RINGING call while another call is ACTIVE
            val waitingCall = if (primaryCall?.state == Call.STATE_ACTIVE) {
                activeCalls.firstOrNull { it != primaryCall && it.state == Call.STATE_RINGING }
            } else null

            val multiCallMap: Map<String, Any?> = mapOf(
                "activeCall"  to primaryCall?.let { buildCallInfo(it).toMap() },
                "heldCall"    to heldCall?.let   { buildCallInfo(it).toMap() },
                "waitingCall" to waitingCall?.let { buildCallInfo(it).toMap() },
            )

            eventChannelService.pushRawEvent(multiCallMap)
            Timber.d(
                "pushCallListEvent: primary=${primaryCall?.state}, " +
                "held=${heldCall?.state}, waiting=${waitingCall?.state}"
            )
        } catch (e: Exception) {
            Timber.e(e, "Error pushing call list event")
        }
    }

    /**
     * Map Android DisconnectCause to a human-readable classification.
     */
    private fun classifyDisconnectCause(cause: android.telecom.DisconnectCause?): String {
        return when (cause?.code) {
            android.telecom.DisconnectCause.BUSY -> "busy"
            android.telecom.DisconnectCause.REMOTE -> "remote_hangup"
            android.telecom.DisconnectCause.LOCAL -> "local_hangup"
            android.telecom.DisconnectCause.CANCELED -> "canceled"
            android.telecom.DisconnectCause.MISSED -> "missed"
            android.telecom.DisconnectCause.REJECTED -> "rejected"
            android.telecom.DisconnectCause.RESTRICTED -> "restricted"
            android.telecom.DisconnectCause.ERROR -> "error"
            android.telecom.DisconnectCause.OTHER -> "other"
            android.telecom.DisconnectCause.UNKNOWN -> "unknown"
            else -> "unknown"
        }
    }
}
