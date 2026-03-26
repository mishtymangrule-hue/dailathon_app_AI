package com.mangrule.dailathon

import android.os.Bundle
import dagger.hilt.android.AndroidEntryPoint
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import timber.log.Timber
import com.mangrule.dailathon.presentation.channels.CallMethodChannelHandler
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : FlutterActivity() {

    @Inject
    lateinit var callMethodChannelHandler: CallMethodChannelHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        callMethodChannelHandler.initialize(flutterEngine)
        Timber.d("MainActivity: configureFlutterEngine - method channel initialized")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Timber.d("MainActivity created")
    }

    override fun onResume() {
        super.onResume()
        // Enable FLAG_KEEP_SCREEN_ON for in-call UI
        // Complements ScreenWakeLock in DialerConnection
        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        Timber.d("MainActivity resumed with screen flag enabled")
    }

    override fun onPause() {
        super.onPause()
        // Disable FLAG_KEEP_SCREEN_ON to save battery when not active
        window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        Timber.d("MainActivity paused, screen flag cleared")
    }
}
