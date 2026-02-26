package com.smartgrab.app

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.annotation.NonNull
import com.smartgrab.app.accessibility.OfferAccessibilityService
import com.smartgrab.app.notify.OfferNotifier
import com.smartgrab.app.overlay.OfferOverlay
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "smartgrab/platform"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "openOverlaySettings" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "isOverlayGranted" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "isAccessibilityEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "getLastRecommendation" -> {
                    val prefs = getSharedPreferences("smartgrab", MODE_PRIVATE)
                    result.success(prefs.getString("last_recommendation", "") ?: "")
                }
                "getLastRecommendationTime" -> {
                    val prefs = getSharedPreferences("smartgrab", MODE_PRIVATE)
                    result.success(prefs.getLong("last_recommendation_time", 0L))
                }
                "getDecisionSettings" -> {
                    val prefs = getSharedPreferences("smartgrab", MODE_PRIVATE)
                    val settings = mapOf(
                        "minPay" to prefs.getFloat("min_pay", 7.0f).toDouble(),
                        "maxDistanceKm" to prefs.getFloat("max_distance_km", 12.0f).toDouble(),
                        "costPerKm" to prefs.getFloat("cost_per_km", 0.5f).toDouble()
                    )
                    result.success(settings)
                }
                "getOnline" -> {
                    val prefs = getSharedPreferences("smartgrab", MODE_PRIVATE)
                    result.success(prefs.getBoolean("online", false))
                }
                "getDebugEnabled" -> {
                    val prefs = getSharedPreferences("smartgrab", MODE_PRIVATE)
                    result.success(prefs.getBoolean("debug_enabled", false))
                }
                "getLastCapture" -> {
                    val prefs = getSharedPreferences("smartgrab", MODE_PRIVATE)
                    result.success(prefs.getString("last_capture", "") ?: "")
                }
                "getLastCaptureTime" -> {
                    val prefs = getSharedPreferences("smartgrab", MODE_PRIVATE)
                    result.success(prefs.getLong("last_capture_time", 0L))
                }
                "getLastCaptureApp" -> {
                    val prefs = getSharedPreferences("smartgrab", MODE_PRIVATE)
                    result.success(prefs.getString("last_capture_app", "") ?: "")
                }
                "getLastCaptureCount" -> {
                    val prefs = getSharedPreferences("smartgrab", MODE_PRIVATE)
                    result.success(prefs.getInt("last_capture_count", 0))
                }
                "setDecisionSettings" -> {
                    val args = call.arguments as? Map<*, *>
                    val prefs = getSharedPreferences("smartgrab", MODE_PRIVATE)
                    val editor = prefs.edit()

                    val minPay = (args?.get("minPay") as? Number)?.toFloat()
                    val maxDistanceKm = (args?.get("maxDistanceKm") as? Number)?.toFloat()
                    val costPerKm = (args?.get("costPerKm") as? Number)?.toFloat()

                    if (minPay != null) editor.putFloat("min_pay", minPay)
                    if (maxDistanceKm != null) editor.putFloat("max_distance_km", maxDistanceKm)
                    if (costPerKm != null) editor.putFloat("cost_per_km", costPerKm)

                    editor.apply()
                    result.success(true)
                }
                "setOnline" -> {
                    val isOnline = call.arguments as? Boolean ?: false
                    val prefs = getSharedPreferences("smartgrab", MODE_PRIVATE)
                    prefs.edit().putBoolean("online", isOnline).apply()
                    result.success(true)
                }
                "setDebugEnabled" -> {
                    val enabled = call.arguments as? Boolean ?: false
                    val prefs = getSharedPreferences("smartgrab", MODE_PRIVATE)
                    prefs.edit().putBoolean("debug_enabled", enabled).apply()
                    result.success(true)
                }
                "clearLastCapture" -> {
                    val prefs = getSharedPreferences("smartgrab", MODE_PRIVATE)
                    prefs.edit()
                        .remove("last_capture")
                        .remove("last_capture_time")
                        .remove("last_capture_app")
                        .remove("last_capture_count")
                        .apply()
                    result.success(true)
                }
                "simulateOffer" -> {
                    val args = call.arguments as? Map<*, *>
                    val pay = (args?.get("pay") as? Number)?.toDouble() ?: 10.0
                    val distanceKm = (args?.get("distanceKm") as? Number)?.toDouble() ?: 2.0
                    val app = (args?.get("app") as? String) ?: "Instacart"

                    val payText = String.format("%.2f", pay)
                    val distanceText = String.format("%.1f", distanceKm)
                    val message = "Accept \\$$payText • $distanceText km • $app"

                    OfferNotifier(this).showRecommendation(message)
                    OfferOverlay(this).show(message)

                    val prefs = getSharedPreferences("smartgrab", MODE_PRIVATE)
                    prefs.edit()
                        .putString("last_recommendation", message)
                        .putLong("last_recommendation_time", System.currentTimeMillis())
                        .apply()

                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val enabled = Settings.Secure.getInt(
            contentResolver,
            Settings.Secure.ACCESSIBILITY_ENABLED,
            0
        ) == 1
        if (!enabled) return false

        val expected = "${packageName}/${OfferAccessibilityService::class.java.name}"
        val services = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        return services.split(':').any { it.equals(expected, ignoreCase = true) }
    }
}
