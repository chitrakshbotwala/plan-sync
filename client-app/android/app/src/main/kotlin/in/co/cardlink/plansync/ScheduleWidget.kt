package `in`.co.cardlink.plansync

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.util.Calendar

/**
 * Home-screen widget showing today's class list. Each row is styled by the
 * device clock: the running class gets a raised green bar, past classes are
 * dimmed, upcoming classes are shown normally. Data is pushed from the Flutter
 * app (see HomeWidgetService) into the "scheduleData" key as JSON; this provider
 * only renders it. Tapping opens the app.
 */
class ScheduleWidget : HomeWidgetProvider() {

    private enum class RowState { PAST, CURRENT, UPCOMING }

    private val rowIds = intArrayOf(
        R.id.sched_row_0, R.id.sched_row_1, R.id.sched_row_2,
        R.id.sched_row_3, R.id.sched_row_4, R.id.sched_row_5,
    )
    private val nameIds = intArrayOf(
        R.id.sched_name_0, R.id.sched_name_1, R.id.sched_name_2,
        R.id.sched_name_3, R.id.sched_name_4, R.id.sched_name_5,
    )
    private val metaIds = intArrayOf(
        R.id.sched_meta_0, R.id.sched_meta_1, R.id.sched_meta_2,
        R.id.sched_meta_3, R.id.sched_meta_4, R.id.sched_meta_5,
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val onAccent = context.getColor(R.color.widget_on_accent)
        val onAccentDim = context.getColor(R.color.widget_on_accent_dim)
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
                val fallbackCurrent = obj.optInt("currentIndex", -1)
                val now = nowMinutes()
                for (i in rowIds.indices) {
                    val c = classes?.optJSONObject(i)
                    if (c == null) {
                        views.setViewVisibility(rowIds[i], View.GONE)
                        continue
                    }
                    views.setViewVisibility(rowIds[i], View.VISIBLE)
                    views.setTextViewText(nameIds[i], c.optString("name"))
                    views.setTextViewText(metaIds[i], c.optString("meta"))
                    when (rowState(c, now, i == fallbackCurrent)) {
                        RowState.CURRENT -> {
                            views.setInt(rowIds[i], "setBackgroundResource", R.drawable.row_current)
                            views.setTextColor(nameIds[i], onAccent)
                            views.setTextColor(metaIds[i], onAccentDim)
                        }
                        RowState.PAST -> {
                            views.setInt(rowIds[i], "setBackgroundResource", 0)
                            views.setTextColor(nameIds[i], muted)
                            views.setTextColor(metaIds[i], muted)
                        }
                        RowState.UPCOMING -> {
                            views.setInt(rowIds[i], "setBackgroundResource", 0)
                            views.setTextColor(nameIds[i], primary)
                            views.setTextColor(metaIds[i], secondary)
                        }
                    }
                }
                val overflow = obj.optInt("overflow", 0)
                if (overflow > 0) {
                    views.setViewVisibility(R.id.sched_overflow, View.VISIBLE)
                    views.setTextViewText(R.id.sched_overflow, "+$overflow more")
                } else {
                    views.setViewVisibility(R.id.sched_overflow, View.GONE)
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
     * Classifies a class row against the device clock from its start/end
     * (minutes since midnight). When the times can't be parsed, falls back to
     * the index the app flagged as current.
     */
    private fun rowState(c: JSONObject, now: Int, pushedCurrent: Boolean): RowState {
        val start = c.optInt("start", -1)
        val end = c.optInt("end", -1)
        if (start >= 0 && end >= 0 && end > start) {
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
