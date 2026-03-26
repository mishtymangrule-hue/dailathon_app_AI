package com.mangrule.dailathon.core.models

/**
 * Enum representing the state of a phone call.
 */
enum class CallState {
    UNKNOWN,
    CONNECTING,
    RINGING,
    DIALING,
    ACTIVE,
    HELD,
    DISCONNECTED;

    /**
     * Get human-readable name of call state.
     */
    fun displayName(): String = when (this) {
        UNKNOWN -> "Unknown"
        CONNECTING -> "Connecting"
        RINGING -> "Ringing"
        DIALING -> "Dialing"
        ACTIVE -> "Active"
        HELD -> "On Hold"
        DISCONNECTED -> "Disconnected"
    }
}
