package com.mady.wherewasi

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.TextView
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlin.math.max
import kotlin.math.min

/**
 * The small card that opens over the home screen when the plus button on the
 * widget is tapped while a book is being read. It shows the page the book is
 * on, with arrows to step one page at a time and a field to type a page. The
 * app itself is never opened.
 *
 * Saving writes the page into the data the widget draws from and refreshes the
 * widget. See WidgetStorage for how the app picks the change up.
 *
 * The colors come from the same palettes the widget uses, so the card matches
 * the widget, including when the widget theme is set to light or dark.
 */
class WidgetProgressActivity : Activity() {

    private var bookId = -1L
    private var originalPage = 0
    private var total = 0

    private lateinit var pageField: EditText

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val prefs = HomeWidgetPlugin.getData(this)
        bookId = intent.getLongExtra(EXTRA_BOOK_ID, -1L)
        val book = WidgetStorage.findBook(prefs, bookId)
        if (book == null) {
            finish()
            return
        }
        originalPage = book.page
        total = book.total

        setContentView(R.layout.ww_progress_dialog)
        bindViews(book)
        applyPalette(prefs)
    }

    private fun bindViews(book: WidgetStorage.BookEntry) {
        findViewById<View>(R.id.wp_root).setOnClickListener { finish() }

        val card = findViewById<View>(R.id.wp_card)
        val params = card.layoutParams as FrameLayout.LayoutParams
        params.width = cardWidthPx()
        card.layoutParams = params

        findViewById<TextView>(R.id.wp_title).text = book.title
        findViewById<TextView>(R.id.wp_total).text =
            if (total > 0) "of $total pages" else "current page"

        pageField = findViewById(R.id.wp_page)
        pageField.setText(originalPage.toString())
        pageField.setSelection(pageField.text.length)
        pageField.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                save()
                true
            } else {
                false
            }
        }

        findViewById<View>(R.id.wp_prev).setOnClickListener { step(-1) }
        findViewById<View>(R.id.wp_next).setOnClickListener { step(1) }
        findViewById<View>(R.id.wp_cancel).setOnClickListener { finish() }
        findViewById<View>(R.id.wp_save).setOnClickListener { save() }
    }

    /** The card is at most 320dp wide and always leaves room at both sides. */
    private fun cardWidthPx(): Int {
        val density = resources.displayMetrics.density
        val screen = resources.displayMetrics.widthPixels
        return min((MAX_CARD_WIDTH_DP * density).toInt(), screen - (2 * SIDE_MARGIN_DP * density).toInt())
    }

    private fun currentFieldValue(): Int = pageField.text.toString().toIntOrNull() ?: originalPage

    private fun clamp(page: Int): Int = if (total > 0) page.coerceIn(0, total) else max(0, page)

    private fun step(delta: Int) {
        val next = clamp(currentFieldValue() + delta)
        pageField.setText(next.toString())
        pageField.setSelection(pageField.text.length)
    }

    private fun save() {
        val prefs = HomeWidgetPlugin.getData(this)
        if (WidgetStorage.savePage(prefs, bookId, clamp(currentFieldValue()))) {
            refreshWidgets()
        }
        finish()
    }

    private fun refreshWidgets() {
        val manager = AppWidgetManager.getInstance(this)
        val ids = manager.getAppWidgetIds(ComponentName(this, WhereWasIWidgetProvider::class.java))
        sendBroadcast(
            Intent(this, WhereWasIWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            },
        )
    }

    /**
     * Light or dark follows the widget theme when it is set to one of them and
     * the phone is on Android 12 or newer, the same rule the widget follows.
     * Otherwise it follows the phone.
     */
    private fun isNight(prefs: SharedPreferences): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            when (prefs.getString(WidgetStorage.KEY_THEME_MODE, "system")) {
                "light" -> return false
                "dark" -> return true
            }
        }
        val mask = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        return mask == Configuration.UI_MODE_NIGHT_YES
    }

    private fun applyPalette(prefs: SharedPreferences) {
        val palette = if (isNight(prefs)) DARK_PALETTE else LIGHT_PALETTE

        fun tint(id: Int, color: Int) {
            findViewById<View>(id).backgroundTintList = ColorStateList.valueOf(color)
        }

        tint(R.id.wp_card, palette.background)
        tint(R.id.wp_prev, palette.button)
        tint(R.id.wp_next, palette.button)
        tint(R.id.wp_page, palette.track)
        tint(R.id.wp_cancel, palette.button)
        tint(R.id.wp_save, palette.primary)

        findViewById<TextView>(R.id.wp_title).setTextColor(palette.onSurface)
        findViewById<TextView>(R.id.wp_total).setTextColor(palette.muted)
        findViewById<TextView>(R.id.wp_prev).setTextColor(palette.onSurface)
        findViewById<TextView>(R.id.wp_next).setTextColor(palette.onSurface)
        findViewById<TextView>(R.id.wp_page).setTextColor(palette.onSurface)
        findViewById<TextView>(R.id.wp_cancel).setTextColor(palette.onSurface)
        findViewById<TextView>(R.id.wp_save).setTextColor(palette.onPrimary)
    }

    companion object {
        const val EXTRA_BOOK_ID = "com.mady.wherewasi.widget.BOOK_ID"

        private const val MAX_CARD_WIDTH_DP = 320f
        private const val SIDE_MARGIN_DP = 24f
    }
}
