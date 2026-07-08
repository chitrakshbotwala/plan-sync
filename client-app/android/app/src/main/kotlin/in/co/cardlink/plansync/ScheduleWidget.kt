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
 * Home-screen widget showing today's class list (the currently-running class is
 * marked). Data is pushed from the Flutter app (see HomeWidgetService) into the
 * "scheduleData" key as JSON; this provider only renders it. Tapping the widget
 * opens the app.
 */
class ScheduleWidget : HomeWidgetProvider() {

    private val rowIds = intArrayOf(
        R.id.sched_row_0, R.id.sched_row_1, R.id.sched_row_2,
        R.id.sched_row_3, R.id.sched_row_4, R.id.sched_row_5,
    )
    private val dotIds = intArrayOf(
        R.id.sched_dot_0, R.id.sched_dot_1, R.id.sched_dot_2,
        R.id.sched_dot_3, R.id.sched_dot_4, R.id.sched_dot_5,
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
        val accent = context.getColor(R.color.widget_accent)
        val primary = context.getColor(R.color.widget_text_primary)

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
                val currentIndex = currentClassIndex(obj, classes)
                for (i in rowIds.indices) {
                    val c = classes?.optJSONObject(i)
                    if (c != null) {
                        views.setViewVisibility(rowIds[i], View.VISIBLE)
                        views.setTextViewText(nameIds[i], c.optString("name"))
                        views.setTextViewText(metaIds[i], c.optString("meta"))
                        val isCurrent = i == currentIndex
                        views.setViewVisibility(dotIds[i], visIf(isCurrent))
                        views.setTextColor(nameIds[i], if (isCurrent) accent else primary)
                    } else {
                        views.setViewVisibility(rowIds[i], View.GONE)
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

    /**
     * Index of the currently-running class. Recomputed from each class's
     * start/end (minutes since midnight) against the device clock, so a manual
     * refresh or the periodic tick keeps the highlight correct even while the
     * app is closed. Falls back to the index the app pushed when the times
     * can't be parsed.
     */
    private fun currentClassIndex(obj: JSONObject, classes: org.json.JSONArray?): Int {
        if (classes == null) return -1
        val cal = Calendar.getInstance()
        val now = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
        var hasTimes = false
        for (i in 0 until classes.length()) {
            val c = classes.optJSONObject(i) ?: continue
            val start = c.optInt("start", -1)
            val end = c.optInt("end", -1)
            if (start >= 0 && end >= 0) {
                hasTimes = true
                if (now in start until end) return i
            }
        }
        return if (hasTimes) -1 else obj.optInt("currentIndex", -1)
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
