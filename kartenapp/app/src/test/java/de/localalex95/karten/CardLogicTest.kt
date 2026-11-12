package de.localalex95.karten

import de.localalex95.karten.barcode.BarcodeEncoder
import de.localalex95.karten.barcode.CardFormat
import de.localalex95.karten.brand.Brands
import de.localalex95.karten.data.Card
import de.localalex95.karten.data.CardJson
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CardLogicTest {

    @Test
    fun jsonRoundTripKeepsAllFields() {
        val cards = listOf(
            Card("1", "IKEA Family", "6275980012345678901", CardFormat.CODE_128, 0xFF1E5AA8, "Notiz „mit“ Umlauten äöü"),
            Card("2", "Bonuskarte", "https://example.com/?id=42", CardFormat.QR_CODE, 0xFFF9A825),
        )
        assertEquals(cards, CardJson.decode(CardJson.encode(cards)))
    }

    @Test
    fun brokenJsonGivesEmptyList() {
        assertEquals(emptyList<Card>(), CardJson.decode("kein json"))
    }

    @Test
    fun entriesWithoutNumberAreSkippedAndUnknownFormatFallsBack() {
        val json = """[{"id":"1","name":"A"},{"id":"2","name":"B","number":"123","format":"GIBTS_NICHT"}]"""
        val cards = CardJson.decode(json)
        assertEquals(1, cards.size)
        assertEquals("2", cards[0].id)
        assertEquals(CardFormat.CODE_128, cards[0].format)
    }

    @Test
    fun everyFormatMapsToZxingFormatOfSameName() {
        for (format in CardFormat.entries) {
            assertEquals(format.name, format.zxing.name)
        }
    }

    @Test
    fun ean13ChecksValidity() {
        assertTrue(BarcodeEncoder.isValid("4006381333931", CardFormat.EAN_13)) // korrekte Prüfziffer
        assertFalse(BarcodeEncoder.isValid("4006381333932", CardFormat.EAN_13)) // falsche Prüfziffer
        assertFalse(BarcodeEncoder.isValid("ABC", CardFormat.EAN_13))
        assertFalse(BarcodeEncoder.isValid("", CardFormat.CODE_128))
    }

    @Test
    fun encodesOneAndTwoDimensionalCodes() {
        val code128 = BarcodeEncoder.encode("6275980012345678901", CardFormat.CODE_128, 600, 200)
        assertEquals(600, code128.width)
        assertEquals(200, code128.height)

        val qr = BarcodeEncoder.encode("Hallo äöü", CardFormat.QR_CODE, 400, 400)
        assertEquals(400, qr.width)
        assertEquals(400, qr.height)
    }

    @Test
    fun brandIsRecognisedInCardName() {
        assertEquals("ikea.com", Brands.match("IKEA Family")?.domain)
        assertEquals("ikea.com", Brands.match("meine ikea-karte")?.domain)
        assertEquals("hm.com", Brands.match("H&M Member")?.domain)
        assertEquals("mueller.de", Brands.match("Müller")?.domain)
        assertEquals("mediamarkt.de", Brands.match("Media Markt Club")?.domain)
        assertEquals("dm.de", Brands.match("dm")?.domain)
    }

    @Test
    fun brandOnlyMatchesWholeWords() {
        assertNull(Brands.match("Admin-Ausweis")) // enthält "dm", aber nicht als Wort
        assertNull(Brands.match("Fitnessstudio"))
        assertNull(Brands.match(""))
    }

    @Test
    fun suggestionsStartWithTypedText() {
        assertEquals(listOf("IKEA Family"), Brands.suggest("ik").map { it.name })
        assertTrue(Brands.suggest("i").isEmpty()) // erst ab zwei Zeichen
        assertTrue(Brands.suggest("PAYBACK").isEmpty()) // schon vollständig getippt
    }
}
