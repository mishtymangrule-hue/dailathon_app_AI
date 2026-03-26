package com.mangrule.dailathon.telecom

import android.content.Context
import android.net.Uri
import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import dagger.hilt.android.AndroidEntryPoint
import timber.log.Timber
import javax.inject.Inject
import com.mangrule.dailathon.domain.managers.IncomingCallHandler
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

    private val coroutineScope = CoroutineScope(SupervisorJob())

    // Track active connections in this service
    private val activeConnections = mutableMapOf<String, DialerConnection>()

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
        val connection = DialerConnection(applicationContext)

        // Set initial call state and metadata
        val displayName = resolveCallerName(phoneNumber)
        connection.setDialing(phoneNumber, displayName)

        // Store connection reference
        activeConnections[connection.getCallId()] = connection

        Timber.d("onCreateOutgoingConnection: created connection ${connection.getCallId()}")
        return connection
    }

    /**
     * Called when creating a conference connection (call merge).
     */
    override fun onCreateConference(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: android.telecom.ConferenceRequest,
    ): android.telecom.Conference {
        Timber.d("onCreateConference: ${request.conferenceParticipants.size} participants")

        val conference = DialerConference(applicationContext, connectionManagerPhoneAccount)
        return conference
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
        val connection = DialerConnection(applicationContext)

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

    /**
     * Called for unmanaged incoming calls (calls not through Telecom).
     * Less commonly invoked but provides fallback handling.
     */
    override fun onCreateUnknownConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: ConnectionRequest,
    ): Connection {
        Timber.d("onCreateUnknownConnection: address=${request.address}")

        // Treat as incoming call
        return onCreateIncomingConnection(connectionManagerPhoneAccount, request)
    }

    // ========== CONNECTION MANAGEMENT ==========

    /**
     * Called when a connection is created to add it to service tracking.
     */
    override fun onConference(connection1: Connection?, connection2: Connection?) {
        super.onConference(connection1, connection2)
        Timber.d("onConference: ${connection1?.state} + ${connection2?.state}")
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

    fun getAllConnections(): List<DialerConnection> {
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

    override fun onBindings() {
        super.onBindings()
        Timber.d("DialerConnectionService.onBindings")
    }

    override fun onUnbindings() {
        super.onUnbindings()
        Timber.d("DialerConnectionService.onUnbindings")
    }
}
