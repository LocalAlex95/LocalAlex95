package de.localalex95.karten.data

import de.localalex95.karten.barcode.CardFormat
import org.json.JSONArray
import org.json.JSONObject

data class Card(
    val id: String,
    val name: String,
    val number: String,
    val format: CardFormat,
    /** ARGB, z. B. 0xFF1E5AA8 */
    val color: Long,
    val note: String = "",
)

/** Auswahl an Kartenfarben im Bearbeiten-Dialog. */
val CardColors: List<Long> = listOf(
    0xFF1E5AA8, // Blau
    0xFFC62828, // Rot
    0xFF2E7D32, // Grün
    0xFFF9A825, // Gelb
    0xFFEF6C00, // Orange
    0xFF6A1B9A, // Lila
    0xFF00838F, // Türkis
    0xFF37474F, // Anthrazit
)

object CardJson {
    fun encode(cards: List<Card>): String {
        val array = JSONArray()
        for (card in cards) {
            array.put(
                JSONObject()
                    .put("id", card.id)
                    .put("name", card.name)
                    .put("number", card.number)
                    .put("format", card.format.name)
                    .put("color", card.color)
                    .put("note", card.note)
            )
        }
        return array.toString()
    }

    /** Liest die Kartenliste. Einzelne defekte Einträge werden übersprungen. */
    fun decode(json: String): List<Card> {
        val array = try {
            JSONArray(json)
        } catch (e: Exception) {
            return emptyList()
        }
        val cards = mutableListOf<Card>()
        for (i in 0 until array.length()) {
            val obj = array.optJSONObject(i) ?: continue
            val id = obj.optString("id")
            val number = obj.optString("number")
            if (id.isEmpty() || number.isEmpty()) continue
            cards += Card(
                id = id,
                name = obj.optString("name"),
                number = number,
                format = CardFormat.fromName(obj.optString("format")) ?: CardFormat.CODE_128,
                color = obj.optLong("color", CardColors.first()),
                note = obj.optString("note"),
            )
        }
        return cards
    }
}
