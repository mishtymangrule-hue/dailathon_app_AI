package com.mangrule.dailathon.domain.managers

import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.TelephonyManager
import dagger.hilt.android.qualifiers.ApplicationContext
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton
import com.mangrule.dailathon.presentation.channels.UssdEventChannelService

/**
 * Handles USSD and MMI code detection and execution.
 * MMI codes are asterisk/hash sequences (e.g., *#06# for IMEI, *100# for USSD)
 */
@Singleton
class UssdManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val ussdEventChannelService: UssdEventChannelService,
) {
    private val teleManager: TelephonyManager =
        context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

    // Intercept-and-handle codes (return true if handled, false otherwise)
    fun interceptInteractiveCode(code: String): Boolean {
        return when {
            // IMEI code: do not dial, show locally
            code.matches(Regex("^\\*#06#$")) -> {
                val imei = getImei()
                Timber.v("IMEI: $imei")
                ussdEventChannelService.pushInteractiveCodeResult("IMEI", imei)
                true
            }
            // Device info code
            code.matches(Regex("^\\*#\\*#4636#\\*#\\*$")) -> {
                Timber.v("Device info code intercepted")
                ussdEventChannelService.pushInteractiveCodeResult("DEVICE_INFO", "Opening device info...")
                true
            }
            else -> false
        }
    }

    fun sendUssd(code: String, subscriptionId: Int = -1) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val tm = if (subscriptionId > 0) {
                teleManager.createForSubscriptionId(subscriptionId)
            } else {
                teleManager
            }

            tm.sendUssdRequest(code, object :
                TelephonyManager.UssdResponseCallback() {
                override fun onReceiveUssdResponse(
                    telephonyManager: TelephonyManager,
                    request: String,
                    response: CharSequence
                ) {
                    Timber.v("USSD response: $response")
                    ussdEventChannelService.pushUssdResponse(request, response.toString())
                }

                override fun onReceiveUssdResponseFailed(
                    telephonyManager: TelephonyManager,
                    request: String,
                    failureCode: Int
                ) {
                    Timber.e("USSD failed (code=$failureCode): $request")
                    ussdEventChannelService.pushUssdFailure(
                        request, 
                        failureCode,
                        "USSD request failed with code $failureCode"
                    )
                }
            }, Handler(Looper.getMainLooper()))
        } else {
            // API < 26: fall back to dialing the USSD code directly
            val uri = Uri.fromParts("tel", Uri.encode(code), null)
            // TODO: Dial using placeCall
            Timber.v("USSD code dialed (API < 26): $code")
        }
    }

    fun isUssdOrMmi(input: String): Boolean {
        // MMI: starts with *, #, or + and ends with #
        val mmiPattern = Regex("^[*#\\+][0-9*#]*#$")
        // USSD: starts with * or # followed by digits and ends with #
        val ussdPattern = Regex("^[*#][0-9*#]+#$")
        return mmiPattern.containsMatchIn(input) || ussdPattern.containsMatchIn(input)
    }

    @Suppress("DEPRECATION")
    private fun getImei(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            teleManager.imei ?: "Unknown"
        } else {
            teleManager.deviceId ?: "Unknown"
        }
    }
}
