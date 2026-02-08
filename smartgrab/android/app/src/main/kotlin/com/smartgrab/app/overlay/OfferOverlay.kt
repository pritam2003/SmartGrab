package com.smartgrab.app.overlay

import android.content.Context
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView

class OfferOverlay(private val context: Context) {
    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val handler = Handler(Looper.getMainLooper())
    private var overlayView: View? = null
    private var removeRunnable: Runnable? = null

    fun show(message: String) {
        if (!Settings.canDrawOverlays(context)) return

        if (overlayView == null) {
            overlayView = buildView()
            windowManager.addView(overlayView, buildLayoutParams())
        }

        val messageView = overlayView?.findViewWithTag<TextView>(TAG_MESSAGE)
        messageView?.text = message

        removeRunnable?.let { handler.removeCallbacks(it) }
        removeRunnable = Runnable { remove() }
        handler.postDelayed(removeRunnable!!, DISPLAY_MS)
    }

    fun remove() {
        if (overlayView != null) {
            try {
                windowManager.removeView(overlayView)
            } catch (_: Exception) {
            }
            overlayView = null
        }
    }

    private fun buildView(): View {
        val container = LinearLayout(context)
        container.orientation = LinearLayout.VERTICAL
        container.setPadding(dp(16), dp(12), dp(16), dp(12))

        val background = GradientDrawable()
        background.cornerRadius = dp(12).toFloat()
        background.setColor(0xEE1A1A1A.toInt())
        container.background = background

        val title = TextView(context)
        title.text = "SmartGrab"
        title.setTextColor(0xFFFFFFFF.toInt())
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
        title.setTypeface(Typeface.DEFAULT_BOLD)

        val message = TextView(context)
        message.tag = TAG_MESSAGE
        message.text = ""
        message.setTextColor(0xFFE6E6E6.toInt())
        message.setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)

        container.addView(title)
        container.addView(message)

        return container
    }

    private fun buildLayoutParams(): WindowManager.LayoutParams {
        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.END
            x = dp(12)
            y = dp(120)
        }
    }

    private fun dp(value: Int): Int {
        val density = context.resources.displayMetrics.density
        return (value * density).toInt()
    }

    companion object {
        private const val DISPLAY_MS = 8000L
        private const val TAG_MESSAGE = "overlay_message"
    }
}
