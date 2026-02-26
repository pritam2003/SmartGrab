package com.smartgrab.app.offers

import android.content.Context
import android.os.SystemClock
import com.google.firebase.FirebaseApp
import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore

class OfferLogger(private val context: Context) {
    private val firestore = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()

    private var lastSignature: String? = null
    private var lastLogTime = 0L

    fun logOffer(sourcePackage: String, offer: Offer, decision: Decision) {
        FirebaseApp.initializeApp(context)

        val uid = auth.currentUser?.uid
            ?: context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY_USER_UID, null)
            ?: return

        val signature = "${offer.app.name}|${offer.pay}|${offer.distanceKm}"
        val now = SystemClock.elapsedRealtime()
        if (signature == lastSignature && now - lastLogTime < MIN_LOG_INTERVAL_MS) {
            return
        }
        lastSignature = signature
        lastLogTime = now

        val payload = hashMapOf(
            "uid" to uid,
            "app" to offer.app.displayName,
            "pay" to offer.pay,
            "distanceKm" to offer.distanceKm,
            "score" to decision.score,
            "shouldAccept" to decision.shouldAccept,
            "reason" to decision.reason,
            "rawText" to offer.rawText.take(MAX_RAW_CHARS),
            "sourcePackage" to sourcePackage,
            "clientAt" to Timestamp.now(),
            "createdAt" to FieldValue.serverTimestamp()
        )

        firestore
            .collection("users")
            .document(uid)
            .collection("offer_logs")
            .add(payload)
    }

    companion object {
        private const val PREFS = "smartgrab"
        private const val KEY_USER_UID = "user_uid"
        private const val MIN_LOG_INTERVAL_MS = 2500L
        private const val MAX_RAW_CHARS = 2000
    }
}
