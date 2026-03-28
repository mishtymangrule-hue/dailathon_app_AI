package com.mangrule.dailathon.vibration

import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import timber.log.Timber

/**
 * CallVibrationManager handles vibration patterns during calls.
 * Respects device ringer mode and DND settings.
 */
@Singleton
class CallVibrationManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val audioManager: AudioManager,
) {

    private val vibrator: Vibrator = getVibrator()

    // Pattern: 0ms delay, 500ms ON, 1000ms OFF (repeating)
    private val ringingPattern = longArrayOf(0, 500, 1000)

    // Single pulse for dialing
    private val dialingPattern = longArrayOf(0, 100)

    // Confirmation: short double-buzz
    private val confirmationPattern = longArrayOf(0, 80, 100, 80)

    // Error: triple quick buzz
    private val errorPattern = longArrayOf(0, 50, 80, 50, 80, 50)

    // Call connected: single medium buzz
    private val connectedPattern = longArrayOf(0, 200)

    // Call ended: descending buzz
    private val endedPattern = longArrayOf(0, 150, 50, 100)

    private fun getVibrator(): Vibrator {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vm?.defaultVibrator ?: getFallbackVibrator()
        } else {
            getFallbackVibrator()
        }
    }

    @Suppress("DEPRECATION")
    private fun getFallbackVibrator(): Vibrator {
        return context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    }

    fun startRingingPattern() {
        if (!shouldVibrate()) {
            Timber.d("CallVibrationManager: skipping ringing vibration (silent mode)")
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                vibrator.vibrate(
                    VibrationEffect.createWaveform(ringingPattern, 0)
                )
                Timber.d("CallVibrationManager: started ringing pattern")
            } catch (e: Exception) {
                Timber.e(e, "Error starting ringing vibration")
            }
        } else {
            @Suppress("DEPRECATION")
            try {
                vibrator.vibrate(ringingPattern, 0)
                Timber.d("CallVibrationManager: started ringing pattern (pre-O)")
            } catch (e: Exception) {
                Timber.e(e, "Error starting ringing vibration")
            }
        }
    }

    fun startDialingPattern() {
        if (!shouldVibrate()) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                vibrator.vibrate(
                    VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE)
                )
                Timber.d("CallVibrationManager: started dialing pattern")
            } catch (e: Exception) {
                Timber.e(e, "Error starting dialing vibration")
            }
        } else {
            @Suppress("DEPRECATION")
            try {
                vibrator.vibrate(100)
                Timber.d("CallVibrationManager: started dialing pattern (pre-O)")
            } catch (e: Exception) {
                Timber.e(e, "Error starting dialing vibration")
            }
        }
    }

    fun stopVibration() {
        try {
            vibrator.cancel()
            Timber.d("CallVibrationManager: stopped vibration")
        } catch (e: Exception) {
            Timber.e(e, "Error stopping vibration")
        }
    }

    private fun shouldVibrate(): Boolean {
        return when (audioManager.ringerMode) {
            AudioManager.RINGER_MODE_VIBRATE -> true
            AudioManager.RINGER_MODE_NORMAL -> true  // Vibrate alongside ringtone
            AudioManager.RINGER_MODE_SILENT -> false
            else -> false
        }
    }

    fun vibrateConfirmation() = vibrateOnce(confirmationPattern)
    fun vibrateError() = vibrateOnce(errorPattern)
    fun vibrateConnected() = vibrateOnce(connectedPattern)
    fun vibrateEnded() = vibrateOnce(endedPattern)

    private fun vibrateOnce(pattern: LongArray) {
        if (!shouldVibrate()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
            } catch (e: Exception) {
                Timber.e(e, "Error with vibration pattern")
            }
        } else {
            @Suppress("DEPRECATION")
            try {
                vibrator.vibrate(pattern, -1)
            } catch (e: Exception) {
                Timber.e(e, "Error with vibration pattern")
            }
        }
    }
}
