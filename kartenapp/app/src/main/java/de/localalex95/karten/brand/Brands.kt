package de.localalex95.karten.brand

/**
 * Ein bekannter Kartenanbieter. Über [domain] wird das Logo (Website-Icon) geladen,
 * [keywords] sind zusätzliche Schreibweisen, an denen der Anbieter im Kartennamen erkannt wird.
 */
data class Brand(val name: String, val domain: String, val keywords: List<String> = emptyList())

object Brands {

    val all: List<Brand> = listOf(
        Brand("IKEA Family", "ikea.com", listOf("ikea")),
        Brand("PAYBACK", "payback.de"),
        Brand("DeutschlandCard", "deutschlandcard.de", listOf("deutschland card")),
        Brand("dm", "dm.de", listOf("dm drogerie")),
        Brand("Rossmann", "rossmann.de"),
        Brand("Müller", "mueller.de", listOf("mueller")),
        Brand("REWE", "rewe.de"),
        Brand("EDEKA", "edeka.de"),
        Brand("Lidl Plus", "lidl.de", listOf("lidl")),
        Brand("Kaufland", "kaufland.de"),
        Brand("PENNY", "penny.de"),
        Brand("Netto", "netto-online.de"),
        Brand("tegut", "tegut.com"),
        Brand("Globus", "globus.de"),
        Brand("Douglas", "douglas.de"),
        Brand("H&M", "hm.com", listOf("hm")),
        Brand("C&A", "c-and-a.com"),
        Brand("Zalando", "zalando.de"),
        Brand("Deichmann", "deichmann.com"),
        Brand("Decathlon", "decathlon.de"),
        Brand("Intersport", "intersport.de"),
        Brand("MediaMarkt", "mediamarkt.de", listOf("media markt")),
        Brand("Saturn", "saturn.de"),
        Brand("OBI", "obi.de"),
        Brand("Hornbach", "hornbach.de"),
        Brand("Bauhaus", "bauhaus.info"),
        Brand("toom", "toom.de"),
        Brand("hagebau", "hagebau.de"),
        Brand("Thalia", "thalia.de"),
        Brand("Tchibo", "tchibo.de"),
        Brand("Fressnapf", "fressnapf.de"),
        Brand("Fielmann", "fielmann.de"),
        Brand("Apollo", "apollo.de"),
        Brand("ADAC", "adac.de"),
        Brand("Shell", "shell.de"),
        Brand("Aral", "aral.de"),
        Brand("Miles & More", "miles-and-more.com", listOf("miles and more")),
        Brand("BahnCard", "bahn.de", listOf("bahn card", "deutsche bahn")),
        Brand("Sixt", "sixt.de"),
        Brand("McDonald's", "mcdonalds.com", listOf("mcdonalds", "mc donalds")),
        Brand("Burger King", "burgerking.de", listOf("burgerking")),
        Brand("Subway", "subway.com"),
        Brand("Starbucks", "starbucks.de"),
    )

    // Längste Schlüsselwörter zuerst, damit z. B. "media markt" vor kürzeren Treffern gewinnt
    private val index: List<Pair<String, Brand>> = all
        .flatMap { brand -> (brand.keywords + brand.name).map { normalize(it) to brand } }
        .distinct()
        .sortedByDescending { it.first.length }

    /** Findet den Anbieter, der als ganzes Wort im Kartennamen vorkommt. */
    fun match(cardName: String): Brand? {
        val padded = " " + normalize(cardName) + " "
        return index.firstOrNull { (keyword, _) -> padded.contains(" $keyword ") }?.second
    }

    /** Namensvorschläge für das, was bisher getippt wurde. */
    fun suggest(typed: String, limit: Int = 5): List<Brand> {
        val prefix = normalize(typed)
        if (prefix.length < 2) return emptyList()
        return all
            .filter { brand ->
                val candidates = (brand.keywords + brand.name).map { normalize(it) }
                normalize(brand.name) != prefix && candidates.any { it.startsWith(prefix) }
            }
            .take(limit)
    }

    /** Kleinbuchstaben, alles außer Buchstaben und Ziffern wird zu einem Leerzeichen. */
    internal fun normalize(text: String): String =
        text.lowercase()
            .map { if (it.isLetterOrDigit()) it else ' ' }
            .joinToString("")
            .trim()
            .replace(Regex(" +"), " ")
}
