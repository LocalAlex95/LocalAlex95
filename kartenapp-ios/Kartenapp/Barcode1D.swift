import Foundation

/// Erzeugt die Strichfolge für 1D-Barcodes, die iOS nicht selbst kann.
/// Ergebnis: ein Bool pro Modul (true = Strich), ohne Ruhezone. nil = Inhalt passt nicht zum Format.
enum Barcode1D {

    static func modules(_ content: String, format: CardFormat) -> [Bool]? {
        let pattern: String?
        switch format {
        case .ean13: pattern = ean13(content)
        case .ean8: pattern = ean8(content)
        case .upcA: pattern = upcA(content)
        case .itf: pattern = itf(content)
        case .code39: pattern = code39(content)
        case .codabar: pattern = codabar(content)
        default: pattern = nil
        }
        return pattern.map { $0.map { $0 == "1" } }
    }

    // MARK: EAN / UPC

    private static let eanL = ["0001101", "0011001", "0010011", "0111101", "0100011",
                               "0110001", "0101111", "0111011", "0110111", "0001011"]
    /// Welche der ersten sechs Ziffern mit dem G-Satz codiert werden, abhängig von der führenden Ziffer.
    private static let eanParity = ["LLLLLL", "LLGLGG", "LLGGLG", "LLGGGL", "LGLLGG",
                                    "LGGLLG", "LGGGLL", "LGLGLG", "LGLGGL", "LGGLGL"]

    private static func eanR(_ digit: Int) -> String {
        String(eanL[digit].map { $0 == "1" ? Character("0") : Character("1") })
    }

    private static func eanG(_ digit: Int) -> String {
        String(eanR(digit).reversed())
    }

    private static func digits(_ text: String) -> [Int]? {
        let values = text.compactMap { $0.isASCII ? $0.wholeNumberValue : nil }
        return values.count == text.count && !text.isEmpty ? values : nil
    }

    /// Prüfziffer nach GS1: von rechts abwechselnd mit 3 und 1 gewichten.
    static func checkDigit(_ payload: [Int]) -> Int {
        var sum = 0
        for (offset, digit) in payload.reversed().enumerated() {
            sum += digit * (offset % 2 == 0 ? 3 : 1)
        }
        return (10 - sum % 10) % 10
    }

    /// Ergänzt die Prüfziffer oder prüft sie, wenn sie schon dabei ist.
    private static func withCheckDigit(_ text: String, length: Int) -> [Int]? {
        guard var values = digits(text) else { return nil }
        if values.count == length - 1 {
            values.append(checkDigit(values))
        } else if values.count == length {
            guard checkDigit(Array(values.dropLast())) == values[length - 1] else { return nil }
        } else {
            return nil
        }
        return values
    }

    private static func ean13(_ text: String) -> String? {
        guard let d = withCheckDigit(text, length: 13) else { return nil }
        let parity = Array(eanParity[d[0]])
        var result = "101"
        for i in 1...6 {
            result += parity[i - 1] == "L" ? eanL[d[i]] : eanG(d[i])
        }
        result += "01010"
        for i in 7...12 {
            result += eanR(d[i])
        }
        return result + "101"
    }

    private static func ean8(_ text: String) -> String? {
        guard let d = withCheckDigit(text, length: 8) else { return nil }
        var result = "101"
        for i in 0...3 { result += eanL[d[i]] }
        result += "01010"
        for i in 4...7 { result += eanR(d[i]) }
        return result + "101"
    }

    /// UPC-A ist ein EAN-13 mit führender Null.
    private static func upcA(_ text: String) -> String? {
        guard text.count == 11 || text.count == 12 else { return nil }
        return ean13("0" + text)
    }

    // MARK: ITF (Interleaved 2 of 5)

    /// true = breites Element
    private static let itfWide: [[Bool]] = [
        [false, false, true, true, false], [true, false, false, false, true],
        [false, true, false, false, true], [true, true, false, false, false],
        [false, false, true, false, true], [true, false, true, false, false],
        [false, true, true, false, false], [false, false, false, true, true],
        [true, false, false, true, false], [false, true, false, true, false],
    ]

    private static func itf(_ text: String) -> String? {
        guard let d = digits(text), d.count % 2 == 0, d.count <= 80 else { return nil }
        var result = "1010"
        for pair in stride(from: 0, to: d.count, by: 2) {
            let bars = itfWide[d[pair]]
            let spaces = itfWide[d[pair + 1]]
            for i in 0..<5 {
                result += String(repeating: "1", count: bars[i] ? 3 : 1)
                result += String(repeating: "0", count: spaces[i] ? 3 : 1)
            }
        }
        return result + "11101"
    }

    // MARK: Code 39

    private static func code39(_ text: String) -> String? {
        guard !text.isEmpty, text.count <= 80, let star = BarcodeTables.code39["*"] else { return nil }
        var parts = [star]
        for character in text {
            guard character != "*", let pattern = BarcodeTables.code39[character] else { return nil }
            parts.append(pattern)
        }
        parts.append(star)
        return parts.joined(separator: "0")
    }

    // MARK: Codabar

    private static func codabar(_ text: String) -> String? {
        var characters = Array(text.uppercased())
        let guards: Set<Character> = ["A", "B", "C", "D"]
        // Ohne Start-/Stoppzeichen wird wie bei ZXing mit "A" eingerahmt
        if characters.count < 2 || !guards.contains(characters[0]) || !guards.contains(characters[characters.count - 1]) {
            guard !characters.contains(where: { guards.contains($0) }) else { return nil }
            characters = ["A"] + characters + ["A"]
        }
        guard characters.count >= 3 else { return nil }
        var parts: [String] = []
        for (index, character) in characters.enumerated() {
            let isEdge = index == 0 || index == characters.count - 1
            guard guards.contains(character) == isEdge,
                  let pattern = BarcodeTables.codabar[character] else { return nil }
            parts.append(pattern)
        }
        return parts.joined(separator: "0")
    }
}
