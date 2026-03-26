package com.mangrule.dailathon.contacts

import android.content.Context
import android.provider.CallLog
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import timber.log.Timber

/**
 * CallLogRepository handles reading and writing call log entries.
 * Supports querying call history, insertion of new entries, and deletion.
 */
@Singleton
class CallLogRepository @Inject constructor(
    @ApplicationContext private val context: Context,
) {

    private val contentResolver = context.contentResolver

    /**
     * Get recent call log entries.
     */
    fun getCallLog(limit: Int = 500): List<CallLogItem> {
        val callLogEntries = mutableListOf<CallLogItem>()

        try {
            val cursor = contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(
                    CallLog.Calls._ID,
                    CallLog.Calls.NUMBER,
                    CallLog.Calls.CACHED_NAME,
                    CallLog.Calls.DATE,
                    CallLog.Calls.DURATION,
                    CallLog.Calls.TYPE,
                ),
                null,
                null,
                CallLog.Calls.DATE + " DESC LIMIT $limit"
            )

            cursor?.use {
                while (it.moveToNext()) {
                    val id = it.getString(0)
                    val number = it.getString(1)
                    val name = it.getString(2) ?: number
                    val timestamp = it.getLong(3)
                    val duration = it.getInt(4)
                    val type = it.getInt(5)

                    callLogEntries.add(
                        CallLogItem(
                            id = id,
                            phoneNumber = number,
                            name = name,
                            timestamp = timestamp,
                            duration = duration,
                            type = type,
                        )
                    )
                }
            }

            Timber.d("CallLogRepository.getCallLog: ${callLogEntries.size} entries loaded")
        } catch (e: Exception) {
            Timber.e(e, "Error loading call log")
        }

        return callLogEntries
    }

    /**
     * Get call log entries filtered by type.
     */
    fun getCallLogByType(type: Int, limit: Int = 500): List<CallLogItem> {
        val allEntries = getCallLog(limit)
        return allEntries.filter { it.type == type }
    }

    /**
     * Add a new entry to call log.
     */
    fun insertEntry(phoneNumber: String, duration: Int, type: Int, name: String? = null) {
        try {
            val contentValues = android.content.ContentValues().apply {
                put(CallLog.Calls.NUMBER, phoneNumber)
                put(CallLog.Calls.TYPE, type)
                put(CallLog.Calls.DATE, System.currentTimeMillis())
                put(CallLog.Calls.DURATION, duration)
                put(CallLog.Calls.CACHED_NAME, name ?: phoneNumber)
            }

            contentResolver.insert(CallLog.Calls.CONTENT_URI, contentValues)
            Timber.d("CallLogRepository.insertEntry: $phoneNumber ($type) duration=${duration}s")
        } catch (e: Exception) {
            Timber.e(e, "Error inserting call log entry")
        }
    }

    /**
     * Delete a call log entry by ID.
     */
    fun deleteEntry(id: String) {
        try {
            contentResolver.delete(
                CallLog.Calls.CONTENT_URI,
                "${CallLog.Calls._ID}=?",
                arrayOf(id)
            )
            Timber.d("CallLogRepository.deleteEntry: $id deleted")
        } catch (e: Exception) {
            Timber.e(e, "Error deleting call log entry")
        }
    }

    /**
     * Clear all call log.
     */
    fun clearCallLog() {
        try {
            contentResolver.delete(CallLog.Calls.CONTENT_URI, null, null)
            Timber.d("CallLogRepository.clearCallLog: all entries cleared")
        } catch (e: Exception) {
            Timber.e(e, "Error clearing call log")
        }
    }

    /**
     * Get all calls with a specific phone number.
     */
    fun getCallsWithNumber(phoneNumber: String): List<CallLogItem> {
        return getCallLog(1000).filter {
            it.phoneNumber.contains(phoneNumber) || phoneNumber.contains(it.phoneNumber)
        }
    }
}
