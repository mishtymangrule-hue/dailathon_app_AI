package com.mangrule.dailathon.domain.managers

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import dagger.hilt.android.qualifiers.ApplicationContext
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages haptic feedback for dialpad keys, call events, and UI interactions.
 * Provides multiple haptic patterns for different scenarios.
 */
@Singleton
class HapticManager @Inject constructor(
    @ApplicationContext private val context: Context
) {

    fun dialpadKeyPress() = vibrateTick()

    fun callConnected() = vibrateClick()

    fun callDisconnected() = vibrateDoubleClick()

    fun callFailed() = vibrateHeavyClick()

    fun holdToggled() = vibrateTick()

    fun muteToggled() = vibrateTick()

    fun confirmAction() = vibrateClick()

    fun errorFeedback() = vibrateHeavyClick()

    fun warningFeedback() = vibrateDoubleClick()

    fun swipeAction() = vibrateTick()

    fun longPressActivated() = vibrateClick()

    fun buttonPress() = vibrateTick()

    fun navigationTap() = vibrateTick()

    fun selectionChanged() = vibrateTick()

    fun textInput() = vibrateTick()

    fun toggleSwitch() = vibrateClick()

    fun pullToRefresh() = vibrateClick()

    fun deleteAction() = vibrateDoubleClick()

    fun successNotification() = vibrateClick()

    fun incomingCallPulse() = vibratePattern(longArrayOf(0, 150, 100, 150), -1)

    fun callWaitingAlert() = vibratePattern(longArrayOf(0, 100, 200, 100), -1)

    private fun vibrateTick() {
        val vibrator = getVibrator()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                vibrator.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK))
            } catch (e: Exception) {
                Timber.w("Haptic tick failed: ${e.message}")
                vibrateFallback(vibrator, 20)
            }
        } else {
            vibrateFallback(vibrator, 20)
        }
    }

    private fun vibrateClick() {
        val vibrator = getVibrator()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                vibrator.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK))
            } catch (e: Exception) {
                Timber.w("Haptic click failed: ${e.message}")
                vibrateFallback(vibrator, 40)
            }
        } else {
            vibrateFallback(vibrator, 40)
        }
    }

    private fun vibrateDoubleClick() {
        val vibrator = getVibrator()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                vibrator.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_DOUBLE_CLICK))
            } catch (e: Exception) {
                Timber.w("Haptic double click failed: ${e.message}")
                vibratePattern(longArrayOf(0, 30, 60, 30), -1)
            }
        } else {
            vibratePattern(longArrayOf(0, 30, 60, 30), -1)
        }
    }

    private fun vibrateHeavyClick() {
        val vibrator = getVibrator()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                vibrator.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_HEAVY_CLICK))
            } catch (e: Exception) {
                Timber.w("Haptic heavy click failed: ${e.message}")
                vibrateFallback(vibrator, 60)
            }
        } else {
            vibrateFallback(vibrator, 60)
        }
    }

    private fun vibratePattern(pattern: LongArray, repeat: Int) {
        val vibrator = getVibrator()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, repeat))
            } catch (e: Exception) {
                Timber.w("Haptic pattern failed: ${e.message}")
            }
        } else {
            try {
                @Suppress("DEPRECATION")
                vibrator.vibrate(pattern, repeat)
            } catch (e: Exception) {
                Timber.w("Haptic pattern failed: ${e.message}")
            }
        }
    }

    private fun vibrateFallback(vibrator: Vibrator, ms: Long) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                vibrator.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE))
            } catch (e: Exception) {
                Timber.w("Haptic fallback failed: ${e.message}")
            }
        } else {
            try {
                @Suppress("DEPRECATION")
                vibrator.vibrate(ms)
            } catch (e: Exception) {
                Timber.w("Haptic fallback failed: ${e.message}")
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
