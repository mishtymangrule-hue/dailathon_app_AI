package com.mangrule.dailathon.telecom

import android.os.Build
import android.provider.BlockedNumberContract
import android.telecom.CallScreeningService
import android.telecom.Call
import timber.log.Timber

/**
 * DialerCallScreeningService handles call screening for spam detection and blocking.
 * Requires API 29+.
 */
class DialerCallScreeningService : CallScreeningService() {

    override fun onScreenCall(callDetails: Call.Details) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            Timber.w("CallScreeningService requires API 29+")
            return
        }

        val phoneNumber = callDetails.handle?.schemeSpecificPart ?: ""
        Timber.d("onScreenCall: $phoneNumber")

        // Check if number is in the system blocked list
        val isBlocked = try {
            if (phoneNumber.isNotEmpty()) {
                BlockedNumberContract.isBlocked(this, phoneNumber)
            } else {
                false
            }
        } catch (e: Exception) {
            Timber.e(e, "Error checking blocked number")
            false
        }

        if (isBlocked) {
            Timber.d("Blocking call from $phoneNumber (in blocked list)")
            respondToCall(
                callDetails,
                CallResponse.Builder()
                    .setDisallowCall(true)
                    .setRejectCall(true)
                    .setSkipNotification(true)
                    .build()
            )
        } else {
            respondToCall(
                callDetails,
                CallResponse.Builder()
                    .setDisallowCall(false)
                    .build()
            )
        }
    }
}
