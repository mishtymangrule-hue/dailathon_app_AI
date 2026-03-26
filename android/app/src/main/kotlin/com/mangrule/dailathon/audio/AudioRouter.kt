package com.mangrule.dailathon.audio

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.AudioManager.OnAudioFocusChangeListener
import android.os.Build
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import timber.log.Timber

/**
 * AudioRouter manages call audio routing across devices:
 * - Earpiece (default)
 * - Speakerphone
 * - Wired headset
 * - Bluetooth SCO (priority: highest quality)
 * 
 * Device selection priority: Bluetooth > Wired Headset > Earpiece > Speaker
 * 
 * API 28+ uses AudioManager.setCommunicationDevice() for precise routing.
 * API 21-27 falls back to deprecated but functional methods.
 */
@Singleton
class AudioRouter @Inject constructor(
    @ApplicationContext private val context: Context,
    private val audioManager: AudioManager,
) {
  private var audioFocusListener: OnAudioFocusChangeListener? = null
  private var currentAudioDevice: AudioDeviceInfo? = null
  private var isMuted = false
  private var isSpeakerEnabled = false
  private var isBluetoothScoOn = false

  /**
   * Initialize call audio mode and request audio focus.
   * Called when call transitions to ACTIVE state.
   */
  fun startCallAudio() {
    try {
      // Set communication mode for call audio routing
      audioManager.mode = AudioManager.MODE_IN_COMMUNICATION

      // Request audio focus with AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE
      audioFocusListener = OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
          AudioManager.AUDIOFOCUS_GAIN -> {
            Timber.v("AudioFocus: gained focus")
            resumeAudio()
          }
          AudioManager.AUDIOFOCUS_LOSS -> {
            Timber.v("AudioFocus: lost focus")
            pauseAudio()
          }
          AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
            Timber.v("AudioFocus: transient loss")
            pauseAudio()
          }
          AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
            Timber.v("AudioFocus: can duck")
            // Could reduce volume instead of pausing, but for calls we pause
            pauseAudio()
          }
        }
      }

      val result = audioManager.requestAudioFocus(
        audioFocusListener,
        AudioManager.STREAM_VOICE_CALL,
        AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE,
      )

      if (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
        Timber.v("AudioRouter: audio focus granted")
      } else {
        Timber.w("AudioRouter: audio focus request failed")
      }

      // Select best available device based on priority
      selectBestAvailableDevice()

      Timber.v("AudioRouter: started call audio mode")
    } catch (e: Exception) {
      Timber.e(e, "Error starting call audio")
    }
  }

  /**
   * Clean up call audio mode and release audio focus.
   * Called when call transitions from ACTIVE.
   */
  fun endCallAudio() {
    try {
      // Clear communication device (API 28+)
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        clearCommunicationDevice()
      } else {
        // Fallback: disable all routing options
        @Suppress("DEPRECATION")
        audioManager.isSpeakerphoneOn = false
        audioManager.isBluetoothScoOn = false
      }

      // Release audio focus
      audioFocusListener?.let {
        audioManager.abandonAudioFocus(it)
        Timber.v("AudioRouter: audio focus abandoned")
      }

      // Reset to normal mode
      audioManager.mode = AudioManager.MODE_NORMAL
      currentAudioDevice = null
      isMuted = false
      isSpeakerEnabled = false
      isBluetoothScoOn = false

      Timber.v("AudioRouter: ended call audio mode")
    } catch (e: Exception) {
      Timber.e(e, "Error ending call audio")
    }
  }

  /**
   * Select best available audio device based on priority.
   * Priority: Bluetooth > Wired Headset > Earpiece > Speaker
   */
  private fun selectBestAvailableDevice() {
    try {
      val availableDevices = getAvailableAudioDevices()

      val selectedDevice = availableDevices.firstOrNull { device ->
        // Bluetooth has highest priority
        when (device.type) {
          AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
          AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> true
          else -> false
        }
      } ?: availableDevices.firstOrNull { device ->
        // Wired headset is second priority
        when (device.type) {
          AudioDeviceInfo.TYPE_WIRED_HEADSET,
          AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> true
          else -> false
        }
      } ?: availableDevices.firstOrNull { device ->
        // Earpiece (BUILTIN_RECEIVER) is third
        device.type == AudioDeviceInfo.TYPE_BUILTIN_RECEIVER
      } ?: availableDevices.firstOrNull { device ->
        // Speaker is last resort
        device.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
      }

      if (selectedDevice != null) {
        setAudioDevice(selectedDevice)
      } else {
        Timber.w("AudioRouter: no audio device found, using default")
      }
    } catch (e: Exception) {
      Timber.e(e, "Error selecting best audio device")
    }
  }

  /**
   * Get list of available audio devices for call routing.
   * Filters for devices suitable for communication.
   */
  private fun getAvailableAudioDevices(): List<AudioDeviceInfo> {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      audioManager.devices
        .filter { device ->
          device.isSink && (
            device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
              device.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
              device.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
              device.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
              device.type == AudioDeviceInfo.TYPE_BUILTIN_RECEIVER ||
              device.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER ||
              device.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER_SAFE
            )
        }
        .sortedBy { device ->
          // Sort by priority
          when (device.type) {
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> 0
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> 1
            AudioDeviceInfo.TYPE_WIRED_HEADSET -> 2
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> 3
            AudioDeviceInfo.TYPE_BUILTIN_RECEIVER -> 4
            AudioDeviceInfo.TYPE_BUILTIN_SPEAKER_SAFE -> 5
            AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> 6
            else -> 99
          }
        }
    } else {
      emptyList()
    }
  }

  /**
   * Set communication device (API 28+) or use deprecated fallback.
   */
  private fun setAudioDevice(device: AudioDeviceInfo) {
    try {
      currentAudioDevice = device

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        audioManager.communicationDevice = device
        Timber.v("AudioRouter: set communication device: ${device.productName} (${getDeviceTypeName(device.type)})")
      } else {
        // Fallback for API 21-27
        @Suppress("DEPRECATION")
        when (device.type) {
          AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
          AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> {
            audioManager.isSpeakerphoneOn = false
            audioManager.isBluetoothScoOn = true
            isBluetoothScoOn = true
            Timber.v("AudioRouter: routed to Bluetooth (deprecated)")
          }
          AudioDeviceInfo.TYPE_WIRED_HEADSET,
          AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> {
            audioManager.isSpeakerphoneOn = false
            audioManager.isBluetoothScoOn = false
            Timber.v("AudioRouter: routed to wired headset (deprecated)")
          }
          AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> {
            audioManager.isSpeakerphoneOn = true
            audioManager.isBluetoothScoOn = false
            isSpeakerEnabled = true
            Timber.v("AudioRouter: routed to speaker (deprecated)")
          }
          else -> {
            audioManager.isSpeakerphoneOn = false
            audioManager.isBluetoothScoOn = false
            Timber.v("AudioRouter: routed to earpiece (deprecated)")
          }
        }
      }
    } catch (e: Exception) {
      Timber.e(e, "Error setting audio device")
    }
  }

  /**
   * Clear communication device (API 28+).
   */
  private fun clearCommunicationDevice() {
    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        audioManager.clearCommunicationDevice()
        Timber.v("AudioRouter: cleared communication device")
      }
      currentAudioDevice = null
    } catch (e: Exception) {
      Timber.e(e, "Error clearing communication device")
    }
  }

  /**
   * Set mute state.
   */
  fun setMuted(muted: Boolean) {
    try {
      isMuted = muted
      audioManager.setMicrophoneMute(muted)
      Timber.v("AudioRouter: mic mute = $muted")
    } catch (e: Exception) {
      Timber.e(e, "Error setting mute")
    }
  }

  /**
   * Get current mute state.
   */
  fun isMuted(): Boolean {
    return try {
      audioManager.isMicrophoneMute
    } catch (e: Exception) {
      Timber.e(e, "Error getting mute state")
      isMuted
    }
  }

  /**
   * Enable/disable speaker phone (deprecated but functional for API 21+).
   */
  fun setSpeakerPhoneOn(enabled: Boolean) {
    try {
      isSpeakerEnabled = enabled
      @Suppress("DEPRECATION")
      audioManager.isSpeakerphoneOn = enabled
      Timber.v("AudioRouter: speaker phone = $enabled")
    } catch (e: Exception) {
      Timber.e(e, "Error setting speaker phone")
    }
  }

  /**
   * Get current speaker phone state.
   */
  fun isSpeakerPhoneOn(): Boolean {
    return try {
      @Suppress("DEPRECATION")
      audioManager.isSpeakerphoneOn
    } catch (e: Exception) {
      Timber.e(e, "Error getting speaker phone state")
      isSpeakerEnabled
    }
  }

  /**
   * Enable/disable Bluetooth SCO audio.
   * Must be called after Bluetooth device is connected.
   */
  fun setBluetoothScoOn(enabled: Boolean) {
    try {
      if (enabled) {
        if (!audioManager.isBluetoothScoOn) {
          audioManager.startBluetoothSco()
          isBluetoothScoOn = true
          Timber.v("AudioRouter: started Bluetooth SCO")
        }
      } else {
        if (audioManager.isBluetoothScoOn) {
          audioManager.stopBluetoothSco()
          isBluetoothScoOn = false
          Timber.v("AudioRouter: stopped Bluetooth SCO")
        }
      }
    } catch (e: Exception) {
      Timber.e(e, "Error setting Bluetooth SCO")
    }
  }

  /**
   * Get current Bluetooth SCO state.
   */
  fun isBluetoothScoOn(): Boolean {
    return try {
      audioManager.isBluetoothScoOn
    } catch (e: Exception) {
      Timber.e(e, "Error getting Bluetooth SCO state")
      isBluetoothScoOn
    }
  }

  /**
   * Pause audio (for focus loss).
   */
  private fun pauseAudio() {
    try {
      Timber.v("AudioRouter: pausing audio")
      // Could implement volume reduction or mute here
    } catch (e: Exception) {
      Timber.e(e, "Error pausing audio")
    }
  }

  /**
   * Resume audio (for focus gain).
   */
  private fun resumeAudio() {
    try {
      Timber.v("AudioRouter: resuming audio")
      // Restore volume or unmute if needed
    } catch (e: Exception) {
      Timber.e(e, "Error resuming audio")
    }
  }

  /**
   * Get human-readable device type name.
   */
  private fun getDeviceTypeName(type: Int): String {
    return when (type) {
      AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> "Bluetooth SCO"
      AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> "Bluetooth A2DP"
      AudioDeviceInfo.TYPE_WIRED_HEADSET -> "Wired Headset"
      AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "Wired Headphones"
      AudioDeviceInfo.TYPE_BUILTIN_RECEIVER -> "Earpiece"
      AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "Speaker"
      AudioDeviceInfo.TYPE_BUILTIN_SPEAKER_SAFE -> "Speaker (Safe)"
      else -> "Unknown ($type)"
    }
  }

  /**
   * Get current audio device info.
   */
  fun getCurrentAudioDevice(): String {
    return currentAudioDevice?.let {
      "${it.productName} (${getDeviceTypeName(it.type)})"
    } ?: "None"
  }

  /**
   * Get list of available audio routes as strings for Flutter.
   * Returns: ["earpiece", "speaker", "wired_headset", "bluetooth"]
   * Priority order (first is highest priority).
   */
  fun getAvailableRoutes(): List<String> {
    return try {
      val devices = getAvailableAudioDevices()
      val routes = mutableListOf<String>()

      for (device in devices) {
        when (device.type) {
          AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
          AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> {
            if (!routes.contains("bluetooth")) routes.add("bluetooth")
          }
          AudioDeviceInfo.TYPE_WIRED_HEADSET,
          AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> {
            if (!routes.contains("wired_headset")) routes.add("wired_headset")
          }
          AudioDeviceInfo.TYPE_BUILTIN_RECEIVER -> {
            if (!routes.contains("earpiece")) routes.add("earpiece")
          }
          AudioDeviceInfo.TYPE_BUILTIN_SPEAKER,
          AudioDeviceInfo.TYPE_BUILTIN_SPEAKER_SAFE -> {
            if (!routes.contains("speaker")) routes.add("speaker")
          }
        }
      }

      Timber.v("Available audio routes: $routes")
      routes
    } catch (e: Exception) {
      Timber.e(e, "Error getting available routes")
      emptyList()
    }
  }
}
