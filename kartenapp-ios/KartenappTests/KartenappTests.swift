import XCTest
@testable import Kartenapp

final class KartenappTests: XCTestCase {

    private func bits(_ modules: [Bool]?) -> String? {
        modules.map { $0.map { $0 ? "1" : "0" }.joined() }
    }

    func testOneDimensionalCodesMatchZXing() {
        for (format, content, expected) in BarcodeVectors.all {
            XCTAssertEqual(bits(Barcode1D.modules(content, format: format)), expected, "\(format.rawValue) \(content)")
        }
    }

    func testCheckDigitsAndInvalidInput() {
        XCTAssertNotNil(Barcode1D.modules("4006381333931", format: .ean13)) // korrekte Prüfziffer
        XCTAssertNil(Barcode1D.modules("4006381333932", format: .ean13)) // falsche Prüfziffer
        XCTAssertNil(Barcode1D.modules("ABC", format: .ean13))
        XCTAssertNil(Barcode1D.modules("12345", format: .itf)) // ungerade Stellenzahl
        XCTAssertNil(Barcode1D.modules("abc", format: .code39)) // Kleinbuchstaben gibt es in Code 39 nicht
        XCTAssertNil(Barcode1D.modules("", format: .code39))
    }

    func testEveryFormatCanShowASample() {
        let samples: [CardFormat: String] = [
            .code128: "6275980012345678901", .ean13: "4006381333931", .ean8: "96385074",
            .upcA: "036000291452", .code39: "ABC-123", .itf: "1234567890", .codabar: "A12345B",
            .qr: "Hallo äöü", .aztec: "Hallo", .pdf417: "Hallo",
        ]
        for format in CardFormat.allCases {
            let sample = samples[format] ?? ""
            XCTAssertTrue(BarcodeEncoder.isValid(sample, format: format), format.rawValue)
        }
        XCTAssertFalse(BarcodeEncoder.isValid("", format: .code128))
        XCTAssertFalse(BarcodeEncoder.isValid("Müller", format: .code128)) // nur ASCII
    }

    func testJSONRoundTripAndAndroidCompatibility() throws {
        let cards = [
            Card(id: "1", name: "IKEA Family", number: "6275980012345678901", format: .code128, color: 0xFF1E5AA8, note: "Notiz äöü"),
            Card(id: "2", name: "Bonuskarte", number: "https://example.com/?id=42", format: .qr, color: 0xFFF9A825),
        ]
        XCTAssertEqual(CardJSON.decode(try CardJSON.encode(cards)), cards)

        // So schreibt die Android-App; defekte Einträge und unbekannte Formate dürfen nichts kaputt machen
        let android = #"[{"id":"1","name":"A"},{"id":"2","name":"B","number":"123","format":"GIBTS_NICHT","color":4280179368,"note":""}]"#
        let decoded = CardJSON.decode(Data(android.utf8))
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first?.id, "2")
        XCTAssertEqual(decoded.first?.format, .code128)
        XCTAssertEqual(CardJSON.decode(Data("kein json".utf8)), [])
    }

    func testBrandRecognition() {
        XCTAssertEqual(Brands.match("IKEA Family")?.domain, "ikea.com")
        XCTAssertEqual(Brands.match("meine ikea-karte")?.domain, "ikea.com")
        XCTAssertEqual(Brands.match("H&M Member")?.domain, "hm.com")
        XCTAssertEqual(Brands.match("Müller")?.domain, "mueller.de")
        XCTAssertEqual(Brands.match("Media Markt Club")?.domain, "mediamarkt.de")
        XCTAssertNil(Brands.match("Admin-Ausweis")) // enthält "dm", aber nicht als Wort
        XCTAssertNil(Brands.match(""))
        XCTAssertEqual(Brands.suggest("ik").map(\.name), ["IKEA Family"])
        XCTAssertTrue(Brands.suggest("i").isEmpty)
    }
}
