package com.mangrule.dailathon.presentation.channels

import android.content.Context
import android.os.Handler
import android.os.Looper
import dagger.hilt.android.qualifiers.ApplicationContext
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import timber.log.Timber
import com.mangrule.dailathon.contacts.ContactsRepository
import com.mangrule.dailathon.contacts.CallLogRepository
import com.mangrule.dailathon.blocking.BlockedNumbersRepository
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Handles all MethodChannel calls from Flutter for contacts and call log access.
 * All calls are dispatched on the main thread to ensure safety.
 * Delegates to underlying repositories for domain logic.
 */
@Singleton
class ContactsMethodChannelHandler @Inject constructor(
    @ApplicationContext private val context: Context,
    private val contactsRepository: ContactsRepository,
    private val callLogRepository: CallLogRepository,
    private val blockedNumbersRepository: BlockedNumbersRepository,
) {
    companion object {
        private const val CHANNEL_NAME = "com.mangrule.dailathon/contacts"
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var methodChannel: MethodChannel? = null

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
                        "getCallLog" -> handleGetCallLog(call, result)
                        "getContacts" -> handleGetContacts(call, result)
                        "searchContacts" -> handleSearchContacts(call, result)
                        "lookupNumber" -> handleLookupNumber(call, result)
                        "getFavoriteContacts" -> handleGetFavoriteContacts(call, result)
                        "getBlockedNumbers" -> handleGetBlockedNumbers(call, result)
                        "blockNumber" -> handleBlockNumber(call, result)
                        "unblockNumber" -> handleUnblockNumber(call, result)
                        "isBlocked" -> handleIsBlocked(call, result)
                        "deleteCallLogEntry" -> handleDeleteCallLogEntry(call, result)
                        "clearCallLog" -> handleClearCallLog(call, result)
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    Timber.e(e, "Error handling method: ${call.method}")
                    result.error("ERROR", e.message, e.stackTraceToString())
                }
            }
        }
        Timber.v("ContactsMethodChannelHandler initialized")
    }

    /**
     * Get call log entries.
     * Returns list of call log items as maps.
     */
    private fun handleGetCallLog(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        try {
            val limit = call.argument<Int>("limit") ?: 500
            val type = call.argument<Int>("type")  // Optional: filter by type (INCOMING, OUTGOING, MISSED)

            val entries = if (type != null) {
                callLogRepository.getCallLogByType(type, limit)
            } else {
                callLogRepository.getCallLog(limit)
            }

            val entriesAsMap = entries.map { entry ->
                mapOf(
                    "id" to entry.id,
                    "phoneNumber" to entry.phoneNumber,
                    "name" to entry.name,
                    "timestamp" to entry.timestamp,
                    "duration" to entry.duration,
                    "type" to entry.type,
                )
            }

            Timber.v("GetCallLog: ${entriesAsMap.size} entries returned")
            result.success(entriesAsMap)
        } catch (e: Exception) {
            Timber.e(e, "Failed to get call log")
            result.error("CALL_LOG_ERROR", e.message, null)
        }
    }

    /**
     * Get all contacts with phone numbers.
     * Returns list of contact items as maps.
     */
    private fun handleGetContacts(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        try {
            val contacts = contactsRepository.getAllContacts()

            val contactsAsMap = contacts.map { contact ->
                mapOf(
                    "id" to contact.id,
                    "name" to contact.name,
                    "phoneNumber" to contact.phoneNumber,
                    "photoUri" to contact.photoUri,
                )
            }

            Timber.v("GetContacts: ${contactsAsMap.size} contacts returned")
            result.success(contactsAsMap)
        } catch (e: Exception) {
            Timber.e(e, "Failed to get contacts")
            result.error("CONTACTS_ERROR", e.message, null)
        }
    }

    /**
     * Search contacts by query using T9 matching.
     * Supports fuzzy matching on display names and numbers.
     */
    private fun handleSearchContacts(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        val query = call.argument<String>("query") ?: run {
            result.error("INVALID_ARGS", "Query is required", null)
            return
        }

        try {
            val contacts = contactsRepository.searchByQuery(query)

            val contactsAsMap = contacts.map { contact ->
                mapOf(
                    "id" to contact.id,
                    "name" to contact.name,
                    "phoneNumber" to contact.phoneNumber,
                    "photoUri" to contact.photoUri,
                )
            }

            Timber.v("SearchContacts: query='$query' returned ${contactsAsMap.size} results")
            result.success(contactsAsMap)
        } catch (e: Exception) {
            Timber.e(e, "Failed to search contacts for query: $query")
            result.error("SEARCH_ERROR", e.message, null)
        }
    }

    /**
     * Look up a single contact by phone number.
     * Returns contact info as map or null if not found.
     */
    private fun handleLookupNumber(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        val number = call.argument<String>("number") ?: run {
            result.error("INVALID_ARGS", "Phone number is required", null)
            return
        }

        try {
            val contact = contactsRepository.lookupByNumber(number)

            if (contact != null) {
                val contactMap = mapOf(
                    "id" to contact.id,
                    "name" to contact.name,
                    "phoneNumber" to contact.phoneNumber,
                    "photoUri" to contact.photoUri,
                )
                Timber.v("LookupNumber: found contact for $number")
                result.success(contactMap)
            } else {
                Timber.v("LookupNumber: no contact found for $number")
                result.success(null)
            }
        } catch (e: Exception) {
            Timber.e(e, "Failed to lookup number: $number")
            result.error("LOOKUP_ERROR", e.message, null)
        }
    }

    /**
     * Get starred/favorite contacts.
     * Returns filtered list of contacts marked as favorites in system contacts.
     */
    private fun handleGetFavoriteContacts(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        try {
            val contacts = contactsRepository.getFavoriteContacts()

            val contactsAsMap = contacts.map { contact ->
                mapOf(
                    "id" to contact.id,
                    "name" to contact.name,
                    "phoneNumber" to contact.phoneNumber,
                    "photoUri" to contact.photoUri,
                )
            }

            Timber.v("GetFavoriteContacts: ${contactsAsMap.size} favorites returned")
            result.success(contactsAsMap)
        } catch (e: Exception) {
            Timber.e(e, "Failed to get favorite contacts")
            result.error("FAVORITES_ERROR", e.message, null)
        }
    }

    /**
     * Get all blocked phone numbers.
     * Uses BlockedNumberContract (API 24+) with SharedPreferences fallback.
     */
    private fun handleGetBlockedNumbers(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        try {
            val blockedNumbers = blockedNumbersRepository.getBlockedNumbers()
            Timber.v("GetBlockedNumbers: ${blockedNumbers.size} numbers blocked")
            result.success(blockedNumbers)
        } catch (e: Exception) {
            Timber.e(e, "Failed to get blocked numbers")
            result.error("BLOCKED_NUMBERS_ERROR", e.message, null)
        }
    }

    /**
     * Block a phone number.
     * Uses BlockedNumberContract (API 24+) with SharedPreferences fallback.
     */
    private fun handleBlockNumber(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        val number = call.argument<String>("number") ?: run {
            result.error("INVALID_ARGS", "Phone number is required", null)
            return
        }

        try {
            blockedNumbersRepository.blockNumber(number)
            Timber.v("BlockNumber: blocked $number")
            result.success(null)
        } catch (e: Exception) {
            Timber.e(e, "Failed to block number: $number")
            result.error("BLOCK_ERROR", e.message, null)
        }
    }

    /**
     * Unblock a phone number.
     * Uses BlockedNumberContract (API 24+) with SharedPreferences fallback.
     */
    private fun handleUnblockNumber(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        val number = call.argument<String>("number") ?: run {
            result.error("INVALID_ARGS", "Phone number is required", null)
            return
        }

        try {
            blockedNumbersRepository.unblockNumber(number)
            Timber.v("UnblockNumber: unblocked $number")
            result.success(null)
        } catch (e: Exception) {
            Timber.e(e, "Failed to unblock number: $number")
            result.error("UNBLOCK_ERROR", e.message, null)
        }
    }

    /**
     * Check if a phone number is blocked.
     */
    private fun handleIsBlocked(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        val number = call.argument<String>("number") ?: run {
            result.error("INVALID_ARGS", "Phone number is required", null)
            return
        }

        try {
            val isBlocked = blockedNumbersRepository.isBlocked(number)
            Timber.v("IsBlocked: $number = $isBlocked")
            result.success(isBlocked)
        } catch (e: Exception) {
            Timber.e(e, "Failed to check if blocked: $number")
            result.error("CHECK_BLOCKED_ERROR", e.message, null)
        }
    }

    /**
     * Delete a specific call log entry.
     */
    private fun handleDeleteCallLogEntry(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        val entryId = call.argument<String>("entryId") ?: run {
            result.error("INVALID_ARGS", "Entry ID is required", null)
            return
        }

        try {
            callLogRepository.deleteEntry(entryId)
            Timber.v("DeleteCallLogEntry: $entryId deleted")
            result.success(null)
        } catch (e: Exception) {
            Timber.e(e, "Failed to delete call log entry: $entryId")
            result.error("DELETE_ENTRY_ERROR", e.message, null)
        }
    }

    /**
     * Clear all call log entries.
     */
    private fun handleClearCallLog(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        try {
            callLogRepository.clearCallLog()
            Timber.v("ClearCallLog: all entries cleared")
            result.success(null)
        } catch (e: Exception) {
            Timber.e(e, "Failed to clear call log")
            result.error("CLEAR_CALL_LOG_ERROR", e.message, null)
        }
    }
}
