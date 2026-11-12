package de.localalex95.karten.data

import java.io.File

/** Speichert die Karten als JSON-Datei im privaten App-Speicher (nur lokal auf dem Gerät). */
class CardStore(private val file: File) {

    fun load(): List<Card> {
        if (!file.exists()) return emptyList()
        return try {
            CardJson.decode(file.readText())
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun save(cards: List<Card>) {
        // Erst in eine temporäre Datei schreiben, damit bei einem Abbruch nichts kaputtgeht.
        val tmp = File(file.parentFile, file.name + ".tmp")
        tmp.writeText(CardJson.encode(cards))
        if (!tmp.renameTo(file)) {
            tmp.copyTo(file, overwrite = true)
            tmp.delete()
        }
    }
}
