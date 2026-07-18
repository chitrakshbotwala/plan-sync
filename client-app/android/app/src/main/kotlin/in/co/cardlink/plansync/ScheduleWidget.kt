package `in`.co.cardlink.plansync

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * Home-screen widget showing a compact window of today's classes — the previous
 * class, the one running now, and the next — laid out like the app's timetable:
 * a start/end time column on the left and a subject card (name + room + duration)
 * on the right. The running class card is outlined green; the past card is
 * dimmed; the upcoming card is normal. Data is pushed from the Flutter app (see
 * HomeWidgetService); this provider only renders it. Tapping opens the app.
 */
class ScheduleWidget : HomeWidgetProvider() {

    private enum class RowState { PAST, CURRENT, UPCOMING }

    private val rowIds = intArrayOf(R.id.sched_row_0, R.id.sched_row_1, R.id.sched_row_2)
    private val cardIds = intArrayOf(R.id.sched_card_0, R.id.sched_card_1, R.id.sched_card_2)
    private val startIds = intArrayOf(R.id.sched_start_0, R.id.sched_start_1, R.id.sched_start_2)
    private val endIds = intArrayOf(R.id.sched_end_0, R.id.sched_end_1, R.id.sched_end_2)
    private val nameIds = intArrayOf(R.id.sched_name_0, R.id.sched_name_1, R.id.sched_name_2)
    private val roomIds = intArrayOf(R.id.sched_room_0, R.id.sched_room_1, R.id.sched_room_2)
    private val durIds = intArrayOf(R.id.sched_dur_0, R.id.sched_dur_1, R.id.sched_dur_2)

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val accent = context.getColor(R.color.widget_accent)
        val primary = context.getColor(R.color.widget_text_primary)
        val secondary = context.getColor(R.color.widget_text_secondary)
        val muted = context.getColor(R.color.widget_text_muted)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.schedule_widget)
            views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))
            views.setOnClickPendingIntent(R.id.refresh_button, refreshIntent(context, widgetId))

            val json = widgetData.getString("scheduleData", null)
            val obj = if (json != null) runCatching { JSONObject(json) }.getOrNull() else null
            val state = obj?.optString("widgetState", "loading") ?: "unconfigured"

            views.setViewVisibility(R.id.loading_state_layout, visIf(state == "loading"))
            views.setViewVisibility(R.id.empty_state_layout, visIf(state == "empty"))
            views.setViewVisibility(
                R.id.configuration_required_layout,
                visIf(state == "unconfigured"),
            )
            views.setViewVisibility(R.id.data_display_layout, visIf(state == "data"))

            if (state == "data" && obj != null) {
                val classes = obj.optJSONArray("classes")
                val now = nowMinutes()
                val fallbackCurrent = obj.optInt("currentIndex", -1)
                val window = windowIndices(classes, now, fallbackCurrent)
                for (k in rowIds.indices) {
                    val srcIdx = window.getOrNull(k) ?: -1
                    val c = if (srcIdx >= 0) classes?.optJSONObject(srcIdx) else null
                    if (c == null) {
                        views.setViewVisibility(rowIds[k], View.GONE)
                        continue
                    }
                    views.setViewVisibility(rowIds[k], View.VISIBLE)
                    views.setTextViewText(startIds[k], c.optString("startLabel"))
                    views.setTextViewText(endIds[k], c.optString("endLabel"))
                    views.setTextViewText(nameIds[k], c.optString("name"))
                    views.setTextViewText(roomIds[k], c.optString("room"))
                    views.setTextViewText(durIds[k], c.optString("duration"))

                    when (rowState(c, now, srcIdx == fallbackCurrent)) {
                        RowState.CURRENT -> {
                            views.setInt(cardIds[k], "setBackgroundResource", R.drawable.row_current)
                            views.setTextColor(nameIds[k], accent)
                            views.setTextColor(startIds[k], primary)
                            views.setTextColor(roomIds[k], secondary)
                            views.setTextColor(durIds[k], secondary)
                        }
                        RowState.PAST -> {
                            views.setInt(cardIds[k], "setBackgroundResource", R.drawable.row_card)
                            views.setTextColor(nameIds[k], muted)
                            views.setTextColor(startIds[k], muted)
                            views.setTextColor(roomIds[k], muted)
                            views.setTextColor(durIds[k], muted)
                        }
                        RowState.UPCOMING -> {
                            views.setInt(cardIds[k], "setBackgroundResource", R.drawable.row_card)
                            views.setTextColor(nameIds[k], primary)
                            views.setTextColor(startIds[k], primary)
                            views.setTextColor(roomIds[k], secondary)
                            views.setTextColor(durIds[k], secondary)
                        }
                    }
                    views.setTextColor(endIds[k], muted)
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun visIf(show: Boolean): Int = if (show) View.VISIBLE else View.GONE

    private fun nowMinutes(): Int {
        val cal = Calendar.getInstance()
        return cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
    }

    /**
     * Source indices to show (max 3): the previous class, the running class and
     * the next one. During a break, shows the just-finished and the upcoming
     * class; before the first class, only the next; after the last, only it.
     */
    private fun windowIndices(classes: JSONArray?, now: Int, fallbackCurrent: Int): List<Int> {
        if (classes == null || classes.length() == 0) return emptyList()
        val n = classes.length()

        var cur = -1
        for (i in 0 until n) {
            val c = classes.optJSONObject(i) ?: continue
            val s = c.optInt("start", -1)
            val e = c.optInt("end", -1)
            if (s >= 0 && e > s && now >= s && now < e) {
                cur = i
                break
            }
        }
        if (cur < 0 && fallbackCurrent in 0 until n) cur = fallbackCurrent
        if (cur >= 0) {
            return listOf(cur - 1, cur, cur + 1).filter { it in 0 until n }
        }

        var nextIdx = -1
        for (i in 0 until n) {
            val c = classes.optJSONObject(i) ?: continue
            if (c.optInt("start", -1).let { it >= 0 && it > now }) {
                nextIdx = i
                break
            }
        }
        if (nextIdx >= 0) {
            return listOf(nextIdx - 1, nextIdx).filter { it in 0 until n }
        }
        return listOf(n - 1) // all done → the most recent class
    }

    /**
     * Classifies a class row against the device clock from its start/end
     * (minutes since midnight). When times can't be parsed, falls back to the
     * index the app flagged as current.
     */
    private fun rowState(c: JSONObject, now: Int, pushedCurrent: Boolean): RowState {
        val start = c.optInt("start", -1)
        val end = c.optInt("end", -1)
        if (start >= 0 && end > start) {
            return when {
                now >= end -> RowState.PAST
                now in start until end -> RowState.CURRENT
                else -> RowState.UPCOMING
            }
        }
        return if (pushedCurrent) RowState.CURRENT else RowState.UPCOMING
    }

    // A broadcast back to this provider so the "refresh" button re-renders the
    // widget from the last data the app saved — restoring it if a background
    // process kill left it stale/blank.
    private fun refreshIntent(context: Context, widgetId: Int): PendingIntent {
        val intent = Intent(context, ScheduleWidget::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId))
        }
        return PendingIntent.getBroadcast(
            context,
            widgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    // Tap opens the app. Built directly (not via home_widget's helper, which
    // sets pendingIntentBackgroundActivityStartMode and crashes on newer
    // Android when targeting recent SDKs).
    private fun openAppIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
