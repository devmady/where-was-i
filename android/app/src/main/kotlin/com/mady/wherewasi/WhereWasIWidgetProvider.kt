package com.mady.wherewasi

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.io.File
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * The Where Was I home screen widget. Shows one book at a time, the one being
 * read, with a progress bar. The up and down arrows step through every book
 * that is being read, most recently touched first, and wrap around at the
 * ends. Which book is showing is remembered here by book id, so the widget
 * does not jump back to the top after the arrows are used.
 *
 * The list of books comes from the Flutter app, which writes it as json each
 * time the library changes. Everything stays on the device.
 */
class WhereWasIWidgetProvider : HomeWidgetProvider() {

    private enum class WidgetSize { SMALL, MEDIUM, LARGE }

    private data class WidgetBook(
        val id: Long,
        val title: String,
        val author: String,
        val page: Int,
        val total: Int,
        val cover: String,
    ) {
        val hasTotal: Boolean
            get() = total > 0

        val fraction: Float
            get() = if (total > 0) (page.toFloat() / total).coerceIn(0f, 1f) else 0f

        val percent: Int
            get() = (fraction * 100).roundToInt()
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            render(context, appWidgetManager, id, widgetData)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        render(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context))
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_PREVIOUS -> stepAndRefresh(context, -1)
            ACTION_NEXT -> stepAndRefresh(context, 1)
            else -> super.onReceive(context, intent)
        }
    }

    private fun stepAndRefresh(context: Context, delta: Int) {
        val prefs = HomeWidgetPlugin.getData(context)
        val books = readBooks(prefs)
        if (books.isEmpty()) return

        val current = currentIndex(prefs, books)
        val next = ((current + delta) % books.size + books.size) % books.size
        prefs.edit().putLong(KEY_CURRENT_BOOK, books[next].id).apply()

        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, WhereWasIWidgetProvider::class.java),
        )
        for (id in ids) {
            render(context, manager, id, prefs)
        }
    }

    private fun readBooks(prefs: SharedPreferences): List<WidgetBook> {
        val raw = prefs.getString(KEY_BOOKS, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { i ->
                val o = array.getJSONObject(i)
                WidgetBook(
                    id = o.getLong("id"),
                    title = o.optString("title"),
                    author = o.optString("author"),
                    page = o.optInt("page"),
                    total = o.optInt("total"),
                    cover = o.optString("cover"),
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun currentIndex(prefs: SharedPreferences, books: List<WidgetBook>): Int {
        if (books.isEmpty()) return -1
        val savedId = prefs.getLong(KEY_CURRENT_BOOK, -1L)
        val index = books.indexOfFirst { it.id == savedId }
        return if (index >= 0) index else 0
    }

    private fun pickSize(manager: AppWidgetManager, widgetId: Int): WidgetSize {
        val options = manager.getAppWidgetOptions(widgetId)
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        val wide = width >= WIDE_DP
        val tall = height >= TALL_DP
        return when {
            wide && tall -> WidgetSize.LARGE
            wide -> WidgetSize.MEDIUM
            else -> WidgetSize.SMALL
        }
    }

    private fun render(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        prefs: SharedPreferences,
    ) {
        val size = pickSize(manager, widgetId)
        val layout = when (size) {
            WidgetSize.SMALL -> R.layout.ww_widget_small
            WidgetSize.MEDIUM -> R.layout.ww_widget_medium
            WidgetSize.LARGE -> R.layout.ww_widget_large
        }
        val views = RemoteViews(context.packageName, layout)

        val books = readBooks(prefs)
        val index = currentIndex(prefs, books)
        val book = if (index >= 0) books[index] else null

        bindCover(context, views, book, size)
        bindText(views, book, size, index, books.size)

        val progress = ((book?.fraction ?: 0f) * 1000).roundToInt()
        views.setProgressBar(R.id.ww_progress, 1000, progress, false)

        bindClicks(context, views)
        manager.updateAppWidget(widgetId, views)
    }

    private fun bindText(
        views: RemoteViews,
        book: WidgetBook?,
        size: WidgetSize,
        index: Int,
        count: Int,
    ) {
        val title = book?.title ?: "Nothing in progress"
        views.setTextViewText(R.id.ww_title, title)

        val pageOnly = if (book != null) "pg ${book.page}" else "Tap + to add a book"
        val pageOfTotal = when {
            book == null -> "Tap + to add a book"
            book.hasTotal -> "pg ${book.page} of ${book.total}"
            else -> "pg ${book.page}"
        }
        val percentText = if (book != null && book.hasTotal) "${book.percent}%" else ""

        when (size) {
            WidgetSize.SMALL -> {
                views.setTextViewText(R.id.ww_percent, percentText)
                val left = if (book != null && book.hasTotal) {
                    "pg ${book.page} / ${book.total}"
                } else {
                    pageOnly
                }
                views.setTextViewText(R.id.ww_stat_left, left)
            }

            WidgetSize.MEDIUM -> {
                views.setTextViewText(R.id.ww_author, book?.author ?: "")
                views.setTextViewText(R.id.ww_stat_left, pageOfTotal)
                views.setTextViewText(R.id.ww_stat_right, percentText)
            }

            WidgetSize.LARGE -> {
                views.setTextViewText(R.id.ww_author, book?.author ?: "")
                views.setTextViewText(
                    R.id.ww_caption,
                    if (book != null) "Left off at page" else "",
                )
                views.setTextViewText(
                    R.id.ww_page_number,
                    if (book != null) "${book.page}" else "\u2013",
                )
                views.setTextViewText(
                    R.id.ww_page_total,
                    if (book != null && book.hasTotal) "of ${book.total}" else "",
                )
                views.setTextViewText(
                    R.id.ww_info_left,
                    if (book != null && book.hasTotal) "${book.percent}% read" else "",
                )
                views.setTextViewText(
                    R.id.ww_info_right,
                    if (book != null && book.hasTotal) {
                        "${max(0, book.total - book.page)} pages left"
                    } else {
                        ""
                    },
                )
                views.setTextViewText(
                    R.id.ww_reading_count,
                    if (book != null) "Reading \u00B7 ${index + 1} of $count" else "No books in reading",
                )
            }
        }
    }

    private fun bindCover(
        context: Context,
        views: RemoteViews,
        book: WidgetBook?,
        size: WidgetSize,
    ) {
        val dims = when (size) {
            WidgetSize.SMALL -> Pair(38, 54)
            WidgetSize.MEDIUM -> Pair(72, 104)
            WidgetSize.LARGE -> Pair(120, 174)
        }
        val bitmap = book?.let { loadCover(context, it.cover, dims.first, dims.second) }

        if (bitmap != null) {
            views.setImageViewBitmap(R.id.ww_cover_image, bitmap)
            views.setViewVisibility(R.id.ww_cover_image, View.VISIBLE)
            views.setViewVisibility(R.id.ww_cover_title, View.GONE)
        } else {
            views.setViewVisibility(R.id.ww_cover_image, View.GONE)
            views.setViewVisibility(R.id.ww_cover_title, View.VISIBLE)
            views.setTextViewText(R.id.ww_cover_title, book?.title ?: "")
        }
    }

    private fun bindClicks(context: Context, views: RemoteViews) {
        views.setOnClickPendingIntent(
            R.id.ww_root,
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse(OPEN_URI),
            ),
        )
        views.setOnClickPendingIntent(
            R.id.ww_btn_add,
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse(ADD_BOOK_URI),
            ),
        )
        views.setOnClickPendingIntent(
            R.id.ww_btn_prev,
            broadcast(context, ACTION_PREVIOUS, 1),
        )
        views.setOnClickPendingIntent(
            R.id.ww_btn_next,
            broadcast(context, ACTION_NEXT, 2),
        )
    }

    private fun broadcast(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, WhereWasIWidgetProvider::class.java).apply {
            this.action = action
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * Loads a saved cover picture, shrunk to about the size it is shown at and
     * cropped to fill with rounded corners. Returns null when there is no
     * picture, so the colored placeholder with the title shows instead.
     */
    private fun loadCover(context: Context, path: String, widthDp: Int, heightDp: Int): Bitmap? {
        if (path.isBlank()) return null
        val file = File(path)
        if (!file.exists()) return null

        val density = context.resources.displayMetrics.density
        val targetWidth = max(1, (widthDp * density).roundToInt())
        val targetHeight = max(1, (heightDp * density).roundToInt())

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        var sample = 1
        while (bounds.outWidth / (sample * 2) >= targetWidth &&
            bounds.outHeight / (sample * 2) >= targetHeight
        ) {
            sample *= 2
        }

        val options = BitmapFactory.Options().apply { inSampleSize = sample }
        val source = BitmapFactory.decodeFile(path, options) ?: return null
        return roundedCenterCrop(source, targetWidth, targetHeight, 6f * density)
    }

    private fun roundedCenterCrop(source: Bitmap, width: Int, height: Int, radius: Float): Bitmap {
        val output = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        canvas.drawRoundRect(RectF(0f, 0f, width.toFloat(), height.toFloat()), radius, radius, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)

        val scale = max(width.toFloat() / source.width, height.toFloat() / source.height)
        val scaledWidth = source.width * scale
        val scaledHeight = source.height * scale
        val left = (width - scaledWidth) / 2f
        val top = (height - scaledHeight) / 2f
        canvas.drawBitmap(source, null, RectF(left, top, left + scaledWidth, top + scaledHeight), paint)

        source.recycle()
        return output
    }

    private companion object {
        const val ACTION_PREVIOUS = "com.mady.wherewasi.widget.PREVIOUS"
        const val ACTION_NEXT = "com.mady.wherewasi.widget.NEXT"

        const val KEY_BOOKS = "books_json"
        const val KEY_CURRENT_BOOK = "widget_current_book_id"

        const val OPEN_URI = "wherewasi://open"
        const val ADD_BOOK_URI = "wherewasi://add-book"

        const val WIDE_DP = 220
        const val TALL_DP = 220
    }
}
