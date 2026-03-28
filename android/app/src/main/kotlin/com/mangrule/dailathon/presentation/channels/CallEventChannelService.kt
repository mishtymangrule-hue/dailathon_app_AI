package com.mangrule.dailathon.presentation.channels

import android.content.Context
import android.os.Handler
import android.os.Looper
import dagger.hilt.android.qualifiers.ApplicationContext
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import timber.log.Timber
import com.mangrule.dailathon.core.models.CallInfo
import com.mangrule.dailathon.core.models.CallState
import com.mangrule.dailathon.core.models.toMap
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.cancel
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages EventChannel for pushing call state updates from Kotlin to Flutter.
 * Handles subscription lifecycle and broadcasts call state changes in real-time.
 */
@Singleton
class CallEventChannelService @Inject constructor(
  @ApplicationContext private val context: Context,
) {
  companion object {
    private const val CHANNEL_NAME = "com.mangrule.dailathon/call_events"
  }

  private val mainHandler = Handler(Looper.getMainLooper())
  private var eventChannel: EventChannel? = null
  private var eventSink: EventChannel.EventSink? = null

  // Shared flow for call state updates
  private val callStateChannel = MutableSharedFlow<CallInfo>(extraBufferCapacity = 10)

  // Coroutine scope for lifecycle management
  private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

  /**
   * Initialize EventChannel with FlutterEngine.
   * Called from MainActivity.configureFlutterEngine()
   */
  fun initialize(flutterEngine: FlutterEngine) {
    eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
    eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Timber.v("EventChannel listener attached")
        eventSink = events
        startListeningToCallUpdates()
      }

      override fun onCancel(arguments: Any?) {
        Timber.v("EventChannel listener detached")
        eventSink = null
        stopListeningToCallUpdates()
      }
    })
  }

  /**
   * Push a call state update to Flutter.
   * Called by DialerInCallService when call state changes.
   */
  fun pushCallStateUpdate(callInfo: CallInfo) {
    mainHandler.post {
      try {
        val eventMap = callInfo.toMap()
        eventSink?.success(eventMap)
        Timber.v("Pushed call state: ${callInfo.callId} - ${callInfo.state} (type=${callInfo.callType})")

        // Also broadcast internally for other subscribers
        scope.launch {
          callStateChannel.emit(callInfo)
        }
      } catch (e: Exception) {
        Timber.e(e, "Error pushing call state update")
        eventSink?.error("PUSH_ERROR", e.message, null)
      }
    }
  }

  /**
   * Push a raw map event to Flutter.
   * Used for MultiCallState-format events (activeCall, heldCall, waitingCall).
   */
  fun pushRawEvent(event: Map<String, Any?>) {
    mainHandler.post {
      try {
        eventSink?.success(event)
        Timber.v("Pushed raw event: keys=${event.keys}")
      } catch (e: Exception) {
        Timber.e(e, "Error pushing raw event")
      }
    }
  }

  /**
   * Push error event to Flutter.
   */
  fun pushError(code: String, message: String?, details: Any? = null) {
    mainHandler.post {
      try {
        eventSink?.error(code, message, details)
        Timber.v("Pushed error: $code - $message")
      } catch (e: Exception) {
        Timber.e(e, "Error pushing error event")
      }
    }
  }

  /**
   * Get the call state update stream for internal subscribers.
   * Used by BLoCs or other components listening to call changes.
   */
  fun getCallStateUpdatesFlow() = callStateChannel.asSharedFlow()

  private fun startListeningToCallUpdates() {
    scope.launch {
      try {
        Timber.v("Started listening to call state updates")
        // TODO: Subscribe to DialerInCallService call state changes
        // This will emit whenever a call state changes:
        // - onCallAdded() → emit CallInfo with state RINGING or DIALING
        // - onStateChanged() → emit CallInfo with state ACTIVE, HELD, DISCONNECTED, etc.
        // - onCallRemoved() → emit CallInfo with state DISCONNECTED
      } catch (e: Exception) {
        Timber.e(e, "Error listening to call updates")
        pushError("LISTEN_ERROR", e.message)
      }
    }
  }

  private fun stopListeningToCallUpdates() {
    scope.launch {
      try {
        Timber.v("Stopped listening to call state updates")
        // TODO: Unsubscribe from DialerInCallService
      } catch (e: Exception) {
        Timber.e(e, "Error stopping call update listener")
      }
    }
  }

  /**
   * Clean up resources.
   * Called when app is destroyed.
   */
  fun dispose() {
    try {
      scope.cancel()
      Timber.v("CallEventChannelService disposed")
    } catch (e: Exception) {
      Timber.e(e, "Error disposing CallEventChannelService")
    }
  }
}
