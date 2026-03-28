package com.mangrule.dailathon.telecom

import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.PhoneAccountHandle
import android.content.ComponentName
import dagger.hilt.android.AndroidEntryPoint
import timber.log.Timber
import javax.inject.Inject
import com.mangrule.dailathon.domain.managers.IncomingCallHandler
import com.mangrule.dailathon.presentation.channels.CallEventChannelService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * DialerConnectionService is the core Android Telecom integration point.
 * Handles creation of outgoing and incoming calls in the Telecom framework.
 * 
 * This service bridges Flutter UI with native Android call management.
 * It persists call state and coordinates with DialerInCallService.
 */
@AndroidEntryPoint
class DialerConnectionService : ConnectionService() {

    @Inject
    lateinit var phoneAccountManager: PhoneAccountManager

    @Inject
    lateinit var vibrationManager: com.mangrule.dailathon.vibration.CallVibrationManager

    @Inject
    lateinit var audioRouter: com.mangrule.dailathon.audio.AudioRouter

    @Inject
    lateinit var incomingCallHandler: IncomingCallHandler

    @Inject
    lateinit var callEventChannelService: CallEventChannelService

    private val coroutineScope = CoroutineScope(SupervisorJob())

    // Track active connections in this service
    private val activeConnections = mutableMapOf<String, DialerConnection>()
    private val activeConferences = mutableListOf<DialerConference>()

    // ========== OUTGOING CALLS ==========

    /**
     * Called when the system wants to create an outgoing call through this ConnectionService.
     * Invoked when user initiates a call via dialer or deep link.
     */
    override fun onCreateOutgoingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: ConnectionRequest,
    ): Connection {
        Timber.d(
            "onCreateOutgoingConnection: address=${request.address}, " +
                    "accountHandle=${connectionManagerPhoneAccount.id}"
        )

        // Extract phone number from request
        val phoneNumber = request.address?.schemeSpecificPart ?: ""
        if (phoneNumber.isEmpty()) {
            Timber.w("onCreateOutgoingConnection: empty phone number")
            return Connection.createFailedConnection(
                android.telecom.DisconnectCause(android.telecom.DisconnectCause.ERROR)
            )
        }

        // Create connection object
        val connection = DialerConnection(applicationContext) { conn ->
            pushConnectionUpdate(conn)
        }

        // Set initial call state and metadata
        val displayName = resolveCallerName(phoneNumber)
        connection.setDialing(phoneNumber, displayName)

        // Store connection reference
        activeConnections[connection.getCallId()] = connection

        Timber.d("onCreateOutgoingConnection: created connection ${connection.getCallId()}")
        return connection
    }


    /**
     * Called for new incoming calls.
     * Invoked by the Telecom framework when a call arrives from the carrier.
     */
    override fun onCreateIncomingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: ConnectionRequest,
    ): Connection {
        Timber.d(
            "onCreateIncomingConnection: address=${request.address}, " +
                    "accountHandle=${connectionManagerPhoneAccount.id}"
        )

        // Extract phone number
        val phoneNumber = request.address?.schemeSpecificPart ?: "Unknown"
        val callId = java.util.UUID.randomUUID().toString()

        // Create connection object
        val connection = DialerConnection(applicationContext) { conn ->
            pushConnectionUpdate(conn)
        }

        // Set incoming call state and metadata
        val displayName = resolveCallerName(phoneNumber)
        connection.setRinging(phoneNumber, displayName)

        // Store connection reference
        activeConnections[connection.getCallId()] = connection

        // Show incoming call notification
        coroutineScope.launch {
          incomingCallHandler.handleIncomingCall(
            phoneNumber = phoneNumber,
            callId = callId,
          )
        }

        Timber.d("onCreateIncomingConnection: created connection ${connection.getCallId()}")
        return connection
    }


    // ========== CONNECTION MANAGEMENT ==========

    /**
     * Called when a connection is created to add it to service tracking.
     */
    override fun onConference(connection1: Connection?, connection2: Connection?) {
        super.onConference(connection1, connection2)
        Timber.d("onConference: ${connection1?.state} + ${connection2?.state}")

        val first = connection1 as? DialerConnection
        val second = connection2 as? DialerConnection
        if (first == null || second == null) {
            Timber.w("onConference: non-DialerConnection participants")
            return
        }

        val accountHandle = phoneAccountManager.getDefaultOutgoingAccount()
            ?: PhoneAccountHandle(
                ComponentName(applicationContext, DialerConnectionService::class.java),
                "conference_default"
            )

        val conference = DialerConference(applicationContext, accountHandle)
        conference.addMember(first)
        conference.addMember(second)
        activeConferences.add(conference)
        addConference(conference)
        Timber.d("onConference: created conference with 2 members")
    }

    /**
     * Clean up connections when they're removed.
     */
    fun removeConnection(callId: String) {
        activeConnections.remove(callId)
        Timber.d("DialerConnectionService.removeConnection: $callId")
    }

    fun getConnection(callId: String): DialerConnection? {
        return activeConnections[callId]
    }

    fun getTrackedConnections(): List<DialerConnection> {
        return activeConnections.values.toList()
    }

    // ========== HELPER METHODS ==========

    /**
     * Resolve caller display name from phone number.
     * TODO: Integrate with ContactsRepository for lookup.
     */
    private fun resolveCallerName(phoneNumber: String): String? {
        // TODO: Query contacts database for name
        // For now, just return null to use number in UI
        return null
    }

    private fun pushConnectionUpdate(connection: DialerConnection) {
        val stateLabel = when (connection.state) {
            Connection.STATE_ACTIVE -> "active"
            Connection.STATE_RINGING -> "ringing"
            Connection.STATE_DIALING -> "dialing"
            Connection.STATE_HOLDING -> "held"
            Connection.STATE_DISCONNECTED -> "ended"
            else -> "unknown"
        }

        val event = mapOf(
            "activeCall" to mapOf(
                "callId" to connection.getCallId(),
                "number" to (connection.address?.schemeSpecificPart ?: ""),
                "state" to stateLabel,
                "duration" to connection.getCallDurationSeconds() * 1000,
                "isOutgoing" to true,
                "isMuted" to connection.isMuted(),
                "isBluetoothAudio" to false,
                "isSpeakerEnabled" to false,
                "isHeld" to connection.isOnHold(),
                "simSlot" to 0,
                "disconnectCause" to "",
            ),
            "heldCall" to null,
            "waitingCall" to null,
        )

        callEventChannelService.pushRawEvent(event)
    }

    /**
     * Called when the system fails to create an outgoing connection.
     */
    override fun onCreateOutgoingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?,
    ) {
        Timber.e(
            "onCreateOutgoingConnectionFailed: account=$connectionManagerPhoneAccount, " +
                    "address=${request?.address}"
        )
        super.onCreateOutgoingConnectionFailed(connectionManagerPhoneAccount, request)
    }

    /**
     * Called when the system fails to create an incoming connection.
     */
    override fun onCreateIncomingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?,
    ) {
        Timber.e(
            "onCreateIncomingConnectionFailed: account=$connectionManagerPhoneAccount, " +
                    "address=${request?.address}"
        )
        super.onCreateIncomingConnectionFailed(connectionManagerPhoneAccount, request)
    }
}
