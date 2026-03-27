package com.mangrule.dailathon.telecom

import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.os.PowerManager
import android.os.SystemClock
import android.telecom.CallAudioState
import android.telecom.Connection
import android.telecom.DisconnectCause
import android.telecom.TelecomManager
import androidx.core.content.ContextCompat
import timber.log.Timber
import java.util.UUID
import com.mangrule.dailathon.presentation.notification.MissedCallNotification

data class CallStateUpdate(
    val callId: String,
    val state: String,
    val callerNumber: String,
    val callerName: String?,
    val durationSeconds: Int,
    val isMuted: Boolean,
    val isSpeakerOn: Boolean,
    val isBluetoothActive: Boolean,
    val isWiredHeadsetConnected: Boolean,
    val isOnHold: Boolean,
    val disconnectCause: String?,
)

/**
 * DialerConnection represents a single phone call (incoming or outgoing).
 * Manages complete state machine: NEW → DIALING/RINGING → ACTIVE → HELD → DISCONNECTED
 * Coordinates with audio router, vibration manager, and event channel.
 */
class DialerConnection(
    private val context: Context,
) : Connection() {

    // Unique call identifier
    private val callId = UUID.randomUUID().toString()

    // Call lifecycle tracking
    private var callStartTime: Long = 0
    private var isMuted = false
    private var isOnHold = false

    // Resource management
    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: android.net.wifi.WifiManager.WifiLock? = null
    private var screenWakeLock: PowerManager.WakeLock? = null

    init {
        Timber.d("DialerConnection created: callId=$callId")
        setConnectionCapabilities(
            CAPABILITY_SUPPORT_HOLD or
            CAPABILITY_MUTE or
            CAPABILITY_RESPOND_VIA_TEXT or
            CAPABILITY_SEPARATE_FROM_CONFERENCE
        )
    }

    // ========== STATE TRANSITIONS ==========

    override fun onAnswer() {
        super.onAnswer()
        Timber.d("DialerConnection[$callId].onAnswer")

        if (state == STATE_RINGING) {
            setActive()
            callStartTime = SystemClock.uptimeMillis()
            acquireWakeLock()
            acquireScreenWakeLock()  // Keep screen bright during active call

            // Stop vibration
            // pushEventToFlutter() - notify EventChannel
        } else {
            Timber.w("DialerConnection[$callId].onAnswer: ignoring, not in ringing state")
        }
    }

    override fun onReject() {
        super.onReject()
        Timber.d("DialerConnection[$callId].onReject")

        // Show missed call notification for incoming rejected calls
        if (state == STATE_RINGING) {
            val callerNumber = address?.schemeSpecificPart ?: "Unknown"
            val callerName = callerDisplayName ?: "Unknown Caller"
            MissedCallNotification.show(context, callerName, callerNumber)
            Timber.v("DialerConnection[$callId]: Missed call notification shown (user rejected)")
        }

        setDisconnected(DisconnectCause(DisconnectCause.REJECTED))
    }

    override fun onHold() {
        super.onHold()
        Timber.d("DialerConnection[$callId].onHold")

        if (state == STATE_ACTIVE) {
            setOnHold()
            isOnHold = true
            // Suspend audio here
            // pushEventToFlutter()
        } else {
            Timber.w("DialerConnection[$callId].onHold: ignoring, not in active state")
        }
    }

    override fun onUnhold() {
        super.onUnhold()
        Timber.d("DialerConnection[$callId].onUnhold")

        if (state == STATE_HOLDING) {
            setActive()
            isOnHold = false
            // Resume audio here
            // pushEventToFlutter()
        } else {
            Timber.w("DialerConnection[$callId].onUnhold: ignoring, not in holding state")
        }
    }

    override fun onDisconnect() {
        super.onDisconnect()
        Timber.d("DialerConnection[$callId].onDisconnect")

        setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
        cleanup()
    }

    override fun onPlayDtmfTone(c: Char) {
        super.onPlayDtmfTone(c)
        Timber.d("DialerConnection[$callId].onPlayDtmfTone($c)")
        // TODO: Forward to AudioRouter for tone playback
    }

    override fun onStopDtmfTone() {
        super.onStopDtmfTone()
        Timber.d("DialerConnection[$callId].onStopDtmfTone")
        // TODO: Stop tone in AudioRouter
    }

    override fun onSeparate() {
        super.onSeparate()
        Timber.d("DialerConnection[$callId].onSeparate")
        // Remove from conference, restore as standalone
    }

    override fun onMuteStateChanged(isMuted: Boolean) {
        super.onMuteStateChanged(isMuted)
        Timber.d("DialerConnection[$callId].onMuteStateChanged($isMuted)")
        this.isMuted = isMuted
        // Gate microphone input
    }

    override fun onCallAudioStateChanged(state: CallAudioState?) {
        super.onCallAudioStateChanged(state)
        Timber.d("DialerConnection[$callId].onCallAudioStateChanged: $state")
        // Update audio routing based on state
    }

    // ========== CALL INFO & METADATA ==========

    fun getCallId(): String = callId

    fun getCallDurationSeconds(): Int {
        if (callStartTime == 0L) return 0
        return ((SystemClock.uptimeMillis() - callStartTime) / 1000).toInt()
    }

    fun isMuted(): Boolean = isMuted

    fun isOnHold(): Boolean = isOnHold

    // ========== RESOURCE MANAGEMENT ==========

    private fun acquireWakeLock() {
        if (wakeLock == null) {
            val powerManager = ContextCompat.getSystemService(context, PowerManager::class.java)
                ?: return

            try {
                wakeLock = powerManager.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "DialerApp:CallWakeLock[$callId]"
                ).apply {
                    acquire(10 * 60 * 1000L)  // 10 minute timeout
                }
                Timber.d("DialerConnection[$callId]: WakeLock acquired")
            } catch (e: Exception) {
                Timber.e(e, "Error acquiring WakeLock")
            }
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                Timber.d("DialerConnection[$callId]: WakeLock released")
            }
        } catch (e: Exception) {
            Timber.e(e, "Error releasing WakeLock")
        }
        wakeLock = null
    }

    private fun acquireWifiLock() {
        if (wifiLock == null) {
            val wifiManager = ContextCompat.getSystemService(context, android.net.wifi.WifiManager::class.java)
                ?: return

            try {
                wifiLock = wifiManager.createWifiLock(
                    android.net.wifi.WifiManager.WIFI_MODE_FULL_HIGH_PERF,
                    "DialerApp:CallWifiLock[$callId]"
                ).apply {
                    acquire()
                }
                Timber.d("DialerConnection[$callId]: WifiLock acquired")
            } catch (e: Exception) {
                Timber.e(e, "Error acquiring WifiLock")
            }
        }
    }

    private fun releaseWifiLock() {
        try {
            if (wifiLock?.isHeld == true) {
                wifiLock?.release()
                Timber.d("DialerConnection[$callId]: WifiLock released")
            }
        } catch (e: Exception) {
            Timber.e(e, "Error releasing WifiLock")
        }
        wifiLock = null
    }

    private fun acquireScreenWakeLock() {
        if (screenWakeLock != null) {
            Timber.v("DialerConnection[$callId]: Screen WakeLock already acquired")
            return
        }

        val powerManager = ContextCompat.getSystemService(context, PowerManager::class.java)
            ?: return

        try {
            // SCREEN_BRIGHT_WAKE_LOCK: keeps screen bright during call
            // ACQUIRE_CAUSES_WAKEUP: immediately wakes device
            // Paired with proximity sensor (gap 4) that darkens screen on ear contact
            screenWakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "DialerApp:ScreenWakeLock[$callId]"
            ).apply {
                acquire()
            }
            Timber.d("DialerConnection[$callId]: Screen WakeLock acquired (SCREEN_BRIGHT)")
        } catch (e: Exception) {
            Timber.e(e, "Error acquiring screen WakeLock")
        }
    }

    private fun releaseScreenWakeLock() {
        try {
            if (screenWakeLock?.isHeld == true) {
                screenWakeLock?.release()
                Timber.d("DialerConnection[$callId]: Screen WakeLock released")
            }
        } catch (e: Exception) {
            Timber.e(e, "Error releasing screen WakeLock")
        }
        screenWakeLock = null
    }

    private fun cleanup() {
        Timber.d("DialerConnection[$callId]: cleanup")

        releaseWakeLock()
        releaseWifiLock()
        releaseScreenWakeLock()

        // Stop vibration
        // Stop audio
        // Cleanup audio focus
    }

    // ========== CALL STATE HELPERS ==========

    /**
     * Transition to DIALING state for outgoing calls.
     */
    fun setDialing(number: String, displayName: String? = null) {
        Timber.d("DialerConnection[$callId].setDialing($number)")
        setAddress(android.net.Uri.fromParts("tel", number, null), TelecomManager.PRESENTATION_ALLOWED)
        setCallerDisplayName(displayName ?: number, TelecomManager.PRESENTATION_ALLOWED)
        setDialing()
        callStartTime = SystemClock.uptimeMillis()
        acquireWakeLock()
        // Start vibration pattern
    }

    /**
     * Transition to RINGING state for incoming calls.
     */
    fun setRinging(number: String, displayName: String? = null) {
        Timber.d("DialerConnection[$callId].setRinging($number)")
        setAddress(android.net.Uri.fromParts("tel", number, null), TelecomManager.PRESENTATION_ALLOWED)
        setCallerDisplayName(displayName ?: number, TelecomManager.PRESENTATION_ALLOWED)
        setRinging()
        acquireWakeLock()
        // Start ringing vibration pattern
    }

    /**
     * Helper: Check if call is currently active.
     */
    fun isActive(): Boolean = state == STATE_ACTIVE

    /**
     * Helper: Check if call is holding.
     */
    fun isHolding(): Boolean = state == STATE_HOLDING

    /**
     * Helper: Check if call is disconnected.
     */
    fun isDisconnected(): Boolean = state == STATE_DISCONNECTED
}
