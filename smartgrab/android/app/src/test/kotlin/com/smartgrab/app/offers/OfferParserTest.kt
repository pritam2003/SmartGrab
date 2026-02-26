package com.smartgrab.app.offers

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class OfferParserTest {
    @Test
    fun parsesDoordashOfferMiles() {
        val texts = listOf("DoorDash", "Earn \$10.50", "5.0 mi", "Total")
        val offer = OfferParser.parse("com.doordash.driverapp", texts)
        assertNotNull(offer)
        offer ?: return
        assertEquals(GigApp.DOORDASH, offer.app)
        assertEquals(10.50, offer.pay, 0.01)
        assertEquals(8.05, offer.distanceKm, 0.05)
    }

    @Test
    fun parsesInstacartOfferKm() {
        val texts = listOf("Instacart", "\$12", "2.0 km")
        val offer = OfferParser.parse("com.instacart.shopper", texts)
        assertNotNull(offer)
        offer ?: return
        assertEquals(GigApp.INSTACART, offer.app)
        assertEquals(12.0, offer.pay, 0.01)
        assertEquals(2.0, offer.distanceKm, 0.01)
    }

    @Test
    fun returnsNullWhenMissingPayOrDistance() {
        val missingPay = OfferParser.parse("com.doordash.driverapp", listOf("5.0 mi"))
        val missingDistance = OfferParser.parse("com.doordash.driverapp", listOf("\$9.00"))
        assertNull(missingPay)
        assertNull(missingDistance)
    }
}
