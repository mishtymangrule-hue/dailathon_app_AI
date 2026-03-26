package com.mangrule.dailathon.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface SpeedDialDao {
    /**
     * Get speed dial entry by position (1-9).
     */
    @Query("SELECT * FROM speed_dial_entries WHERE position = :position")
    suspend fun getByPosition(position: Int): SpeedDialEntry?

    /**
     * Get all speed dial entries sorted by position.
     */
    @Query("SELECT * FROM speed_dial_entries ORDER BY position ASC")
    fun getAllSpeedDials(): Flow<List<SpeedDialEntry>>

    /**
     * Insert or update a speed dial entry.
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdate(entry: SpeedDialEntry)

    /**
     * Update an existing speed dial entry.
     */
    @Update
    suspend fun update(entry: SpeedDialEntry)

    /**
     * Delete a speed dial entry.
     */
    @Delete
    suspend fun delete(entry: SpeedDialEntry)

    /**
     * Delete speed dial entry by position.
     */
    @Query("DELETE FROM speed_dial_entries WHERE position = :position")
    suspend fun deleteByPosition(position: Int)

    /**
     * Check if a position has an assignment.
     */
    @Query("SELECT EXISTS(SELECT 1 FROM speed_dial_entries WHERE position = :position)")
    suspend fun hasAssignment(position: Int): Boolean

    /**
     * Get all positions that have assignments (for quick lookup).
     */
    @Query("SELECT position FROM speed_dial_entries ORDER BY position ASC")
    suspend fun getAssignedPositions(): List<Int>

    /**
     * Clear all speed dial assignments except voicemail.
     */
    @Query("DELETE FROM speed_dial_entries WHERE position > 1")
    suspend fun clearAllExceptVoicemail()

    /**
     * Setup default voicemail entry (optional).
     */
    suspend fun setVoicemail(contactId: String, displayName: String, number: String, photoUri: String? = null) {
        insertOrUpdate(SpeedDialEntry(
            position = 1,
            contactId = contactId,
            displayName = displayName,
            phoneNumber = number,
            photoUri = photoUri,
        ))
    }
}

@Dao
interface ContactFavoriteDao {
    /**
     * Get favorite contact by ID.
     */
    @Query("SELECT * FROM contact_favorites WHERE contactId = :contactId")
    suspend fun getById(contactId: String): ContactFavorite?

    /**
     * Get all favorite contacts.
     */
    @Query("SELECT * FROM contact_favorites WHERE isFavorite = 1 ORDER BY displayName ASC")
    fun getAllFavorites(): Flow<List<ContactFavorite>>

    /**
     * Mark contact as favorite.
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun addFavorite(favorite: ContactFavorite)

    /**
     * Remove contact from favorites.
     */
    @Query("DELETE FROM contact_favorites WHERE contactId = :contactId")
    suspend fun removeFavorite(contactId: String)

    /**
     * Check if contact is favorited.
     */
    @Query("SELECT EXISTS(SELECT 1 FROM contact_favorites WHERE contactId = :contactId AND isFavorite = 1)")
    suspend fun isFavorite(contactId: String): Boolean

    /**
     * Get all favorite contact IDs.
     */
    @Query("SELECT contactId FROM contact_favorites WHERE isFavorite = 1")
    suspend fun getFavoriteIds(): List<String>
}
