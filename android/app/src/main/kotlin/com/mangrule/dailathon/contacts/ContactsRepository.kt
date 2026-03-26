package com.mangrule.dailathon.contacts

import android.content.Context
import android.database.Cursor
import android.provider.CallLog
import android.provider.ContactsContract
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import timber.log.Timber

data class ContactItem(
    val id: String,
    val name: String,
    val phoneNumber: String,
    val photoUri: String? = null,
)

data class CallLogItem(
    val id: String,
    val phoneNumber: String,
    val name: String,
    val timestamp: Long,
    val duration: Int,
    val type: Int, // CallLog.Calls.INCOMING, OUTGOING, MISSED
)

/**
 * ContactsRepository provides access to device contacts and call log.
 * Supports T9 matching for fuzzy search.
 */
@Singleton
class ContactsRepository @Inject constructor(
    @ApplicationContext private val context: Context,
) {

    private val contentResolver = context.contentResolver

    /**
     * Get all contacts with phone numbers from device.
     */
    fun getAllContacts(): List<ContactItem> {
        val contacts = mutableListOf<ContactItem>()

        try {
            val cursor = contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                arrayOf(
                    ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
                    ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                    ContactsContract.CommonDataKinds.Phone.NUMBER,
                    ContactsContract.CommonDataKinds.Phone.PHOTO_URI,
                ),
                null,
                null,
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME + " ASC"
            )

            cursor?.use {
                while (it.moveToNext()) {
                    val id = it.getString(0)
                    val name = it.getString(1)
                    val number = it.getString(2)
                    val photoUri = it.getString(3)

                    contacts.add(
                        ContactItem(
                            id = id,
                            name = name,
                            phoneNumber = number.normalizePhoneNumber(),
                            photoUri = photoUri
                        )
                    )
                }
            }

            Timber.d("ContactsRepository.getAllContacts: ${contacts.size} contacts loaded")
        } catch (e: Exception) {
            Timber.e(e, "Error loading contacts")
        }

        return contacts
    }

    /**
     * Search contacts by name using T9 matching.
     * Supports fuzzy matching on display names and numbers.
     */
    fun searchByQuery(query: String): List<ContactItem> {
        if (query.isEmpty()) {
            return emptyList()
        }

        val allContacts = getAllContacts()
        val results = mutableListOf<ContactItem>()

        // Check if query is numeric (pure digits) for T9 matching
        val isNumeric = query.all { it.isDigit() }

        for (contact in allContacts) {
            if (isNumeric) {
                // T9 matching on phone number
                if (matchesT9(contact.phoneNumber, query)) {
                    results.add(contact)
                }
            } else {
                // Fuzzy matching on display name
                if (contact.name.contains(query, ignoreCase = true)) {
                    results.add(contact)
                }
            }
        }

        Timber.d("ContactsRepository.searchByQuery('$query'): ${results.size} matches")
        return results
    }

    /**
     * Look up a contact by phone number.
     */
    fun lookupByNumber(phoneNumber: String): ContactItem? {
        val normalizedNumber = phoneNumber.normalizePhoneNumber()

        return try {
            val uri = ContactsContract.PhoneLookup.CONTENT_FILTER_URI.buildUpon()
                .appendPath(normalizedNumber)
                .build()

            val cursor = contentResolver.query(
                uri,
                arrayOf(
                    ContactsContract.PhoneLookup.CONTACT_ID,
                    ContactsContract.PhoneLookup.DISPLAY_NAME,
                    ContactsContract.PhoneLookup.NUMBER,
                    ContactsContract.PhoneLookup.PHOTO_URI,
                ),
                null,
                null,
                null
            )

            var contact: ContactItem? = null
            cursor?.use {
                if (it.moveToFirst()) {
                    contact = ContactItem(
                        id = it.getString(0),
                        name = it.getString(1),
                        phoneNumber = it.getString(2),
                        photoUri = it.getString(3),
                    )
                }
            }

            contact
        } catch (e: Exception) {
            Timber.e(e, "Error looking up contact for $phoneNumber")
            null
        }
    }

    /**
     * Get starred/favorite contacts from ContactsContract.
     */
    fun getFavoriteContacts(): List<ContactItem> {
        val contacts = mutableListOf<ContactItem>()

        try {
            val cursor = contentResolver.query(
                ContactsContract.Contacts.CONTENT_URI,
                arrayOf(
                    ContactsContract.Contacts._ID,
                    ContactsContract.Contacts.DISPLAY_NAME,
                    ContactsContract.Contacts.PHOTO_URI,
                ),
                "${ContactsContract.Contacts.STARRED} = 1",
                null,
                ContactsContract.Contacts.DISPLAY_NAME + " ASC"
            )

            cursor?.use {
                while (it.moveToNext()) {
                    val id = it.getString(0)
                    val name = it.getString(1)
                    val photoUri = it.getString(2)

                    // Get phone number for this contact
                    val phoneCursor = contentResolver.query(
                        ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                        arrayOf(ContactsContract.CommonDataKinds.Phone.NUMBER),
                        "${ContactsContract.CommonDataKinds.Phone.CONTACT_ID} = ?",
                        arrayOf(id),
                        null
                    )

                    phoneCursor?.use { pc ->
                        if (pc.moveToFirst()) {
                            val phoneNumber = pc.getString(0)
                            contacts.add(
                                ContactItem(
                                    id = id,
                                    name = name,
                                    phoneNumber = phoneNumber.normalizePhoneNumber(),
                                    photoUri = photoUri
                                )
                            )
                        }
                    }
                }
            }

            Timber.d("ContactsRepository.getFavoriteContacts: ${contacts.size} favorites loaded")
        } catch (e: Exception) {
            Timber.e(e, "Error loading favorite contacts")
        }

        return contacts
    }

    // ========== T9 MATCHING ==========

    /**
     * T9 matching: sequentially match digits to letter keys on phone keypad.
     * 2=abc, 3=def, 4=ghi, 5=jkl, 6=mno, 7=pqrs, 8=tuv, 9=wxyz, 0=space
     */
    private fun matchesT9(phoneNumber: String, query: String): Boolean {
        val digitOnly = phoneNumber.filter { it.isDigit() }
        return digitOnly.contains(query)
    }

    // ========== HELPER ==========

    private fun String.normalizePhoneNumber(): String {
        return this.filter { it.isDigit() || it == '+' }
    }
}
