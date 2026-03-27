package com.mangrule.dailathon.telecom

import android.content.Context
import android.telecom.Conference
import android.telecom.Connection
import android.telecom.DisconnectCause
import android.telecom.PhoneAccountHandle
import timber.log.Timber
import java.util.UUID

/**
 * DialerConference represents a multi-party call conference.
 * Handles merging of calls, separation, hold/unhold of all members.
 */
class DialerConference(
    private val context: Context,
    private val phoneAccountHandle: PhoneAccountHandle,
) : Conference(phoneAccountHandle) {

    private val conferenceId = UUID.randomUUID().toString()
    private val memberConnections = mutableListOf<DialerConnection>()

    init {
        Timber.d("DialerConference created: confId=$conferenceId")
        setConnectionCapabilities(
            Connection.CAPABILITY_SUPPORT_HOLD or
            Connection.CAPABILITY_MERGE_CONFERENCE or
            Connection.CAPABILITY_SWAP_CONFERENCE
        )
    }

    // ========== CONFERENCE OPERATIONS ==========

    /**
     * Add a connection to this conference.
     */
    fun addMember(connection: DialerConnection) {
        Timber.d("DialerConference[$conferenceId].addMember: ${connection.getCallId()}")
        memberConnections.add(connection)
        updateConferenceState()
    }

    /**
     * Get all member connections.
     */
    fun getMembers(): List<DialerConnection> {
        return memberConnections.toList()
    }

    /**
     * Check if this is a valid conference (2+ members).
     */
    fun isValid(): Boolean {
        return memberConnections.size >= 2
    }

    // ========== STATE MANAGEMENT ==========

    override fun onHold() {
        super.onHold()
        Timber.d("DialerConference[$conferenceId].onHold: putting all ${memberConnections.size} members on hold")

        for (member in memberConnections) {
            try {
                member.setOnHold()
            } catch (e: Exception) {
                Timber.e(e, "Error holding member ${member.getCallId()}")
            }
        }
    }

    override fun onUnhold() {
        super.onUnhold()
        Timber.d("DialerConference[$conferenceId].onUnhold: resuming all ${memberConnections.size} members")

        for (member in memberConnections) {
            try {
                member.setActive()
            } catch (e: Exception) {
                Timber.e(e, "Error unholding member ${member.getCallId()}")
            }
        }
    }

    override fun onDisconnect() {
        super.onDisconnect()
        Timber.d("DialerConference[$conferenceId].onDisconnect: disconnecting all ${memberConnections.size} members")

        for (member in memberConnections) {
            try {
                member.setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
            } catch (e: Exception) {
                Timber.e(e, "Error disconnecting member ${member.getCallId()}")
            }
        }

        setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
    }

    override fun onSeparate(connection: Connection?) {
        super.onSeparate(connection)
        Timber.d("DialerConference[$conferenceId].onSeparate: removing connection")

        if (connection is DialerConnection) {
            memberConnections.remove(connection)
            connection.setActive()  // Restore as standalone call

            if (memberConnections.size < 2) {
                Timber.d("DialerConference[$conferenceId]: no longer valid (${memberConnections.size} members)")
                setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
            }
        }
    }

    override fun onMerge(connection: Connection?) {
        super.onMerge(connection)
        Timber.d("DialerConference[$conferenceId].onMerge: adding connection")

        if (connection is DialerConnection) {
            addMember(connection)
        }
    }

    // ========== HELPERS ==========

    private fun updateConferenceState() {
        setConnectionCapabilities(
            Connection.CAPABILITY_SUPPORT_HOLD or
            Connection.CAPABILITY_MERGE_CONFERENCE or
            Connection.CAPABILITY_SWAP_CONFERENCE
        )

        Timber.d("DialerConference[$conferenceId].updateConferenceState: members=${memberConnections.size}, valid=${isValid()}")
    }
}
