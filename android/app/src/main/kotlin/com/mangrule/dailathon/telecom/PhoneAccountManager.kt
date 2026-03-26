package com.mangrule.dailathon.telecom

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import timber.log.Timber

/**
 * PhoneAccountManager handles registration and management of PhoneAccount instances per SIM.
 * Supports API 21+ with proper fallback for single-SIM devices.
 * Persists all PhoneAccountHandle entries for reliable retrieval.
 */
@Singleton
class PhoneAccountManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val telecomManager: TelecomManager,
    private val simManager: com.mangrule.dailathon.multisim.SimManager,
) {

    private val prefs: SharedPreferences = context.getSharedPreferences(
        "com.mangrule.dailathon.phone_accounts",
        Context.MODE_PRIVATE
    )

    /**
     * Ensures all active SIM subscriptions are registered as PhoneAccounts.
     * Should be called from Application.onCreate() and MainActivity.onResume().
     */
    fun ensureAllRegistered() {
        val simSlots = simManager.getActiveSimSlots()
        Timber.d("PhoneAccountManager.ensureAllRegistered: found ${simSlots.size} SIM slot(s)")

        for (sim in simSlots) {
            registerPhoneAccount(sim.subscriptionId, sim.displayName)
        }
    }

    /**
     * Register a single PhoneAccount for the given subscription ID.
     * Safely handles API level differences.
     */
    private fun registerPhoneAccount(subscriptionId: Int, displayName: String) {
        if (!context.packageManager.hasSystemFeature("android.hardware.telephony")) {
            Timber.w("PhoneAccountManager: device not telephony capable, skipping registration")
            return
        }

        try {
            val phoneAccountHandle = buildPhoneAccountHandle(subscriptionId)
            val phoneAccount = buildPhoneAccount(subscriptionId, displayName, phoneAccountHandle)

            telecomManager.registerPhoneAccount(phoneAccount)
            persistPhoneAccountHandle(subscriptionId, phoneAccountHandle)

            Timber.d("PhoneAccountManager: registered PhoneAccount for sub=$subscriptionId, display=$displayName")
        } catch (e: Exception) {
            Timber.e(e, "Error registering PhoneAccount for sub=$subscriptionId")
        }
    }

    /**
     * Build a PhoneAccountHandle for the given subscription ID.
     */
    private fun buildPhoneAccountHandle(subscriptionId: Int): PhoneAccountHandle {
        val componentName = android.content.ComponentName(
            context,
            DialerConnectionService::class.java
        )
        return PhoneAccountHandle(componentName, "SIM_$subscriptionId")
    }

    /**
     * Build a PhoneAccount with capabilities for PSTN calling.
     */
    private fun buildPhoneAccount(
        subscriptionId: Int,
        displayName: String,
        handle: PhoneAccountHandle,
    ): android.telecom.PhoneAccount {
        return android.telecom.PhoneAccount.builder(handle, displayName)
            .setCapabilities(
                android.telecom.PhoneAccount.CAPABILITY_CALL_PROVIDER or
                android.telecom.PhoneAccount.CAPABILITY_CONNECTION_MANAGER
            )
            .setHighlightColor(android.graphics.Color.parseColor("#2196F3"))
            .setShortDescription("$displayName (Sub: $subscriptionId)")
            .build()
    }

    /**
     * Persist the PhoneAccountHandle to SharedPreferences for reliable recovery.
     */
    private fun persistPhoneAccountHandle(subscriptionId: Int, handle: PhoneAccountHandle) {
        prefs.edit().putString(
            "phone_account_handle_$subscriptionId",
            handle.id
        ).apply()
    }

    /**
     * Retrieve the PhoneAccountHandle for a given subscription ID.
     */
    fun getPhoneAccountHandle(subscriptionId: Int): PhoneAccountHandle? {
        val handleId = prefs.getString("phone_account_handle_$subscriptionId", null)
            ?: return null

        val componentName = android.content.ComponentName(
            context,
            DialerConnectionService::class.java
        )
        return PhoneAccountHandle(componentName, handleId)
    }

    /**
     * Check if a PhoneAccount is registered for the given subscription ID.
     */
    fun isRegistered(subscriptionId: Int): Boolean {
        return getPhoneAccountHandle(subscriptionId)?.let { handle ->
            try {
                telecomManager.getPhoneAccount(handle) != null
            } catch (e: Exception) {
                Timber.e(e, "Error checking registration for sub=$subscriptionId")
                false
            }
        } ?: false
    }

    /**
     * Get the default outgoing PhoneAccountHandle.
     * Respects user's system default if set, otherwise returns the first active SIM.
     */
    fun getDefaultOutgoingAccount(): PhoneAccountHandle? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                val defaultSubId = SubscriptionManager.getDefaultVoiceSubscriptionId()
                if (defaultSubId != SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
                    getPhoneAccountHandle(defaultSubId)
                } else {
                    // Fall back to first active SIM
                    val firstActive = simManager.getActiveSimSlots().firstOrNull()
                    firstActive?.let { getPhoneAccountHandle(it.subscriptionId) }
                }
            } else {
                // API 21: single SIM only
                getPhoneAccountHandle(0)
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting default outgoing account")
            null
        }
    }

    /**
     * Get all registered PhoneAccountHandles for this app.
     */
    fun getAllRegisteredAccounts(): List<PhoneAccountHandle> {
        val simSlots = simManager.getActiveSimSlots()
        return simSlots.mapNotNull { sim ->
            getPhoneAccountHandle(sim.subscriptionId)
        }
    }
}
