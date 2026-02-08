package com.smartgrab.app.offers

enum class GigApp(val displayName: String) {
    DOORDASH("DoorDash"),
    INSTACART("Instacart"),
    UNKNOWN("Unknown")
}

data class Offer(
    val app: GigApp,
    val pay: Double,
    val distanceKm: Double,
    val rawText: String
)

data class Decision(
    val offer: Offer,
    val score: Double,
    val shouldAccept: Boolean,
    val reason: String
)
