package com.mady.wherewasi

import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.max

/**
 * The keys of the data that the Flutter app and the widget share, and the one
 * place that changes a page from the widget side.
 *
 * A page changed from the widget is written to the list of books the widget
 * draws from, so the widget shows it at once. The same change is also queued
 * with the time it was made, and the app writes it into its own records the
 * next time it opens or comes to the front. Nothing leaves the device.
 */
internal object WidgetStorage {
    const val KEY_BOOKS = "books_json"
    const val KEY_CURRENT_BOOK = "widget_current_book_id"
    const val KEY_THEME_MODE = "widget_theme_mode"
    const val KEY_PENDING_PROGRESS = "pending_progress_json"

    class BookEntry(
        val id: Long,
        val title: String,
        val page: Int,
        val total: Int,
    )

    fun findBook(prefs: SharedPreferences, bookId: Long): BookEntry? {
        val raw = prefs.getString(KEY_BOOKS, null) ?: return null
        return try {
            val books = JSONArray(raw)
            var found: BookEntry? = null
            for (i in 0 until books.length()) {
                val book = books.getJSONObject(i)
                if (book.getLong("id") == bookId) {
                    found = BookEntry(
                        id = bookId,
                        title = book.optString("title"),
                        page = book.optInt("page"),
                        total = book.optInt("total"),
                    )
                    break
                }
            }
            found
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Sets the page of one book. The page is kept between zero and the last
     * page when the total is known. Returns false when nothing changed.
     */
    fun savePage(prefs: SharedPreferences, bookId: Long, page: Int): Boolean {
        val raw = prefs.getString(KEY_BOOKS, null) ?: return false
        return try {
            val books = JSONArray(raw)
            var changed = false
            for (i in 0 until books.length()) {
                val book = books.getJSONObject(i)
                if (book.getLong("id") != bookId) continue

                val total = book.optInt("total")
                val next = if (total > 0) page.coerceIn(0, total) else max(0, page)
                if (next == book.optInt("page")) break

                book.put("page", next)
                val pending = readPending(prefs)
                pending.put(
                    JSONObject()
                        .put("id", bookId)
                        .put("page", next)
                        .put("at", System.currentTimeMillis()),
                )
                prefs.edit()
                    .putString(KEY_BOOKS, books.toString())
                    .putString(KEY_PENDING_PROGRESS, pending.toString())
                    .apply()
                changed = true
                break
            }
            changed
        } catch (e: Exception) {
            false
        }
    }

    private fun readPending(prefs: SharedPreferences): JSONArray {
        val raw = prefs.getString(KEY_PENDING_PROGRESS, null) ?: return JSONArray()
        return try {
            JSONArray(raw)
        } catch (e: Exception) {
            JSONArray()
        }
    }
}
