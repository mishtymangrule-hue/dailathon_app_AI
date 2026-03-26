package com.mangrule.dailathon.multisim

import android.content.Context
import android.os.Build
import android.telecom.TelecomManager
import android.telephony.SubscriptionManager
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import timber.log.Timber

data class SimSlotInfo(
    val subscriptionId: Int,
    val slotIndex: Int,
    val displayName: String,
    val iccId: String,
    val isDefault: Boolean,
)

/**
 * SimManager handles multi-SIM enumeration and default SIM selection.
 * Supports API 21+ with fallback for single-SIM devices.
 */
@Singleton
class SimManager @Inject constructor(
    @ApplicationContext private val context: Context,
) {

    fun getActiveSimSlots(): List<SimSlotInfo> {
        if (!context.packageManager.hasSystemFeature("android.hardware.telephony")) {
            return emptyList()
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            getActiveSimSlotsApi22Plus()
        } else {
            // API 21: single SIM only
            listOf(
                SimSlotInfo(
                    subscriptionId = 0,
                    slotIndex = 0,
                    displayName = "SIM 1",
                    iccId = "",
                    isDefault = true
                )
            )
        }
    }

    private fun getActiveSimSlotsApi22Plus(): List<SimSlotInfo> {
        return try {
            val sm = context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE)
                    as? SubscriptionManager ?: return emptyList()

            val defaultVoiceSubId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                SubscriptionManager.getDefaultVoiceSubscriptionId()
            } else {
                SubscriptionManager.getDefaultSubscriptionId()
            }

            sm.activeSubscriptionInfoList?.map { sub ->
                SimSlotInfo(
                    subscriptionId = sub.subscriptionId,
                    slotIndex = sub.simSlotIndex,
                    displayName = sub.displayName?.toString() ?: "SIM ${sub.simSlotIndex + 1}",
                    iccId = sub.iccId ?: "",
                    isDefault = sub.subscriptionId == defaultVoiceSubId
                )
            } ?: emptyList()
        } catch (e: Exception) {
            Timber.e(e, "Error getting SIM slots")
            emptyList()
        }
    }

    fun getDefaultVoiceSubscriptionId(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            SubscriptionManager.getDefaultVoiceSubscriptionId()
        } else {
            0
        }
    }
}
