package com.smartgrab.app.offers

object OfferParser {
    private val moneyRegex = Regex("\\$\\s*([0-9]+(?:\\.[0-9]{1,2})?)")
    private val distanceRegex = Regex("([0-9]+(?:\\.[0-9]+)?)\\s*(mi|km)\\b", RegexOption.IGNORE_CASE)

    fun parse(packageName: String?, texts: List<String>): Offer? {
        if (packageName.isNullOrBlank() || texts.isEmpty()) return null

        val app = when (packageName) {
            "com.doordash.driverapp" -> GigApp.DOORDASH
            "com.instacart.shopper" -> GigApp.INSTACART
            else -> GigApp.UNKNOWN
        }

        val joined = texts.joinToString(" • ")

        val pays = moneyRegex.findAll(joined)
            .mapNotNull { it.groupValues[1].toDoubleOrNull() }
            .toList()

        val distancesKm = distanceRegex.findAll(joined)
            .mapNotNull { match ->
                val value = match.groupValues[1].toDoubleOrNull() ?: return@mapNotNull null
                val unit = match.groupValues[2].lowercase()
                if (unit == "mi") value * 1.60934 else value
            }
            .toList()

        if (pays.isEmpty() || distancesKm.isEmpty()) return null

        // Heuristic: take the highest payout and the largest distance to avoid underestimating.
        val pay = pays.maxOrNull() ?: return null
        val distanceKm = distancesKm.maxOrNull() ?: return null

        return Offer(
            app = app,
            pay = pay,
            distanceKm = distanceKm,
            rawText = joined
        )
    }
}
