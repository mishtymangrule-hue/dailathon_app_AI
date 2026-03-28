package com.mangrule.dailathon.presentation.activities

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import timber.log.Timber
import com.mangrule.dailathon.presentation.channels.CallMethodChannelHandler
import com.mangrule.dailathon.presentation.channels.CallEventChannelService
import com.mangrule.dailathon.presentation.channels.ContactsMethodChannelHandler
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.components.SingletonComponent
import com.mangrule.dailathon.telecom.PhoneAccountManager

/**
 * Main activity for Dailathon Telecom Dialer.
 * Initializes Flutter engine and wires up native platform channels.
 */
class MainActivity : FlutterActivity() {
  private lateinit var callMethodChannelHandler: CallMethodChannelHandler
  private lateinit var callEventChannelService: CallEventChannelService
  private lateinit var contactsMethodChannelHandler: ContactsMethodChannelHandler
  private lateinit var phoneAccountManager: PhoneAccountManager

  @EntryPoint
  @InstallIn(SingletonComponent::class)
  interface MainActivityEntryPoint {
    fun callMethodChannelHandler(): CallMethodChannelHandler
    fun callEventChannelService(): CallEventChannelService
    fun contactsMethodChannelHandler(): ContactsMethodChannelHandler
    fun phoneAccountManager(): PhoneAccountManager
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    // Must initialize BEFORE super.onCreate() because FlutterActivity calls
    // configureFlutterEngine() during super.onCreate(), and that method accesses
    // these lateinit properties.
    val entryPoint = EntryPointAccessors.fromApplication(
      applicationContext,
      MainActivityEntryPoint::class.java,
    )
    callMethodChannelHandler = entryPoint.callMethodChannelHandler()
    callEventChannelService = entryPoint.callEventChannelService()
    contactsMethodChannelHandler = entryPoint.contactsMethodChannelHandler()
    phoneAccountManager = entryPoint.phoneAccountManager()

    super.onCreate(savedInstanceState)

    // Register phone accounts for all SIM cards
    phoneAccountManager.ensureAllRegistered()
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

  override fun onResume() {
    super.onResume()
    callMethodChannelHandler.setActivity(this)
  }

  @Suppress("DEPRECATION")
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
    // Re-attach activity after the role dialog closes so subsequent checks work
    if (requestCode == CallMethodChannelHandler.REQUEST_CODE_ROLE_DIALER) {
      callMethodChannelHandler.setActivity(this)
      Timber.v("RoleManager result: resultCode=$resultCode")
    }
  }

  override fun onPause() {
    callMethodChannelHandler.setActivity(null)
    super.onPause()
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
