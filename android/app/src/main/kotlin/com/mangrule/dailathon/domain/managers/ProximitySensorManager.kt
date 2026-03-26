package com.mangrule.dailathon.domain.managers

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.PowerManager
import dagger.hilt.android.qualifiers.ApplicationContext
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages proximity sensor for turning screen off when phone is held to ear.
 * PROXIMITY_SCREEN_OFF_WAKE_LOCK automatically handles screen on/off based on
 * the sensor value — no manual screen control needed.
 */
@Singleton
class ProximitySensorManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val sensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val proximitySensor: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)
    private val powerManager =
        context.getSystemService(Context.POWER_SERVICE) as PowerManager

    private val proximityWakeLock: PowerManager.WakeLock? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            powerManager.newWakeLock(
                PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
                "DialerApp:ProximityLock"
            ).apply { setReferenceCounted(false) }
        } else null
    }

    private val listener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            val isNear = event.values[0] < (proximitySensor?.maximumRange ?: 5f)
            Timber.v("Proximity sensor: near=$isNear")
            // TODO: Post proximity event for Flutter UI if needed
        }

        override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
    }

    fun start() {
        if (proximitySensor == null) {
            Timber.w("Device has no proximity sensor")
            return
        }
        proximityWakeLock?.takeIf { !it.isHeld }?.acquire()
        sensorManager.registerListener(listener, proximitySensor,
            SensorManager.SENSOR_DELAY_NORMAL)
        Timber.v("Proximity sensor started")
    }

    fun stop() {
        sensorManager.unregisterListener(listener)
        proximityWakeLock?.takeIf { it.isHeld }?.release()
        Timber.v("Proximity sensor stopped")
    }
}
