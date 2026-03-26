package com.mangrule.dailathon.domain.managers

import android.content.Context
import android.os.Build
import android.os.Vibrator
import android.os.VibratorManager
import dagger.hilt.android.qualifiers.ApplicationContext
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages haptic feedback for dialpad keys and other UI interactions.
 */
@Singleton
class HapticManager @Inject constructor(
    @ApplicationContext private val context: Context
) {

    fun dialpadKeyPress() {
        val vibrator = getVibrator()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                vibrator.vibrate(
                    android.os.VibrationEffect.createPredefined(
                        android.os.VibrationEffect.EFFECT_TICK
                    )
                )
            } catch (e: Exception) {
                Timber.w("Haptic dialpad press failed: ${e.message}")
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                @Suppress("DEPRECATION")
                vibrator.vibrate(
                    android.os.VibrationEffect.createOneShot(
                        30,
                        android.os.VibrationEffect.DEFAULT_AMPLITUDE
                    )
                )
            } catch (e: Exception) {
                Timber.w("Haptic dialpad press failed: ${e.message}")
            }
        } else {
            try {
                @Suppress("DEPRECATION")
                vibrator.vibrate(30)
            } catch (e: Exception) {
                Timber.w("Haptic dialpad press failed: ${e.message}")
            }
        }
    }

    private fun getVibrator(): Vibrator =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager)
                .defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
}
