package com.mangrule.dailathon.domain.managers

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.telecom.TelecomManager
import android.telephony.PhoneNumberUtils
import timber.log.Timber

object EmergencyCallManager {

    private val HARDCODED_EMERGENCY_NUMBERS = setOf(
        "112",  // International (EU, most of world)
        "911",  // North America
        "999",  // UK, Ireland, Hong Kong
        "000",  // Australia
        "110",  // Germany / Japan police
        "119",  // Japan ambulance
        "100",  // India police
        "101",  // India fire / Russia fire
        "102",  // India ambulance
        "103",  // Russia police
        "08",   // France (legacy)
        "15",   // France SAMU
        "17",   // France police
        "18",   // France fire
        "115",  // Vietnam
        "060",  // UAE police
        "998",  // Uzbekistan
    )

    fun isEmergencyNumber(number: String): Boolean {
        val normalised = number.trimStart('+').replace(Regex("[^0-9]"), "")
        @Suppress("DEPRECATION")
        return PhoneNumberUtils.isEmergencyNumber(normalised) ||
            normalised in HARDCODED_EMERGENCY_NUMBERS
    }

    fun placeEmergencyCall(context: Context, number: String) {
        val uri = Uri.fromParts("tel", number, null)

        // Primary: TelecomManager
        val telecomManager =
            context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        try {
            telecomManager.placeCall(uri, android.os.Bundle())
            Timber.v("Emergency call placed via TelecomManager: $number")
            return
        } catch (e: SecurityException) {
            Timber.w("TelecomManager failed (CALL_PHONE not granted), trying fallbacks")
        }

        // Fallback: ACTION_CALL
        try {
            context.startActivity(
                Intent(Intent.ACTION_CALL, uri)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            Timber.v("Emergency call placed via ACTION_CALL: $number")
            return
        } catch (_: ActivityNotFoundException) {}

        // Last resort: ACTION_DIAL (user taps Call manually)
        try {
            context.startActivity(
                Intent(Intent.ACTION_DIAL, uri)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            Timber.v("Emergency dialer opened via ACTION_DIAL: $number")
        } catch (_: ActivityNotFoundException) {
            Timber.e("Failed to route emergency call: $number")
        }
    }
}
