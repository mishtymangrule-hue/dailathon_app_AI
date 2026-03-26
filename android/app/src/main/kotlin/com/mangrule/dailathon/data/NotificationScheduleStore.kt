package com.mangrule.dailathon.data

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Lightweight SharedPreferences-backed store for pending notification schedules.
 *
 * The Flutter side writes to this store (via MethodChannel or WorkManager input data)
 * so that [RescheduleAlarmsWorker] can restore alarms after reboot without
 * needing to contact the CRM API.
 */
object NotificationScheduleStore {

    private const val PREFS_NAME = "notification_schedule"
    private const val KEY_ITEMS = "items"

    data class ScheduledItem(
        val id: String,
        val scheduledAtMillis: Long,
        val title: String,
        val body: String,
        val phoneNumber: String?,
    )

    fun getPending(context: Context): List<ScheduledItem> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val json = prefs.getString(KEY_ITEMS, "[]") ?: "[]"
        val array = runCatching { JSONArray(json) }.getOrDefault(JSONArray())
        val now = System.currentTimeMillis()
        val items = mutableListOf<ScheduledItem>()
        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            val scheduledAt = obj.getLong("scheduledAt")
            // Only return future items
            if (scheduledAt > now) {
                items.add(
                    ScheduledItem(
                        id = obj.getString("id"),
                        scheduledAtMillis = scheduledAt,
                        title = obj.getString("title"),
                        body = obj.getString("body"),
                        phoneNumber = obj.optString("phoneNumber").ifEmpty { null },
                    )
                )
            }
        }
        return items
    }

    fun save(context: Context, items: List<ScheduledItem>) {
        val array = JSONArray()
        for (item in items) {
            array.put(JSONObject().apply {
                put("id", item.id)
                put("scheduledAt", item.scheduledAtMillis)
                put("title", item.title)
                put("body", item.body)
                if (item.phoneNumber != null) put("phoneNumber", item.phoneNumber)
            })
        }
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_ITEMS, array.toString())
            .apply()
    }
}
