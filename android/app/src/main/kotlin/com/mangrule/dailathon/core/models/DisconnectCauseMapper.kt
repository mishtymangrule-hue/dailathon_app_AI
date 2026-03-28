package com.mangrule.dailathon.core.models

import android.telecom.DisconnectCause

enum class DisconnectedBy {
    USER, LEAD, SYSTEM
}

object DisconnectCauseMapper {

    fun mapDisconnectedBy(
        cause: DisconnectCause?,
        callState: String,
        direction: String,
    ): DisconnectedBy {
        if (cause == null) return DisconnectedBy.SYSTEM

        return when (cause.code) {
            // Agent took an action to end or reject the call
            DisconnectCause.LOCAL -> DisconnectedBy.USER

            // Remote party (lead) took an action
            DisconnectCause.REMOTE -> DisconnectedBy.LEAD

            // Lead explicitly rejected the outgoing call
            DisconnectCause.REJECTED -> DisconnectedBy.LEAD

            // Lead's line was busy
            DisconnectCause.BUSY -> DisconnectedBy.LEAD

            // Ring timeout — lead did not pick up
            DisconnectCause.ANSWERED_ELSEWHERE,
            -> DisconnectedBy.SYSTEM

            // Canceled: agent hung up before connect (outgoing) or missed (incoming)
            DisconnectCause.CANCELED -> {
                if (direction == "OUTGOING") DisconnectedBy.USER
                else DisconnectedBy.LEAD
            }

            // Incoming call not answered by agent — missed
            DisconnectCause.MISSED -> {
                if (direction == "INCOMING" && callState == "RINGING") {
                    DisconnectedBy.LEAD
                } else {
                    DisconnectedBy.SYSTEM
                }
            }

            // Network or carrier dropped the call
            DisconnectCause.ERROR -> DisconnectedBy.SYSTEM
            DisconnectCause.RESTRICTED -> DisconnectedBy.SYSTEM
            DisconnectCause.CALL_PULLED -> DisconnectedBy.SYSTEM

            // Unknown — default to SYSTEM to avoid misattribution
            else -> DisconnectedBy.SYSTEM
        }
    }

    fun mapUnansweredReason(
        cause: DisconnectCause?,
        direction: String,
    ): String? {
        if (cause == null) return null

        return when (cause.code) {
            DisconnectCause.REJECTED -> {
                if (direction == "INCOMING") "EMPLOYEE_REJECTED_INCOMING"
                else "LEAD_REJECTED"
            }
            DisconnectCause.BUSY -> "LEAD_REJECTED"
            DisconnectCause.MISSED -> "MISSED_INCOMING"
            DisconnectCause.CANCELED -> {
                if (direction == "OUTGOING") "EMPLOYEE_ENDED_BEFORE_CONNECT"
                else "MISSED_INCOMING"
            }
            DisconnectCause.LOCAL -> {
                if (direction == "INCOMING") "EMPLOYEE_REJECTED_INCOMING"
                else "EMPLOYEE_ENDED_BEFORE_CONNECT"
            }
            DisconnectCause.REMOTE -> "LEAD_NO_ANSWER"
            else -> null
        }
    }
}
