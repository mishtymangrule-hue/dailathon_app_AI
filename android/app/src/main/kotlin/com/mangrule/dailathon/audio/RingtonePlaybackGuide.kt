package com.mangrule.dailathon.audio

/**
 * RINGTONE PLAYBACK GUIDE
 * 
 * Android's telecom framework handles ringtone playback automatically.
 * The dialer app should NOT manually play ringtone sounds.
 * 
 * KEY PRINCIPLES:
 * ===============
 * 
 * 1. AUTOMATIC PLAYBACK
 *    - When a call is ringing, the system (Telecom) plays the ringtone automatically.
 *    - The ringtone is controlled by the system ringtone setting, not the app.
 *    - The app receives STATE_RINGING callbacks but should not handle audio playback.
 * 
 * 2. NEVER SUPPRESS STREAM_RING
 *    ❌ DO NOT CALL:
 *    - audioManager.setStreamMute(AudioManager.STREAM_RING, true)
 *    - audioManager.setStreamVolume(AudioManager.STREAM_RING, 0, ...)
 *    - These will prevent system ringtone from playing!
 *    - Only suppress STREAM_RING if explicitly allowing it via user setting.
 * 
 * 3. AUDIO FOCUS HANDLING
 *    - Request audio focus with AudioManager.STREAM_VOICE_CALL during active calls.
 *    - This is done in AudioRouter.startCallAudio()
 *    - During ringing (STATE_RINGING), DO NOT request focus on VOICE_CALL yet.
 *    - Let the system play STREAM_RING undisturbed.
 * 
 * 4. MUTE/SPEAKER CONTROL
 *    - These controls are for the call AUDIO (STREAM_VOICE_CALL), not the ringtone.
 *    - Muting affects the microphone and call audio stream.
 *    - Speaker affects call audio routing, not ringtone.
 *    - Ringtone routing is controlled by device proximity, user DND, silent mode.
 * 
 * 5. VIBRATION
 *    - Vibration is separate from ringtone playback.
 *    - Handled by CallVibrationManager based on ringer mode.
 *    - Works alongside ringtone, not instead of it.
 * 
 * CALL STATE AUDIO HANDLING:
 * ==========================
 * 
 * STATE_RINGING:
 *   - System plays ringtone and vibration (if enabled).
 *   - App shows incoming call UI.
 *   - App requests vibration via CallVibrationManager (optional, system already vibrates).
 *   - DO NOT request audio focus yet.
 *   - DO NOT mute or suppress STREAM_RING.
 * 
 * STATE_ACTIVE:
 *   - Ringtone was stopped by user answering.
 *   - Request audio focus for STREAM_VOICE_CALL in AudioRouter.startCallAudio().
 *   - Switch audio to earpiece/speaker/bluetooth based on AudioRouter.selectBestAvailableDevice().
 *   - Now start enforcing mute, speaker, and Bluetooth audio controls.
 * 
 * STATE_DISCONNECTED:
 *   - Call ended, ringtone (if not answered) or call audio stopped.
 *   - Release audio focus in AudioRouter.endCallAudio().
 *   - Vibration stopped in CallVibrationManager.stopVibration().
 * 
 * CUSTOM RINGTONE PICKER (Optional Future Feature):
 * ===================================================
 * If you want to add a custom ringtone selector in Settings:
 * 
 * val ringtonePickerIntent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
 *     putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_RINGTONE)
 *     putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Select Ringtone")
 * }
 * startActivityForResult(ringtonePickerIntent, REQUEST_CODE_RINGTONE)
 * 
 * Then in onActivityResult:
 * val uri: Uri? = intent.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
 * RingtoneManager.setActualDefaultRingtoneUri(context, RingtoneManager.TYPE_RINGTONE, uri)
 * 
 * DEVICE RESTRICTIONS:
 * ====================
 * Some OEM devices (Xiaomi, Samsung, Huawei) restrict ringtone playback if:
 * - The app is not set as the default dialer (or runtime permission needed).
 * - The device is in power-saving mode.
 * - App is in battery optimization list.
 * 
 * Solution: Direct user to battery settings via OemCompatManager.getBatterySettingsIntent()
 * to whitelist the app for normal operation.
 * 
 * TESTING RINGTONE:
 * =================
 * 1. Ensure MODIFY_AUDIO_SETTINGS and READ_PHONE_STATE permissions granted.
 * 2. Ensure app is set as default dialer (checkDefaultDialer() / requestDefaultDialer()).
 * 3. Make an incoming call → system should play ringtone immediately.
 * 4. Verify ringer mode and DND settings are respected (system does this).
 * 5. Press answer → ringtone stops, call audio begins.
 */

// This file serves as documentation and reference.
// No executable code here; it's for developer guidance.
