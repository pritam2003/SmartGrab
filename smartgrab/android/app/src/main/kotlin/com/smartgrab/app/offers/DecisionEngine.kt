package com.smartgrab.app.offers

import android.content.Context
import kotlin.math.roundToInt

object DecisionEngine {
    private const val PREFS = "smartgrab"

    fun evaluate(context: Context, offer: Offer): Decision {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        val minPay = prefs.getFloat("min_pay", 7.0f).toDouble()
        val maxDistanceKm = prefs.getFloat("max_distance_km", 12.0f).toDouble()
        val costPerKm = prefs.getFloat("cost_per_km", 0.5f).toDouble()

        val score = offer.pay - (offer.distanceKm * costPerKm)
        val passes = offer.pay >= minPay && offer.distanceKm <= maxDistanceKm

        val reason = buildString {
            append("score=")
            append((score * 100).roundToInt() / 100.0)
            append(", minPay=")
            append(minPay)
            append(", maxDist=")
            append(maxDistanceKm)
        }

        return Decision(
            offer = offer,
            score = score,
            shouldAccept = passes,
            reason = reason
        )
    }
}
