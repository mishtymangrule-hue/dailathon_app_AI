package com.mangrule.dailathon.presentation.channels

import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.BlockedNumberContract
import android.telecom.TelecomManager
import dagger.hilt.android.qualifiers.ApplicationContext
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import timber.log.Timber
import java.lang.ref.WeakReference
import com.mangrule.dailathon.telecom.PhoneAccountManager
import com.mangrule.dailathon.audio.AudioRouter
import com.mangrule.dailathon.vibration.CallVibrationManager
import com.mangrule.dailathon.multisim.SimManager
import com.mangrule.dailathon.forwarding.CallForwardingManager
import com.mangrule.dailathon.domain.managers.CallOperationsManager
import com.mangrule.dailathon.domain.managers.UssdManager
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Handles all MethodChannel calls from Flutter.
 * All calls are dispatched on the main thread to ensure safety.
 * Delegates to underlying managers for domain logic.
 */
@Singleton
class CallMethodChannelHandler @Inject constructor(
  @ApplicationContext private val context: Context,
  private val phoneAccountManager: PhoneAccountManager,
  private val audioRouter: AudioRouter,
  private val callVibrationManager: CallVibrationManager,
  private val simManager: SimManager,
  private val callForwardingManager: CallForwardingManager,
  private val callOperationsManager: CallOperationsManager,
  private val ussdManager: UssdManager,
) {
  companion object {
    private const val CHANNEL_NAME = "com.mangrule.dailathon/call_commands"
  }

  private val mainHandler = Handler(Looper.getMainLooper())
  private var methodChannel: MethodChannel? = null
  private var activityRef: WeakReference<Activity>? = null

  /** Called from MainActivity.onResume / onPause to provide Activity context for startActivity. */
  fun setActivity(activity: Activity?) {
    activityRef = if (activity != null) WeakReference(activity) else null
  }

  /**
   * Initialize MethodChannel with FlutterEngine.
   * Called from MainActivity.configureFlutterEngine()
   */
  fun initialize(flutterEngine: FlutterEngine) {
    methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
    methodChannel?.setMethodCallHandler { call, result ->
      // All calls dispatched on main thread
      mainHandler.post {
        try {
          when (call.method) {
            "dial" -> handleDial(call, result)
            "answer" -> handleAnswer(call, result)
            "hangUp" -> handleHangUp(call, result)
            "hold" -> handleHold(call, result)
            "unhold" -> handleUnhold(call, result)
            "mute" -> handleMute(call, result)
            "setSpeaker" -> handleSetSpeaker(call, result)
            "setBluetoothAudio" -> handleSetBluetoothAudio(call, result)
            "getAvailableAudioRoutes" -> handleGetAvailableAudioRoutes(call, result)
            "sendDtmf" -> handleSendDtmf(call, result)
            "mergeActiveCalls" -> handleMergeActiveCalls(call, result)
            "swapCalls" -> handleSwapCalls(call, result)
            "setCallForwarding" -> handleSetCallForwarding(call, result)
            "enableCallForwarding" -> handleEnableCallForwarding(call, result)
            "disableCallForwarding" -> handleDisableCallForwarding(call, result)
            "checkDefaultDialer" -> handleCheckDefaultDialer(call, result)
            "setDefaultDialer" -> handleSetDefaultDialer(call, result)
            "getPhoneAccounts" -> handleGetPhoneAccounts(call, result)
            "selectPhoneAccount" -> handleSelectPhoneAccount(call, result)
            "acceptCall" -> handleAcceptCall(call, result)
            "rejectCall" -> handleRejectCall(call, result)
            "getBlockedNumbers" -> handleGetBlockedNumbers(call, result)
            "blockNumber" -> handleBlockNumber(call, result)
            "unblockNumber" -> handleUnblockNumber(call, result)
            "sendUssd" -> handleSendUssd(call, result)
            "getSimSlots" -> handleGetPhoneAccounts(call, result)
            else -> result.notImplemented()
          }
        } catch (e: Exception) {
          Timber.e(e, "Error handling method: ${call.method}")
          result.error("ERROR", e.message, e.stackTraceToString())
        }
      }
    }
  }

  private fun handleDial(call: MethodCall, result: MethodChannel.Result) {
    val number = call.argument<String>("number") ?: run {
      result.error("INVALID_ARGS", "Phone number is required", null)
      return
    }
    val simSlot = call.argument<Int>("simSlot") ?: 0

    try {
      val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
      val uri = Uri.fromParts("tel", number, null)

      // Use the system's call-capable phone accounts (real SIM accounts from telephony stack)
      // NOT the app's custom DialerConnectionService account.
      val extras = android.os.Bundle()
      val simHandle = getSystemSimPhoneAccountHandle(telecomManager, simSlot)
      if (simHandle != null) {
        extras.putParcelable(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, simHandle)
      }

      telecomManager.placeCall(uri, extras)
      Timber.v("Dial (placeCall): number=$number, simSlot=$simSlot, simHandle=${simHandle?.id}")
      result.success(null)
    } catch (e: SecurityException) {
      // App is not the default dialer — fall back to ACTION_CALL intent.
      // This requires CALL_PHONE permission and lets the OS route the call.
      Timber.w("placeCall denied (not default dialer), falling back to ACTION_CALL for $number")
      try {
        val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:${Uri.encode(number)}")).apply {
          addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
        result.success(null)
      } catch (e2: Exception) {
        Timber.e(e2, "ACTION_CALL fallback failed for $number")
        result.error("DIAL_ERROR", e2.message, null)
      }
    } catch (e: Exception) {
      Timber.e(e, "Failed to dial $number")
      result.error("DIAL_ERROR", e.message, null)
    }
  }

  /**
   * Returns the system telephony PhoneAccountHandle for the given UI slot index.
   * Queries callCapablePhoneAccounts (real SIM accounts) rather than the app's
   * custom DialerConnectionService handles.
   */
  @android.annotation.SuppressLint("MissingPermission")
  private fun getSystemSimPhoneAccountHandle(
    telecomManager: TelecomManager,
    simSlot: Int,
  ): android.telecom.PhoneAccountHandle? {
    return try {
      val accounts = telecomManager.callCapablePhoneAccounts
      if (accounts.isEmpty()) return null

      if (simSlot <= 0 || accounts.size == 1) {
        return accounts.firstOrNull()
      }

      // Try to match by subscription ID for dual-SIM
      val activeSims = simManager.getActiveSimSlots()
      val targetSubId = activeSims.getOrNull(simSlot)?.subscriptionId

      if (targetSubId != null && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
        val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE)
            as android.telephony.TelephonyManager
        val matched = accounts.firstOrNull { handle ->
          try {
            telephonyManager.createForPhoneAccountHandle(handle)?.subscriptionId == targetSubId
          } catch (_: Exception) { false }
        }
        if (matched != null) return matched
      }

      // Fallback: index directly into the list
      accounts.getOrNull(simSlot) ?: accounts.firstOrNull()
    } catch (e: Exception) {
      Timber.e(e, "Error resolving system SIM phone account for simSlot=$simSlot")
      null
    }
  }

  private fun handleAnswer(call: MethodCall, result: MethodChannel.Result) {
    try {
      val callId = call.argument<String>("callId")
      callOperationsManager.answerCall(callId)
      Timber.v("Answer: callId=$callId")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to answer call")
      result.error("ANSWER_ERROR", e.message, null)
    }
  }

  private fun handleHangUp(call: MethodCall, result: MethodChannel.Result) {
    try {
      val callId = call.argument<String>("callId")
      callOperationsManager.hangUpCall(callId)
      Timber.v("Hang up: callId=$callId")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to hang up")
      result.error("HANGUP_ERROR", e.message, null)
    }
  }

  private fun handleHold(call: MethodCall, result: MethodChannel.Result) {
    try {
      val callId = call.argument<String>("callId")
      callOperationsManager.holdCall(callId)
      Timber.v("Hold: callId=$callId")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to hold call")
      result.error("HOLD_ERROR", e.message, null)
    }
  }

  private fun handleUnhold(call: MethodCall, result: MethodChannel.Result) {
    try {
      val callId = call.argument<String>("callId")
      callOperationsManager.unholdCall(callId)
      Timber.v("Unhold: callId=$callId")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to unhold call")
      result.error("UNHOLD_ERROR", e.message, null)
    }
  }

  private fun handleMute(call: MethodCall, result: MethodChannel.Result) {
    val isMuted = call.argument<Boolean>("isMuted") ?: false
    try {
      audioRouter.setMuted(isMuted)
      Timber.v("Mute: $isMuted")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to set mute")
      result.error("MUTE_ERROR", e.message, null)
    }
  }

  private fun handleSetSpeaker(call: MethodCall, result: MethodChannel.Result) {
    val enabled = call.argument<Boolean>("enabled") ?: false
    try {
      audioRouter.setSpeakerPhoneOn(enabled)
      Timber.v("Speaker: $enabled")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to set speaker")
      result.error("SPEAKER_ERROR", e.message, null)
    }
  }

  private fun handleSetBluetoothAudio(call: MethodCall, result: MethodChannel.Result) {
    val enabled = call.argument<Boolean>("enabled") ?: false
    try {
      audioRouter.setBluetoothScoOn(enabled)
      Timber.v("Bluetooth audio: $enabled")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to set Bluetooth audio")
      result.error("BT_AUDIO_ERROR", e.message, null)
    }
  }

  private fun handleGetAvailableAudioRoutes(call: MethodCall, result: MethodChannel.Result) {
    try {
      val routes = audioRouter.getAvailableRoutes()
      Timber.v("Get available audio routes: $routes")
      result.success(routes)
    } catch (e: Exception) {
      Timber.e(e, "Failed to get available audio routes")
      result.error("AUDIO_ROUTES_ERROR", e.message, null)
    }
  }

  private fun handleSendDtmf(call: MethodCall, result: MethodChannel.Result) {
    val digit = call.argument<String>("digit") ?: run {
      result.error("INVALID_ARGS", "DTMF digit is required", null)
      return
    }
    try {
      callOperationsManager.sendDtmfTone(digit)
      Timber.v("Send DTMF: $digit")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to send DTMF")
      result.error("DTMF_ERROR", e.message, null)
    }
  }

  private fun handleMergeActiveCalls(call: MethodCall, result: MethodChannel.Result) {
    try {
      callOperationsManager.mergeActiveCalls()
      Timber.v("Merge calls requested from Flutter")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to merge calls")
      result.error("MERGE_ERROR", e.message, null)
    }
  }

  private fun handleSwapCalls(call: MethodCall, result: MethodChannel.Result) {
    try {
      callOperationsManager.swapActiveCalls()
      Timber.v("Swap calls requested from Flutter")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to swap calls")
      result.error("SWAP_ERROR", e.message, null)
    }
  }

  private fun handleSetCallForwarding(call: MethodCall, result: MethodChannel.Result) {
    val reasonLabel = call.argument<String>("reason") ?: "unconditional"
    val number = call.argument<String>("number")
    val enable = call.argument<Boolean>("enable") ?: true

    val reason = when (reasonLabel) {
      "unconditional" -> 0
      "busy" -> 1
      "noAnswer" -> 2
      "unreachable" -> 3
      else -> 0
    }

    try {
      callForwardingManager.setForwarding(enabled = enable, number = number, reason = reason)
      Timber.v("Set call forwarding: reason=$reasonLabel, number=$number, enable=$enable")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to set call forwarding")
      result.error("FORWARDING_ERROR", e.message, null)
    }
  }

  private fun handleGetPhoneAccounts(call: MethodCall, result: MethodChannel.Result) {
    try {
      val accounts = simManager.getActiveSimSlots().map { sim ->
        mapOf(
          "slot" to sim.slotIndex,
          "subscriptionId" to sim.subscriptionId,
          "displayName" to sim.displayName,
          "simOperatorName" to sim.displayName,
          "hasPhoneAccount" to (phoneAccountManager.getPhoneAccountHandle(sim.subscriptionId) != null),
        )
      }

      Timber.v("Get phone accounts: ${accounts.size} accounts")
      result.success(accounts)
    } catch (e: Exception) {
      Timber.e(e, "Failed to get phone accounts")
      result.error("ACCOUNTS_ERROR", e.message, null)
    }
  }

  private fun handleSelectPhoneAccount(call: MethodCall, result: MethodChannel.Result) {
    val simSlot = call.argument<Int>("simSlot") ?: run {
      result.error("INVALID_ARGS", "SIM slot is required", null)
      return
    }

    // System default outgoing account selection is managed by Android settings UI.
    Timber.v("Select phone account requested for SIM slot $simSlot")
    result.success(null)
  }

  private fun handleAcceptCall(call: MethodCall, result: MethodChannel.Result) {
    val callId = call.argument<String>("callId")

    try {
      callOperationsManager.answerCall(callId)
      Timber.v("Accept call: $callId")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to accept call")
      result.error("ACCEPT_ERROR", e.message, null)
    }
  }

  private fun handleRejectCall(call: MethodCall, result: MethodChannel.Result) {
    val callId = call.argument<String>("callId")

    try {
      callOperationsManager.rejectCall(callId)
      Timber.v("Reject call: $callId")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to reject call")
      result.error("REJECT_ERROR", e.message, null)
    }
  }

  private fun handleGetBlockedNumbers(call: MethodCall, result: MethodChannel.Result) {
    try {
      val blockedNumbers = mutableListOf<String>()
      val cursor = context.contentResolver.query(
        BlockedNumberContract.BlockedNumbers.CONTENT_URI,
        arrayOf(BlockedNumberContract.BlockedNumbers.COLUMN_ORIGINAL_NUMBER),
        null, null, null
      )
      cursor?.use {
        val colIndex = it.getColumnIndex(BlockedNumberContract.BlockedNumbers.COLUMN_ORIGINAL_NUMBER)
        while (it.moveToNext()) {
          blockedNumbers.add(it.getString(colIndex))
        }
      }
      Timber.v("Get blocked numbers: ${blockedNumbers.size} found")
      result.success(blockedNumbers)
    } catch (e: Exception) {
      Timber.e(e, "Failed to get blocked numbers")
      result.error("BLOCKED_ERROR", e.message, null)
    }
  }

  private fun handleBlockNumber(call: MethodCall, result: MethodChannel.Result) {
    val number = call.argument<String>("number") ?: run {
      result.error("INVALID_ARGS", "Phone number is required", null)
      return
    }

    try {
      val values = ContentValues().apply {
        put(BlockedNumberContract.BlockedNumbers.COLUMN_ORIGINAL_NUMBER, number)
      }
      context.contentResolver.insert(
        BlockedNumberContract.BlockedNumbers.CONTENT_URI, values
      )
      Timber.v("Block number: $number")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to block number")
      result.error("BLOCK_ERROR", e.message, null)
    }
  }

  private fun handleUnblockNumber(call: MethodCall, result: MethodChannel.Result) {
    val number = call.argument<String>("number") ?: run {
      result.error("INVALID_ARGS", "Phone number is required", null)
      return
    }

    try {
      val deleted = BlockedNumberContract.unblock(context, number)
      Timber.v("Unblock number: $number, result=$deleted")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to unblock number")
      result.error("UNBLOCK_ERROR", e.message, null)
    }
  }

  private fun handleEnableCallForwarding(call: MethodCall, result: MethodChannel.Result) {
    val forwardingType = call.argument<String>("forwardingType") ?: run {
      result.error("INVALID_ARGS", "Forwarding type is required", null)
      return
    }
    val forwardingNumber = call.argument<String>("forwardingNumber") ?: run {
      result.error("INVALID_ARGS", "Forwarding number is required", null)
      return
    }

    try {
      val reason = when (forwardingType) {
        "unconditional" -> 0 // CF_REASON_UNCONDITIONAL
        "busy" -> 1 // CF_REASON_BUSY
        "noAnswer" -> 2 // CF_REASON_NO_REPLY
        "unreachable" -> 3 // CF_REASON_NOT_REACHABLE
        else -> 0
      }
      
      callForwardingManager.setForwarding(
        enabled = true,
        number = forwardingNumber,
        reason = reason,
      )
      Timber.v("Enable call forwarding: type=$forwardingType, number=$forwardingNumber")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to enable call forwarding")
      result.error("FORWARDING_ERROR", e.message, null)
    }
  }

  private fun handleDisableCallForwarding(call: MethodCall, result: MethodChannel.Result) {
    val forwardingType = call.argument<String>("forwardingType") ?: run {
      result.error("INVALID_ARGS", "Forwarding type is required", null)
      return
    }

    try {
      val reason = when (forwardingType) {
        "unconditional" -> 0 // CF_REASON_UNCONDITIONAL
        "busy" -> 1 // CF_REASON_BUSY
        "noAnswer" -> 2 // CF_REASON_NO_REPLY
        "unreachable" -> 3 // CF_REASON_NOT_REACHABLE
        else -> 0
      }
      
      callForwardingManager.setForwarding(
        enabled = false,
        number = null,
        reason = reason,
      )
      Timber.v("Disable call forwarding: type=$forwardingType")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to disable call forwarding")
      result.error("FORWARDING_ERROR", e.message, null)
    }
  }

  private fun handleCheckDefaultDialer(call: MethodCall, result: MethodChannel.Result) {
    try {
      val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
      val defaultDialerPackage = telecomManager.defaultDialerPackage
      val isDefault = defaultDialerPackage == context.packageName
      
      Timber.v("Check default dialer: $isDefault (current=$defaultDialerPackage)")
      result.success(isDefault)
    } catch (e: Exception) {
      Timber.e(e, "Failed to check default dialer")
      result.error("DEFAULT_DIALER_ERROR", e.message, null)
    }
  }

  private fun handleSetDefaultDialer(call: MethodCall, result: MethodChannel.Result) {
    try {
      val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
      
      val intent = Intent(android.telecom.TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
        .putExtra(android.telecom.TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, context.packageName)
      val activity = activityRef?.get()
      if (activity != null && !activity.isFinishing) {
        // Use Activity context — works on all OEMs including MIUI which blocks app-context launches
        activity.startActivity(intent)
      } else {
        // Fallback: application context requires NEW_TASK flag
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
      }
      
      Timber.v("Set default dialer requested")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to set default dialer")
      result.error("SET_DEFAULT_DIALER_ERROR", e.message, null)
    }
  }

  private fun handleSendUssd(call: MethodCall, result: MethodChannel.Result) {
    val code = call.argument<String>("code") ?: run {
      result.error("INVALID_ARGS", "USSD code is required", null)
      return
    }
    val simSlot = call.argument<Int>("simSlot") ?: 0

    try {
      // Validate USSD code format
      if (!ussdManager.isUssdOrMmi(code)) {
        Timber.w("Invalid USSD code format: $code")
        // Still attempt to send, but log warning
      }

      // Convert simSlot (0 or 1) to subscriptionId for TelephonyManager
      // -1 means default subscription
      val subscriptionId = if (simSlot > 0) {
        // Get actual subscription ID from simSlot
        // For now, use simSlot value (this may need refinement)
        simSlot
      } else {
        -1 // Default subscription
      }

      // Send USSD using UssdManager (which handles responses via EventChannel)
      ussdManager.sendUssd(code, subscriptionId)
      Timber.v("Send USSD: code=$code, simSlot=$simSlot, subscriptionId=$subscriptionId")
      result.success(null)
    } catch (e: Exception) {
      Timber.e(e, "Failed to send USSD code $code")
      result.error("USSD_ERROR", e.message, null)
    }
  }
}

