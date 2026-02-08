package com.smartgrab.app.accessibility

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import com.smartgrab.app.notify.OfferNotifier
import com.smartgrab.app.offers.DecisionEngine
import com.smartgrab.app.offers.GigApp
import com.smartgrab.app.offers.OfferParser
import com.smartgrab.app.overlay.OfferOverlay

class OfferAccessibilityService : AccessibilityService() {
    private lateinit var notifier: OfferNotifier
    private lateinit var overlay: OfferOverlay

    private var lastRecommendation: String? = null
    private var lastRecommendationTime = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        notifier = OfferNotifier(this)
        overlay = OfferOverlay(this)

        val info = serviceInfo ?: AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
            AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        info.notificationTimeout = 300
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return
        if (!SUPPORTED_PACKAGES.contains(packageName)) return

        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ONLINE, false)) return

        val root = rootInActiveWindow ?: return
        val texts = mutableListOf<String>()
        collectText(root, texts)

        val offer = OfferParser.parse(packageName, texts) ?: return
        if (offer.app == GigApp.UNKNOWN) return

        val decision = DecisionEngine.evaluate(this, offer)
        if (!decision.shouldAccept) return

        val payText = String.format("%.2f", offer.pay)
        val distanceText = String.format("%.1f", offer.distanceKm)
        val message = "Accept \\$$payText • $distanceText km • ${offer.app.displayName}"
        if (!shouldNotify(message)) return

        saveRecommendation(message)
        notifier.showRecommendation(message)
        overlay.show(message)
    }

    override fun onInterrupt() {
        overlay.remove()
    }

    private fun collectText(node: AccessibilityNodeInfo, sink: MutableList<String>) {
        val text = node.text?.toString()?.trim()
        if (!text.isNullOrBlank()) {
            sink.add(text)
        }

        val content = node.contentDescription?.toString()?.trim()
        if (!content.isNullOrBlank()) {
            sink.add(content)
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            collectText(child, sink)
        }
    }

    private fun shouldNotify(message: String): Boolean {
        val now = SystemClock.elapsedRealtime()
        if (message == lastRecommendation && now - lastRecommendationTime < MIN_REPEAT_MS) {
            return false
        }
        lastRecommendation = message
        lastRecommendationTime = now
        return true
    }

    private fun saveRecommendation(message: String) {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_LAST_RECOMMENDATION, message)
            .putLong(KEY_LAST_TIME, System.currentTimeMillis())
            .apply()
    }

    companion object {
        private const val PREFS = "smartgrab"
        private const val KEY_LAST_RECOMMENDATION = "last_recommendation"
        private const val KEY_LAST_TIME = "last_recommendation_time"
        private const val KEY_ONLINE = "online"
        private const val MIN_REPEAT_MS = 4000L

        private val SUPPORTED_PACKAGES = setOf(
            "com.doordash.driverapp",
            "com.instacart.shopper"
        )
    }
}
