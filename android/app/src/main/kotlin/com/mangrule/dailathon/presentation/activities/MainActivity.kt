package com.mangrule.dailathon.presentation.activities

import android.os.Bundle
import dagger.hilt.android.AndroidEntryPoint
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import timber.log.Timber
import com.mangrule.dailathon.presentation.channels.CallMethodChannelHandler
import com.mangrule.dailathon.presentation.channels.CallEventChannelService
import com.mangrule.dailathon.presentation.channels.ContactsMethodChannelHandler
import javax.inject.Inject

/**
 * Main activity for Dailathon Telecom Dialer.
 * Initializes Flutter engine and wires up native platform channels.
 */
@AndroidEntryPoint
class MainActivity : FlutterActivity() {
  @Inject lateinit var callMethodChannelHandler: CallMethodChannelHandler
  @Inject lateinit var callEventChannelService: CallEventChannelService
  @Inject lateinit var contactsMethodChannelHandler: ContactsMethodChannelHandler

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    Timber.v("MainActivity created")
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    try {
      // Initialize bidirectional method channel (Flutter → Kotlin calls)
      callMethodChannelHandler.initialize(flutterEngine)
      Timber.v("CallMethodChannelHandler initialized")

      // Initialize contacts method channel (Flutter → Kotlin calls)
      contactsMethodChannelHandler.initialize(flutterEngine)
      Timber.v("ContactsMethodChannelHandler initialized")

      // Initialize event channel (Kotlin → Flutter events)
      callEventChannelService.initialize(flutterEngine)
      Timber.v("CallEventChannelService initialized")

      Timber.v("Flutter engine configured with custom channels")
    } catch (e: Exception) {
      Timber.e(e, "Failed to configure Flutter engine channels")
      throw e
    }
  }

  override fun onDestroy() {
    try {
      callEventChannelService.dispose()
      Timber.v("Channels cleaned up")
    } catch (e: Exception) {
      Timber.e(e, "Error cleaning up channels")
    }
    super.onDestroy()
  }
}
