package com.mangrule.dailathon.presentation.channels

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages EventChannel for pushing USSD responses from Kotlin to Flutter.
 * Handles USSD responses, failures, and interactive codes (IMEI fetch, device info).
 */
@Singleton
class UssdEventChannelService @Inject constructor() {
    companion object {
        private const val CHANNEL_NAME = "com.mangrule.dailathon/ussd_events"
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    /**
     * Initialize EventChannel with FlutterEngine.
     * Called from MainActivity.configureFlutterEngine()
     */
    fun initialize(flutterEngine: FlutterEngine) {
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Timber.v("UssdEventChannelService: listener attached")
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                Timber.v("UssdEventChannelService: listener detached")
                eventSink = null
            }
        })
        Timber.v("UssdEventChannelService initialized on channel: $CHANNEL_NAME")
    }

    /**
     * Push a successful USSD response to Flutter.
     */
    fun pushUssdResponse(code: String, response: String) {
        mainHandler.post {
            try {
                val eventMap = mapOf(
                    "success" to true,
                    "code" to code,
                    "response" to response,
                    "timestamp" to System.currentTimeMillis(),
                )
                eventSink?.success(eventMap)
                Timber.v("Pushed USSD response: code=$code")
            } catch (e: Exception) {
                Timber.e(e, "Error pushing USSD response")
                eventSink?.error("USSD_ERROR", e.message, null)
            }
        }
    }

    /**
     * Push a USSD response failure to Flutter.
     */
    fun pushUssdFailure(code: String, failureCode: Int, message: String = "") {
        mainHandler.post {
            try {
                val eventMap = mapOf(
                    "success" to false,
                    "code" to code,
                    "failureCode" to failureCode,
                    "message" to message,
                    "timestamp" to System.currentTimeMillis(),
                )
                eventSink?.success(eventMap)
                Timber.v("Pushed USSD failure: code=$code, failureCode=$failureCode")
            } catch (e: Exception) {
                Timber.e(e, "Error pushing USSD failure")
                eventSink?.error("USSD_ERROR", e.message, null)
            }
        }
    }

    /**
     * Push an interactive code result (IMEI, device info, etc.) to Flutter.
     */
    fun pushInteractiveCodeResult(codeType: String, result: String) {
        mainHandler.post {
            try {
                val eventMap = mapOf(
                    "type" to "interactive",
                    "codeType" to codeType,
                    "result" to result,
                    "timestamp" to System.currentTimeMillis(),
                )
                eventSink?.success(eventMap)
                Timber.v("Pushed interactive code result: type=$codeType")
            } catch (e: Exception) {
                Timber.e(e, "Error pushing interactive code result")
                eventSink?.error("USSD_ERROR", e.message, null)
            }
        }
    }

    /**
     * Clean up resources.
     */
    fun dispose() {
        eventSink = null
        eventChannel = null
    }
}
