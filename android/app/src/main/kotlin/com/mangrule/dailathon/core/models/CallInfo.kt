package com.mangrule.dailathon.core.models

import kotlin.time.Duration

/**
 * Data class representing information about an active phone call.
 * Pushed to Flutter via EventChannel whenever call state changes.
 */
data class CallInfo(
    val callId: String,
    val number: String,
    val state: CallState,
    val duration: Duration,
    val isOutgoing: Boolean,
    val isMuted: Boolean,
    val isBluetoothAudio: Boolean,
    val isSpeakerEnabled: Boolean,
    val isHeld: Boolean,
    val simSlot: Int,
    val disconnectCause: String? = null,
    val disconnectedBy: String? = null,
    val unansweredReason: String? = null,
    val callType: String = "normal",  // "normal", "call_waiting", "conference"
    val callerName: String? = null,
    val callerPhotoUri: String? = null,
    val isConference: Boolean = false,
    val conferenceParticipants: List<String> = emptyList(),
)

/**
 * Convert CallInfo to a Map for transmission over EventChannel to Flutter.
 */
fun CallInfo.toMap(): Map<String, Any?> {
    return mapOf(
        "callId" to callId,
        "number" to number,
        "state" to when (state) {
            CallState.DISCONNECTED -> "ended"
            CallState.ACTIVE       -> "active"
            CallState.RINGING      -> "ringing"
            CallState.DIALING      -> "dialing"
            CallState.HELD         -> "held"
            CallState.CONNECTING   -> "dialing"
            CallState.UNKNOWN      -> "dialing"
        },
        "duration" to duration.inWholeMilliseconds,
        "isOutgoing" to isOutgoing,
        "isMuted" to isMuted,
        "isBluetoothAudio" to isBluetoothAudio,
        "isSpeakerEnabled" to isSpeakerEnabled,
        "isHeld" to isHeld,
        "simSlot" to simSlot,
        "disconnectCause" to (disconnectCause ?: ""),
        "disconnectedBy" to (disconnectedBy ?: ""),
        "unansweredReason" to (unansweredReason ?: ""),
        "callType" to callType,
        "callerName" to (callerName ?: ""),
        "callerPhotoUri" to (callerPhotoUri ?: ""),
        "isConference" to isConference,
        "conferenceParticipants" to conferenceParticipants,
    )
}
