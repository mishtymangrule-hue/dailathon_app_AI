package com.mangrule.dailathon.telecom

import android.os.Build
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

        Timber.d("onScreenCall: ${callDetails.handle}")

        // TODO: Implement spam detection and blocking logic
        // For now, allow all calls
        respondToCall(callDetails, CallResponse.Builder().setDisallowCall(false).build())
    }
}
