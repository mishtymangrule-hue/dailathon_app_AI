package com.mangrule.dailathon.domain.managers

import android.telecom.Call
import dagger.hilt.android.qualifiers.ApplicationContext
import timber.log.Timber
import com.mangrule.dailathon.presentation.notifications.IncomingCallNotificationManager
import com.mangrule.dailathon.contacts.ContactsRepository
import android.content.Context
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Handles incoming call interception and notification display.
 * Bridges between DialerConnectionService and IncomingCallNotificationManager.
 */
@Singleton
class IncomingCallHandler @Inject constructor(
  @ApplicationContext private val context: Context,
  private val notificationManager: IncomingCallNotificationManager,
  private val contactsRepository: ContactsRepository,
) {

  /**
   * Process incoming call and show notification.
   * Called from DialerConnectionService.onCreateIncomingConnection()
   */
  suspend fun handleIncomingCall(
    phoneNumber: String,
    callId: String,
  ) {
    try {
      // Look up contact display name
      val displayName = try {
        contactsRepository.lookupByNumber(phoneNumber)?.name
      } catch (e: Exception) {
        Timber.w(e, "Failed to lookup contact for $phoneNumber")
        null
      }

      Timber.v("Incoming call: $phoneNumber, name=$displayName, callId=$callId")

      // Show full-screen notification
      notificationManager.showIncomingCallNotification(
        phoneNumber = phoneNumber,
        displayName = displayName,
        callId = callId,
      )
    } catch (e: Exception) {
      Timber.e(e, "Error handling incoming call")
    }
  }

  /**
   * Call answered - update or clear notification.
   */
  fun onCallAnswered(phoneNumber: String) {
    try {
      Timber.v("Call answered: $phoneNumber")
      // Keep notification minimized while in call
      notificationManager.cancelIncomingCallNotification()
    } catch (e: Exception) {
      Timber.e(e, "Error on call answered")
    }
  }

  /**
   * Call rejected - clear notification.
   */
  fun onCallRejected(phoneNumber: String) {
    try {
      Timber.v("Call rejected: $phoneNumber")
      notificationManager.cancelIncomingCallNotification()
    } catch (e: Exception) {
      Timber.e(e, "Error on call rejected")
    }
  }

  /**
   * Call ended - clear notification.
   */
  fun onCallEnded(phoneNumber: String) {
    try {
      Timber.v("Call ended: $phoneNumber")
      notificationManager.cancelIncomingCallNotification()
    } catch (e: Exception) {
      Timber.e(e, "Error on call ended")
    }
  }
}
