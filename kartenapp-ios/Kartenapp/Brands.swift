import Foundation

/// Ein bekannter Kartenanbieter. Über `domain` wird das Logo (Website-Icon) geladen,
/// `keywords` sind zusätzliche Schreibweisen, an denen der Anbieter im Kartennamen erkannt wird.
struct Brand: Hashable {
    let name: String
    let domain: String
    var keywords: [String] = []
}

enum Brands {
    // Gleiche Liste wie in der Android-App (Brands.kt)
    static let all: [Brand] = [
        Brand(name: "IKEA Family", domain: "ikea.com", keywords: ["ikea"]),
        Brand(name: "PAYBACK", domain: "payback.de", keywords: []),
        Brand(name: "DeutschlandCard", domain: "deutschlandcard.de", keywords: ["deutschland card"]),
        Brand(name: "dm", domain: "dm.de", keywords: ["dm drogerie"]),
        Brand(name: "Rossmann", domain: "rossmann.de", keywords: []),
        Brand(name: "Müller", domain: "mueller.de", keywords: ["mueller"]),
        Brand(name: "REWE", domain: "rewe.de", keywords: []),
        Brand(name: "EDEKA", domain: "edeka.de", keywords: []),
        Brand(name: "Lidl Plus", domain: "lidl.de", keywords: ["lidl"]),
        Brand(name: "Kaufland", domain: "kaufland.de", keywords: []),
        Brand(name: "PENNY", domain: "penny.de", keywords: []),
        Brand(name: "Netto", domain: "netto-online.de", keywords: []),
        Brand(name: "tegut", domain: "tegut.com", keywords: []),
        Brand(name: "Globus", domain: "globus.de", keywords: []),
        Brand(name: "Douglas", domain: "douglas.de", keywords: []),
        Brand(name: "H&M", domain: "hm.com", keywords: ["hm"]),
        Brand(name: "C&A", domain: "c-and-a.com", keywords: []),
        Brand(name: "Zalando", domain: "zalando.de", keywords: []),
        Brand(name: "Deichmann", domain: "deichmann.com", keywords: []),
        Brand(name: "Decathlon", domain: "decathlon.de", keywords: []),
        Brand(name: "Intersport", domain: "intersport.de", keywords: []),
        Brand(name: "MediaMarkt", domain: "mediamarkt.de", keywords: ["media markt"]),
        Brand(name: "Saturn", domain: "saturn.de", keywords: []),
        Brand(name: "OBI", domain: "obi.de", keywords: []),
        Brand(name: "Hornbach", domain: "hornbach.de", keywords: []),
        Brand(name: "Bauhaus", domain: "bauhaus.info", keywords: []),
        Brand(name: "toom", domain: "toom.de", keywords: []),
        Brand(name: "hagebau", domain: "hagebau.de", keywords: []),
        Brand(name: "Thalia", domain: "thalia.de", keywords: []),
        Brand(name: "Tchibo", domain: "tchibo.de", keywords: []),
        Brand(name: "Fressnapf", domain: "fressnapf.de", keywords: []),
        Brand(name: "Fielmann", domain: "fielmann.de", keywords: []),
        Brand(name: "Apollo", domain: "apollo.de", keywords: []),
        Brand(name: "ADAC", domain: "adac.de", keywords: []),
        Brand(name: "Shell", domain: "shell.de", keywords: []),
        Brand(name: "Aral", domain: "aral.de", keywords: []),
        Brand(name: "Miles & More", domain: "miles-and-more.com", keywords: ["miles and more"]),
        Brand(name: "BahnCard", domain: "bahn.de", keywords: ["bahn card", "deutsche bahn"]),
        Brand(name: "Sixt", domain: "sixt.de", keywords: []),
        Brand(name: "McDonald's", domain: "mcdonalds.com", keywords: ["mcdonalds", "mc donalds"]),
        Brand(name: "Burger King", domain: "burgerking.de", keywords: ["burgerking"]),
        Brand(name: "Subway", domain: "subway.com", keywords: []),
        Brand(name: "Starbucks", domain: "starbucks.de", keywords: []),
    ]

    // Längste Schlüsselwörter zuerst, damit z. B. "media markt" vor kürzeren Treffern gewinnt
    private static let index: [(keyword: String, brand: Brand)] = all
        .flatMap { brand in (brand.keywords + [brand.name]).map { (keyword: normalize($0), brand: brand) } }
        .sorted { $0.keyword.count > $1.keyword.count }

    /// Findet den Anbieter, der als ganzes Wort im Kartennamen vorkommt.
    static func match(_ cardName: String) -> Brand? {
        let padded = " " + normalize(cardName) + " "
        return index.first { padded.contains(" " + $0.keyword + " ") }?.brand
    }

    /// Namensvorschläge für das, was bisher getippt wurde.
    static func suggest(_ typed: String, limit: Int = 5) -> [Brand] {
        let prefix = normalize(typed)
        guard prefix.count >= 2 else { return [] }
        let matches = all.filter { brand in
            let candidates = (brand.keywords + [brand.name]).map(normalize)
            return normalize(brand.name) != prefix && candidates.contains { $0.hasPrefix(prefix) }
        }
        return Array(matches.prefix(limit))
    }

    /// Kleinbuchstaben, alles außer Buchstaben und Ziffern wird zu einem Leerzeichen.
    static func normalize(_ text: String) -> String {
        let mapped = text.lowercased().map { $0.isLetter || $0.isNumber ? $0 : Character(" ") }
        return String(mapped).split(separator: " ").joined(separator: " ")
    }
}
