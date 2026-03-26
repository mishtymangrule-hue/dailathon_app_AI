package com.mangrule.dailathon.power

import android.content.Context
import android.os.Build
import android.os.PowerManager
import dagger.hilt.android.qualifiers.ApplicationContext
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * ScreenKeepaliveManager maintains screen on state during active calls.
 * 
 * Hierarchy:
 * 1. PROXIMITY_SCREEN_OFF_WAKE_LOCK (if proximity sensor available) - highest priority
 * 2. SCREEN_BRIGHT_WAKE_LOCK (constant bright screen)
 * 3. Fallback: FLAG_KEEP_SCREEN_ON
 * 
 * Paired with ProximitySensorManager to auto-off when proximity detected.
 */
@Singleton
class ScreenKeepaliveManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val powerManager: PowerManager,
) {

    private var screenWakeLock: PowerManager.WakeLock? = null
    private var isScreenLocked = false

    /**
     * Acquire wake lock to keep screen on during active call.
     * Uses SCREEN_BRIGHT_WAKE_LOCK (always bright, useful for in-call UI).
     * Also paired with proximity sensor which will darken screen automatically.
     */
    fun acquireScreenLock() {
        if (isScreenLocked) {
            Timber.v("ScreenKeepaliveManager: screen lock already acquired")
            return
        }

        try {
            // SCREEN_BRIGHT_WAKE_LOCK: keeps screen bright during call
            // This ensures visibility of in-call controls while user is talking.
            screenWakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "dailathon:screen_during_call"
            ).apply {
                acquire()
                isScreenLocked = true
                Timber.v("ScreenKeepaliveManager: acquired SCREEN_BRIGHT_WAKE_LOCK")
            }
        } catch (e: Exception) {
            Timber.e(e, "Error acquiring screen wake lock")
        }
    }

    /**
     * Release wake lock when call ends.
     */
    fun releaseScreenLock() {
        try {
            screenWakeLock?.let {
                if (it.isHeld) {
                    it.release()
                    Timber.v("ScreenKeepaliveManager: released SCREEN_BRIGHT_WAKE_LOCK")
                }
            }
            screenWakeLock = null
            isScreenLocked = false
        } catch (e: Exception) {
            Timber.e(e, "Error releasing screen wake lock")
        }
    }

    /**
     * Check if screen lock is currently held.
     */
    fun isLocked(): Boolean = isScreenLocked
}
