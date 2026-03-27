package com.mangrule.dailathon.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import timber.log.Timber
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Periodic WorkManager worker that triggers a CRM event queue flush via
 * the Flutter MethodChannel.
 *
 * Registered in [DialerApplication] to run every 15 minutes when network is
 * available.  If no Flutter engine is cached yet (cold start), the worker
 * succeeds immediately and defers to the next run.
 */
class CrmFlushWorker(
    private val context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {

    companion object {
        const val CHANNEL = "com.mangrule.dailathon/crm_flush"
        const val METHOD_FLUSH = "flushQueue"
        const val WORK_NAME = "crm_flush_periodic"
    }

    override suspend fun doWork(): Result {
        Timber.d("CrmFlushWorker: starting flush")
        val engine: FlutterEngine =
            FlutterEngineCache.getInstance().get("main_engine")
                ?: run {
                    Timber.w("CrmFlushWorker: no cached Flutter engine — skipping")
                    return Result.success()
                }

        return try {
            withContext(Dispatchers.Main) { flushViaChannel(engine) }
            Timber.d("CrmFlushWorker: flush complete")
            Result.success()
        } catch (e: Exception) {
            Timber.e(e, "CrmFlushWorker: flush failed")
            Result.retry()
        }
    }

    private suspend fun flushViaChannel(engine: FlutterEngine) =
        suspendCancellableCoroutine { cont ->
            val channel = MethodChannel(
                engine.dartExecutor.binaryMessenger,
                CHANNEL,
            )
            channel.invokeMethod(
                METHOD_FLUSH,
                null,
                object : MethodChannel.Result {
                    override fun success(result: Any?) = cont.resume(Unit)
                    override fun error(code: String, msg: String?, details: Any?) =
                        cont.resumeWithException(
                            RuntimeException("CRM flush error $code: $msg")
                        )
                    override fun notImplemented() = cont.resume(Unit)
                },
            )
        }
}
