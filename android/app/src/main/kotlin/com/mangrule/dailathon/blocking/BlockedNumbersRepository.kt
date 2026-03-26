package com.mangrule.dailathon.blocking

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.provider.BlockedNumberContract
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import timber.log.Timber
import org.json.JSONArray
import org.json.JSONException

/**
 * BlockedNumbersRepository handles blocking and unblocking phone numbers.
 * Uses BlockedNumberContract (API 24+) with SharedPreferences fallback for API 21-23.
 */
@Singleton
class BlockedNumbersRepository @Inject constructor(
    @ApplicationContext private val context: Context,
) {

    private val contentResolver = context.contentResolver
    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences("blocked_numbers_prefs", Context.MODE_PRIVATE)
    }

    companion object {
        private const val BLOCKED_NUMBERS_KEY = "blocked_numbers_list"
    }

    /**
     * Get all blocked phone numbers.
     * Uses BlockedNumberContract on API 24+, SharedPreferences on API 21-23.
     */
    fun getBlockedNumbers(): List<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            getBlockedNumbersApi24Plus()
        } else {
            getBlockedNumbersApi21To23()
        }
    }

    /**
     * Get blocked numbers from BlockedNumberContract (API 24+).
     */
    private fun getBlockedNumbersApi24Plus(): List<String> {
        val blockedNumbers = mutableListOf<String>()

        try {
            val cursor = contentResolver.query(
                BlockedNumberContract.BlockedNumbers.CONTENT_URI,
                arrayOf(BlockedNumberContract.BlockedNumbers.COLUMN_ORIGINAL_NUMBER),
                null,
                null,
                null
            )

            cursor?.use {
                while (it.moveToNext()) {
                    val number = it.getString(0)
                    blockedNumbers.add(number)
                }
            }

            Timber.d("BlockedNumbersRepository.getBlockedNumbers (API 24+): ${blockedNumbers.size} blocked")
        } catch (e: Exception) {
            Timber.e(e, "Error fetching blocked numbers from BlockedNumberContract")
        }

        return blockedNumbers
    }

    /**
     * Get blocked numbers from SharedPreferences (API 21-23).
     * Fallback for devices without BlockedNumberContract.
     */
    private fun getBlockedNumbersApi21To23(): List<String> {
        return try {
            val jsonString = prefs.getString(BLOCKED_NUMBERS_KEY, "[]")
            val jsonArray = JSONArray(jsonString ?: "[]")
            val numbers = mutableListOf<String>()
            
            for (i in 0 until jsonArray.length()) {
                numbers.add(jsonArray.getString(i))
            }
            
            Timber.d("BlockedNumbersRepository.getBlockedNumbers (API 21-23): ${numbers.size} blocked")
            numbers
        } catch (e: JSONException) {
            Timber.e(e, "Error parsing blocked numbers from SharedPreferences")
            emptyList()
        }
    }

    /**
     * Block a phone number.
     * Uses BlockedNumberContract on API 24+, SharedPreferences on API 21-23.
     */
    fun blockNumber(number: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            blockNumberApi24Plus(number)
        } else {
            blockNumberApi21To23(number)
        }
    }

    /**
     * Block number via BlockedNumberContract (API 24+).
     */
    private fun blockNumberApi24Plus(number: String) {
        try {
            val contentValues = android.content.ContentValues().apply {
                put(BlockedNumberContract.BlockedNumbers.COLUMN_ORIGINAL_NUMBER, number)
            }

            contentResolver.insert(
                BlockedNumberContract.BlockedNumbers.CONTENT_URI,
                contentValues
            )

            Timber.d("BlockedNumbersRepository.blockNumber (API 24+): $number blocked")
        } catch (e: Exception) {
            Timber.e(e, "Error blocking number via BlockedNumberContract")
        }
    }

    /**
     * Block number via SharedPreferences (API 21-23).
     */
    private fun blockNumberApi21To23(number: String) {
        try {
            val currentNumbers = getBlockedNumbersApi21To23().toMutableList()
            
            // Add if not already blocked
            if (!currentNumbers.contains(number)) {
                currentNumbers.add(number)
                
                val jsonArray = JSONArray(currentNumbers)
                prefs.edit()
                    .putString(BLOCKED_NUMBERS_KEY, jsonArray.toString())
                    .apply()
                
                Timber.d("BlockedNumbersRepository.blockNumber (API 21-23): $number blocked")
            } else {
                Timber.w("BlockedNumbersRepository.blockNumber: $number already blocked")
            }
        } catch (e: Exception) {
            Timber.e(e, "Error blocking number via SharedPreferences")
        }
    }

    /**
     * Unblock a phone number.
     * Uses BlockedNumberContract on API 24+, SharedPreferences on API 21-23.
     */
    fun unblockNumber(number: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            unblockNumberApi24Plus(number)
        } else {
            unblockNumberApi21To23(number)
        }
    }

    private fun unblockNumberApi24Plus(number: String) {
        try {
            contentResolver.delete(
                BlockedNumberContract.BlockedNumbers.CONTENT_URI,
                "${BlockedNumberContract.BlockedNumbers.COLUMN_ORIGINAL_NUMBER}=?",
                arrayOf(number)
            )

            Timber.d("BlockedNumbersRepository.unblockNumber (API 24+): $number unblocked")
        } catch (e: Exception) {
            Timber.e(e, "Error unblocking number via BlockedNumberContract")
        }
    }

    /**
     * Unblock number via SharedPreferences (API 21-23).
     */
    private fun unblockNumberApi21To23(number: String) {
        try {
            val currentNumbers = getBlockedNumbersApi21To23().toMutableList()
            
            if (currentNumbers.remove(number)) {
                val jsonArray = JSONArray(currentNumbers)
                prefs.edit()
                    .putString(BLOCKED_NUMBERS_KEY, jsonArray.toString())
                    .apply()
                
                Timber.d("BlockedNumbersRepository.unblockNumber (API 21-23): $number unblocked")
            } else {
                Timber.w("BlockedNumbersRepository.unblockNumber: $number not in block list")
            }
        } catch (e: Exception) {
            Timber.e(e, "Error unblocking number via SharedPreferences")
        }
    }

    /**
     * Check if a number is blocked.
     */
    fun isBlocked(number: String): Boolean {
        return getBlockedNumbers().any { blocked ->
            blocked.contains(number) || number.contains(blocked)
        }
    }
}
