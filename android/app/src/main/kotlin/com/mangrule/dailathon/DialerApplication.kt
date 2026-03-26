package com.mangrule.dailathon

import android.app.Application
import dagger.hilt.android.HiltAndroidApp
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import timber.log.Timber
import javax.inject.Inject
import com.mangrule.dailathon.telecom.PhoneAccountManager

@HiltAndroidApp
class DialerApplication : Application() {

    @Inject
    lateinit var phoneAccountManager: PhoneAccountManager

    override fun onCreate() {
        super.onCreate()

        // Initialize logging
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        } else {
            // Release build: plant release tree (errors only)
            Timber.plant(ReleaseTree())
        }

        // Initialize Flutter engine
        initializeFlutterEngine()

        // Register all PhoneAccounts for active SIMs
        try {
            phoneAccountManager.ensureAllRegistered()
            Timber.d("DialerApplication: PhoneAccounts registered")
        } catch (e: Exception) {
            Timber.e(e, "Error registering PhoneAccounts")
        }

        Timber.d("DialerApplication initialized successfully")
    }

    private fun initializeFlutterEngine() {
        try {
            val engine = FlutterEngine(this)
            engine.dartExecutor.executeDartEntrypoint(
                io.flutter.embedding.engine.DartExecutor.DartEntrypoint.createDefault()
            )
            FlutterEngineCache.getInstance().put("main_engine", engine)
            Timber.d("DialerApplication: Flutter engine initialized")
        } catch (e: Exception) {
            Timber.e(e, "Error initializing Flutter engine")
        }
    }

    /**
     * Release build Timber tree - logs errors only.
     */
    private class ReleaseTree : Timber.Tree() {
        override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
            if (priority == android.util.Log.ERROR || priority == android.util.Log.WARN) {
                android.util.Log.println(priority, tag, message)
            }
        }
    }
}
