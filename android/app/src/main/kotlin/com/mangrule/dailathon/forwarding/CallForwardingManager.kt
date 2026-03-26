package com.mangrule.dailathon.forwarding

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.telecom.TelecomManager
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import timber.log.Timber

/**
 * CallForwardingManager handles call forwarding configuration via MMI codes.
 * Supports all four forwarding conditions: unconditional, busy, no-answer, unreachable.
 * 
 * MMI codes follow ITU-T standard:
 * - **21*<number># : Unconditional forwarding enable
 * - ##21# : Unconditional forwarding disable
 * - **67*<number># : Busy forwarding enable
 * - ##67# : Busy forwarding disable
 * - **61*<number># : No answer forwarding enable
 * - ##61# : No answer forwarding disable
 * - **62*<number># : Unreachable forwarding enable
 * - ##62# : Unreachable forwarding disable
 */
@Singleton
class CallForwardingManager @Inject constructor(
    @ApplicationContext private val context: Context,
) {

    /**
     * Set call forwarding for a given reason.
     * @param enabled true to enable, false to disable
     * @param number forwarding number (ignored if disabled)
     * @param reason 0=unconditional, 1=busy, 2=no-answer, 3=unreachable
     */
    fun setForwarding(enabled: Boolean, number: String?, reason: Int = 0) {
        if (enabled && number.isNullOrBlank()) {
            Timber.w("CallForwardingManager.setForwarding: cannot enable without number")
            return
        }

        val mmiCode = buildMmiCode(enabled, number, reason)
        Timber.d("CallForwardingManager.setForwarding: $mmiCode")

        dialMmiCode(mmiCode)
    }

    /**
     * Build MMI code for call forwarding.
     */
    private fun buildMmiCode(enabled: Boolean, number: String?, reason: Int): String {
        val serviceCode = getServiceCode(reason)

        return if (enabled && !number.isNullOrBlank()) {
            // Enable with number
            "**$serviceCode*${number.trim()}#"
        } else {
            // Disable
            "##$serviceCode#"
        }
    }

    /**
     * Get service code for each forwarding reason.
     */
    private fun getServiceCode(reason: Int): String {
        return when (reason) {
            0 -> "21"   // Unconditional
            1 -> "67"   // Busy
            2 -> "61"   // No answer
            3 -> "62"   // Unreachable
            else -> "21"
        }
    }

    /**
     * Dial MMI code via TelecomManager.
     */
    private fun dialMmiCode(mmiCode: String) {
        try {
            val uri = Uri.fromParts("tel", mmiCode, null)
            val intent = Intent(Intent.ACTION_CALL, uri).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            Timber.d("CallForwardingManager.dialMmiCode: initiated")
        } catch (e: Exception) {
            Timber.e(e, "Error dialing MMI code")
        }
    }

    /**
     * Get readable name for forwarding reason.
     */
    fun getReasonName(reason: Int): String {
        return when (reason) {
            0 -> "Unconditional"
            1 -> "Busy"
            2 -> "No Answer"
            3 -> "Unreachable"
            else -> "Unknown"
        }
    }
}
