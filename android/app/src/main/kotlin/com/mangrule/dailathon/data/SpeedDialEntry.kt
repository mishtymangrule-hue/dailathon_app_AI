package com.mangrule.dailathon.data

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * SpeedDialEntry represents a speed dial shortcut (1-9).
 * Position 1 is reserved for voicemail.
 * Positions 2-9 can be assigned to contacts for quick dialing.
 */
@Entity(tableName = "speed_dial_entries")
data class SpeedDialEntry(
    @PrimaryKey
    val position: Int,  // 1-9 (1 = voicemail, 2-9 = quick dials)

    val contactId: String, // Contact ID from system contacts provider
    val displayName: String,  // Contact name for UI
    val phoneNumber: String,  // Actual number to dial
    val photoUri: String? = null,  // Optional contact photo

    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
) {
    init {
        require(position in 1..9) { "Speed dial position must be 1-9" }
    }

    fun isVoicemail(): Boolean = position == 1
}

/**
 * ContactFavorite marks a contact as a favorite (starred).
 * Shows in Contacts view and is available for speed dial assignment.
 */
@Entity(tableName = "contact_favorites")
data class ContactFavorite(
    @PrimaryKey
    val contactId: String,

    val isFavorite: Boolean = true,
    val displayName: String? = null,
    val phoneNumber: String? = null,
    val photoUri: String? = null,

    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
)
