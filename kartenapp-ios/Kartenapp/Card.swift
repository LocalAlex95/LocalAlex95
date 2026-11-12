import Foundation

/// Unterstützte Barcode-Typen. Die Rohwerte entsprechen denen der Android-App.
enum CardFormat: String, Codable, CaseIterable, Identifiable {
    case code128 = "CODE_128"
    case ean13 = "EAN_13"
    case ean8 = "EAN_8"
    case upcA = "UPC_A"
    case code39 = "CODE_39"
    case itf = "ITF"
    case codabar = "CODABAR"
    case qr = "QR_CODE"
    case aztec = "AZTEC"
    case pdf417 = "PDF_417"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .code128: return "Code 128"
        case .ean13: return "EAN-13"
        case .ean8: return "EAN-8"
        case .upcA: return "UPC-A"
        case .code39: return "Code 39"
        case .itf: return "ITF (2 aus 5)"
        case .codabar: return "Codabar"
        case .qr: return "QR-Code"
        case .aztec: return "Aztec"
        case .pdf417: return "PDF417"
        }
    }
}

struct Card: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var number: String
    var format: CardFormat
    /// ARGB, z. B. 0xFF1E5AA8
    var color: Int64
    var note: String

    init(id: String = UUID().uuidString, name: String, number: String,
         format: CardFormat, color: Int64, note: String = "") {
        self.id = id
        self.name = name
        self.number = number
        self.format = format
        self.color = color
        self.note = note
    }

    // Gleiche Feldnamen wie in der Android-App; unbekannte Formate fallen auf Code 128 zurück.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        number = try values.decode(String.self, forKey: .number)
        name = try values.decodeIfPresent(String.self, forKey: .name) ?? ""
        let rawFormat = try values.decodeIfPresent(String.self, forKey: .format) ?? ""
        format = CardFormat(rawValue: rawFormat) ?? .code128
        color = try values.decodeIfPresent(Int64.self, forKey: .color) ?? Card.colors[0]
        note = try values.decodeIfPresent(String.self, forKey: .note) ?? ""
    }

    /// Auswahl an Kartenfarben im Bearbeiten-Dialog.
    static let colors: [Int64] = [
        0xFF1E5AA8, // Blau
        0xFFC62828, // Rot
        0xFF2E7D32, // Grün
        0xFFF9A825, // Gelb
        0xFFEF6C00, // Orange
        0xFF6A1B9A, // Lila
        0xFF00838F, // Türkis
        0xFF37474F, // Anthrazit
    ]
}

enum CardJSON {
    static func encode(_ cards: [Card]) throws -> Data {
        try JSONEncoder().encode(cards)
    }

    /// Liest die Kartenliste. Einzelne defekte Einträge werden übersprungen.
    static func decode(_ data: Data) -> [Card] {
        guard let entries = try? JSONDecoder().decode([Lenient].self, from: data) else { return [] }
        return entries.compactMap(\.card).filter { !$0.id.isEmpty && !$0.number.isEmpty }
    }

    private struct Lenient: Decodable {
        let card: Card?
        init(from decoder: Decoder) throws {
            card = try? Card(from: decoder)
        }
    }
}
