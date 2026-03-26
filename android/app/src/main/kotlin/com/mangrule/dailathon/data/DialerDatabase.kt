package com.mangrule.dailathon.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [SpeedDialEntry::class, ContactFavorite::class],
    version = 1,
    exportSchema = false
)
abstract class DialerDatabase : RoomDatabase() {
    abstract fun speedDialDao(): SpeedDialDao
    abstract fun contactFavoriteDao(): ContactFavoriteDao

    companion object {
        @Volatile
        private var instance: DialerDatabase? = null

        fun getInstance(context: Context): DialerDatabase {
            return instance ?: synchronized(this) {
                Room.databaseBuilder(
                    context.applicationContext,
                    DialerDatabase::class.java,
                    "dialer_database"
                ).build().also { instance = it }
            }
        }
    }
}
