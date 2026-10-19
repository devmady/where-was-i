package com.mady.wherewasi

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.ColorStateList
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.util.TypedValue
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
 * The colors used when the app is set to light or dark. They mirror the app
 * theme, and the same values live in the color resources that the widget uses
 * while the app is set to follow the phone.
 */
private class WidgetPalette(
    val background: Int,
    val onSurface: Int,
    val muted: Int,
    val primary: Int,
    val onPrimary: Int,
    val track: Int,
    val button: Int,
)

private val LIGHT_PALETTE = WidgetPalette(
    background = 0xFFF4F1EC.toInt(),
    onSurface = 0xFF1A1A1A.toInt(),
    muted = 0xFF6B6B6B.toInt(),
    primary = 0xFF0F6E56.toInt(),
    onPrimary = 0xFFFFFFFF.toInt(),
    track = 0xFFDDD7CC.toInt(),
    button = 0xFFE6E1D8.toInt(),
)

private val DARK_PALETTE = WidgetPalette(
    background = 0xFF212725.toInt(),
    onSurface = 0xFFF2F2F0.toInt(),
    muted = 0xFF9A9A97.toInt(),
    primary = 0xFF4FC9A6.toInt(),
    onPrimary = 0xFF0B2A22.toInt(),
    track = 0xFF353C39.toInt(),
    button = 0xFF2E3532.toInt(),
)

private val COVER_PLACEHOLDER_COLOR = 0xFF3D5A73.toInt()

/**
 * The Where Was I home screen widget. Shows one book at a time, the one being
 * read, with a progress bar. The up and down arrows step through every book
 * that is being read, most recently touched first, and wrap around at the
 * ends. Which book is showing is remembered here by book id, so the widget
 * does not jump back to the top after the arrows are used.
 *
 * The list of books comes from the Flutter app, which writes it as json each
 * time the library changes. Everything stays on the device.
 *
 * Sizing. The real width and height of the widget are measured each time it
 * is drawn. Three layouts exist, a narrow one, a wide short one and a large
 * one. The cover picture is drawn at exactly the size that is left over, so
 * nothing is cut off, and parts that do not fit are left out.
 *
 * Colors. While the app is set to follow the phone, the layouts take their
 * colors from the color resources, which switch with the phone. When the app
 * is set to light or dark, the matching palette is applied on top. That needs
 * Android 12 or newer, and older phones keep following the phone.
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

    /**
     * The widget size in dp. The smaller of the two reported values is used for
     * each side, so what is drawn fits in both portrait and landscape.
     */
    private fun widgetSizeDp(manager: AppWidgetManager, widgetId: Int): Pair<Float, Float> {
        val options = manager.getAppWidgetOptions(widgetId)
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        return Pair(
            if (width > 0) width.toFloat() else DEFAULT_DP,
            if (height > 0) height.toFloat() else DEFAULT_DP,
        )
    }

    private fun pickSize(widthDp: Float, heightDp: Float): WidgetSize {
        return when {
            widthDp < WIDE_MIN_WIDTH_DP -> WidgetSize.SMALL
            heightDp >= LARGE_MIN_HEIGHT_DP -> WidgetSize.LARGE
            else -> WidgetSize.MEDIUM
        }
    }

    private fun render(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        prefs: SharedPreferences,
    ) {
        val (widthDp, heightDp) = widgetSizeDp(manager, widgetId)
        val size = pickSize(widthDp, heightDp)
        val layout = when (size) {
            WidgetSize.SMALL -> R.layout.ww_widget_small
            WidgetSize.MEDIUM -> R.layout.ww_widget_medium
            WidgetSize.LARGE -> R.layout.ww_widget_large
        }
        val views = RemoteViews(context.packageName, layout)

        val books = readBooks(prefs)
        val index = currentIndex(prefs, books)
        val book = if (index >= 0) books[index] else null

        val coverBox = if (book != null) coverBoxFor(size, widthDp, heightDp) else null
        bindCover(context, views, book, coverBox)
        bindText(views, book, size, index, books.size, heightDp, widthDp, coverBox)

        val progress = ((book?.fraction ?: 0f) * 1000).roundToInt()
        views.setProgressBar(R.id.ww_progress, 1000, progress, false)

        forcedPalette(prefs)?.let { applyPalette(views, it, size) }

        bindClicks(context, views)
        manager.updateAppWidget(widgetId, views)
    }

    /**
     * How much room the cover picture gets, in dp, or null when there is no
     * room worth using. The numbers here mirror the fixed parts of each
     * layout file, so the picture fills exactly what is left over.
     */
    private fun coverBoxFor(size: WidgetSize, widthDp: Float, heightDp: Float): Pair<Float, Float>? {
        return when (size) {
            WidgetSize.SMALL -> {
                if (widthDp < SMALL_COVER_MIN_WIDTH_DP) {
                    null
                } else {
                    fitCover((widthDp - 16f) * 0.36f, heightDp - SMALL_FIXED_DP)
                }
            }

            WidgetSize.MEDIUM -> {
                fitCover(minOf(widthDp - MEDIUM_OTHER_WIDTH_DP, widthDp * 0.34f), heightDp - 24f)
            }

            WidgetSize.LARGE -> {
                fitCover(widthDp * 0.36f, heightDp - LARGE_FIXED_DP)
            }
        }
    }

    private fun fitCover(maxWidthDp: Float, maxHeightDp: Float): Pair<Float, Float>? {
        if (maxWidthDp < MIN_COVER_WIDTH_DP || maxHeightDp < MIN_COVER_HEIGHT_DP) return null
        val width = minOf(maxWidthDp, maxHeightDp * COVER_RATIO)
        val height = width / COVER_RATIO
        if (width < MIN_COVER_WIDTH_DP || height < MIN_COVER_HEIGHT_DP) return null
        return Pair(width, height)
    }

    private fun bindText(
        views: RemoteViews,
        book: WidgetBook?,
        size: WidgetSize,
        index: Int,
        count: Int,
        heightDp: Float,
        widthDp: Float,
        coverBox: Pair<Float, Float>?,
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

                val author = book?.author ?: ""
                val showAuthor = heightDp >= SMALL_AUTHOR_MIN_HEIGHT_DP && author.isNotBlank()
                views.setViewVisibility(R.id.ww_author, if (showAuthor) View.VISIBLE else View.GONE)
                if (showAuthor) {
                    views.setTextViewText(R.id.ww_author, author)
                }
            }

            WidgetSize.MEDIUM -> {
                views.setTextViewText(R.id.ww_author, book?.author ?: "")
                views.setTextViewText(R.id.ww_stat_left, pageOfTotal)
                views.setTextViewText(R.id.ww_stat_right, percentText)
            }

            WidgetSize.LARGE -> {
                // The width left for the text beside the cover decides how big
                // the page number can be and which caption fits.
                val textWidth = widthDp - 28f - (coverBox?.first ?: 0f) - 12f - 8f - 30f

                views.setTextViewText(R.id.ww_author, book?.author ?: "")
                views.setTextViewText(
                    R.id.ww_caption,
                    when {
                        book == null -> ""
                        textWidth < 100f -> "Left off"
                        else -> "Left off at page"
                    },
                )

                val pageText = if (book != null) "${book.page}" else "\u2013"
                val totalText = if (book != null && book.hasTotal) "of ${book.total}" else ""
                views.setTextViewText(R.id.ww_page_number, pageText)
                views.setTextViewText(R.id.ww_page_total, totalText)

                val totalWidth = if (totalText.isEmpty()) 0f else totalText.length * 7.5f + 6f
                val numberSize = ((textWidth - totalWidth) / (0.6f * pageText.length))
                    .coerceIn(18f, 34f)
                views.setTextViewTextSize(R.id.ww_page_number, TypedValue.COMPLEX_UNIT_SP, numberSize)

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

    /**
     * The palette to apply on top of the layout, or null while the app follows
     * the phone. Tinting a view from code needs Android 12, so older phones
     * always follow the phone.
     */
    private fun forcedPalette(prefs: SharedPreferences): WidgetPalette? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return null
        return when (prefs.getString(KEY_THEME_MODE, "system")) {
            "light" -> LIGHT_PALETTE
            "dark" -> DARK_PALETTE
            else -> null
        }
    }

    private fun applyPalette(views: RemoteViews, palette: WidgetPalette, size: WidgetSize) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return

        views.setColorStateList(
            R.id.ww_root,
            "setBackgroundTintList",
            ColorStateList.valueOf(palette.background),
        )
        views.setColorStateList(
            R.id.ww_btn_add,
            "setBackgroundTintList",
            ColorStateList.valueOf(palette.primary),
        )
        views.setColorStateList(
            R.id.ww_btn_prev,
            "setBackgroundTintList",
            ColorStateList.valueOf(palette.button),
        )
        views.setColorStateList(
            R.id.ww_btn_next,
            "setBackgroundTintList",
            ColorStateList.valueOf(palette.button),
        )
        views.setColorStateList(
            R.id.ww_progress,
            "setProgressTintList",
            ColorStateList.valueOf(palette.primary),
        )
        views.setColorStateList(
            R.id.ww_progress,
            "setProgressBackgroundTintList",
            ColorStateList.valueOf(palette.track),
        )

        views.setTextColor(R.id.ww_btn_add, palette.onPrimary)
        views.setTextColor(R.id.ww_title, palette.onSurface)
        views.setTextColor(R.id.ww_author, palette.muted)

        when (size) {
            WidgetSize.SMALL -> {
                views.setTextColor(R.id.ww_percent, palette.onSurface)
                views.setTextColor(R.id.ww_stat_left, palette.muted)
                views.setTextColor(R.id.ww_btn_prev, palette.muted)
                views.setTextColor(R.id.ww_btn_next, palette.muted)
            }

            WidgetSize.MEDIUM -> {
                views.setTextColor(R.id.ww_stat_left, palette.muted)
                views.setTextColor(R.id.ww_stat_right, palette.onSurface)
                views.setTextColor(R.id.ww_btn_prev, palette.muted)
                views.setTextColor(R.id.ww_btn_next, palette.muted)
            }

            WidgetSize.LARGE -> {
                views.setTextColor(R.id.ww_caption, palette.muted)
                views.setTextColor(R.id.ww_page_number, palette.onSurface)
                views.setTextColor(R.id.ww_page_total, palette.muted)
                views.setTextColor(R.id.ww_info_left, palette.muted)
                views.setTextColor(R.id.ww_info_right, palette.muted)
                views.setTextColor(R.id.ww_reading_count, palette.muted)
                views.setTextColor(R.id.ww_btn_prev, palette.onSurface)
                views.setTextColor(R.id.ww_btn_next, palette.onSurface)
            }
        }
    }

    private fun bindCover(
        context: Context,
        views: RemoteViews,
        book: WidgetBook?,
        coverBox: Pair<Float, Float>?,
    ) {
        if (book == null || coverBox == null) {
            views.setViewVisibility(R.id.ww_cover_image, View.GONE)
            return
        }

        val density = context.resources.displayMetrics.density
        val widthPx = max(1, (coverBox.first * density).roundToInt())
        val heightPx = max(1, (coverBox.second * density).roundToInt())

        val bitmap = loadCover(book.cover, widthPx, heightPx, density)
            ?: placeholderCover(book.title, widthPx, heightPx, density)

        views.setImageViewBitmap(R.id.ww_cover_image, bitmap)
        views.setViewVisibility(R.id.ww_cover_image, View.VISIBLE)
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
     * picture, so the colored placeholder with the title is drawn instead.
     */
    private fun loadCover(path: String, widthPx: Int, heightPx: Int, density: Float): Bitmap? {
        if (path.isBlank()) return null
        val file = File(path)
        if (!file.exists()) return null

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        var sample = 1
        while (bounds.outWidth / (sample * 2) >= widthPx &&
            bounds.outHeight / (sample * 2) >= heightPx
        ) {
            sample *= 2
        }

        val options = BitmapFactory.Options().apply { inSampleSize = sample }
        val source = BitmapFactory.decodeFile(path, options) ?: return null
        return roundedCenterCrop(source, widthPx, heightPx, 6f * density)
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

    /**
     * Draws the placeholder cover, a colored rounded rectangle with the book
     * title in white, at exactly the size it will be shown at.
     */
    private fun placeholderCover(title: String, width: Int, height: Int, density: Float): Bitmap {
        val output = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val radius = 6f * density

        val fill = Paint(Paint.ANTI_ALIAS_FLAG)
        fill.color = COVER_PLACEHOLDER_COLOR
        canvas.drawRoundRect(RectF(0f, 0f, width.toFloat(), height.toFloat()), radius, radius, fill)

        val padding = width * 0.1f
        val textWidth = (width - 2f * padding).roundToInt()
        if (title.isBlank() || textWidth < 8) return output

        val paint = TextPaint(Paint.ANTI_ALIAS_FLAG)
        paint.color = Color.WHITE
        paint.typeface = Typeface.DEFAULT_BOLD
        paint.textSize = max(7f * density, width * 0.11f)

        @Suppress("DEPRECATION")
        val textLayout = StaticLayout(
            title,
            paint,
            textWidth,
            Layout.Alignment.ALIGN_NORMAL,
            1f,
            0f,
            false,
        )

        canvas.save()
        canvas.clipRect(padding, padding, width - padding, height - padding)
        canvas.translate(padding, padding)
        textLayout.draw(canvas)
        canvas.restore()
        return output
    }

    private companion object {
        const val ACTION_PREVIOUS = "com.mady.wherewasi.widget.PREVIOUS"
        const val ACTION_NEXT = "com.mady.wherewasi.widget.NEXT"

        const val KEY_BOOKS = "books_json"
        const val KEY_CURRENT_BOOK = "widget_current_book_id"
        const val KEY_THEME_MODE = "widget_theme_mode"

        const val OPEN_URI = "wherewasi://open"
        const val ADD_BOOK_URI = "wherewasi://add-book"

        // Used until the launcher reports a real size.
        const val DEFAULT_DP = 160f

        // Narrower than this uses the narrow layout. Wider and shorter than
        // the large height uses the wide layout, and wider and taller uses
        // the large layout.
        const val WIDE_MIN_WIDTH_DP = 210f
        const val LARGE_MIN_HEIGHT_DP = 230f

        // Narrow layout. The fixed height is the padding, the progress bar and
        // the bottom row. The cover is only shown when there is room beside it.
        const val SMALL_FIXED_DP = 55f
        const val SMALL_COVER_MIN_WIDTH_DP = 150f
        const val SMALL_AUTHOR_MIN_HEIGHT_DP = 135f

        // Wide layout. This is everything in the width except the cover and
        // the title column, plus a title column that is still readable.
        const val MEDIUM_OTHER_WIDTH_DP = 162f

        // Large layout. The fixed height is the padding, the progress bar, the
        // info row and the bottom row.
        const val LARGE_FIXED_DP = 114f

        // Cover shape, the same as the cover pictures in the app.
        const val COVER_RATIO = 120f / 174f
        const val MIN_COVER_WIDTH_DP = 26f
        const val MIN_COVER_HEIGHT_DP = 38f
    }
}
