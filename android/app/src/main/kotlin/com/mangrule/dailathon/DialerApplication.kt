package com.mangrule.dailathon

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.mangrule.dailathon.notification.NotificationAlarmReceiver
import com.mangrule.dailathon.telecom.PhoneAccountManager
import com.mangrule.dailathon.worker.CrmFlushWorker
import dagger.hilt.android.HiltAndroidApp
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import timber.log.Timber
import java.util.concurrent.TimeUnit
import javax.inject.Inject

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

        // Create all notification channels
        createAllNotificationChannels()

        // Initialize Flutter engine
        initializeFlutterEngine()

        // Register all PhoneAccounts for active SIMs
        try {
            phoneAccountManager.ensureAllRegistered()
            Timber.d("DialerApplication: PhoneAccounts registered")
        } catch (e: Exception) {
            Timber.e(e, "Error registering PhoneAccounts")
        }

        // Register periodic CRM flush worker
        registerCrmFlushWorker()

        Timber.d("DialerApplication initialized successfully")
    }

    private fun createAllNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

        // CRM scheduled reminders
        val crmChannel = NotificationChannel(
            NotificationAlarmReceiver.CHANNEL_ID,
            "CRM Reminders",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Scheduled call reminders from your CRM"
            enableVibration(true)
        }

        manager.createNotificationChannels(listOf(crmChannel))
        Timber.d("DialerApplication: notification channels created")
    }

    private fun registerCrmFlushWorker() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()
        val request = PeriodicWorkRequestBuilder<CrmFlushWorker>(
            15, TimeUnit.MINUTES,
        )
            .setConstraints(constraints)
            .build()
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            CrmFlushWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
        Timber.d("DialerApplication: CRM flush worker registered")
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
