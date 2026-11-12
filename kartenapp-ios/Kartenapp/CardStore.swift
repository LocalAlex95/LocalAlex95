import Foundation
import Observation

/// Hält die Karten und speichert sie als JSON-Datei im App-Speicher (nur lokal auf dem Gerät).
@Observable
final class CardStore {
    private(set) var cards: [Card] = []
    private let file: URL

    init(file: URL = CardStore.defaultFile) {
        self.file = file
        if let data = try? Data(contentsOf: file) {
            cards = sorted(CardJSON.decode(data))
        }
    }

    static var defaultFile: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("cards.json")
    }

    func card(id: String) -> Card? {
        cards.first { $0.id == id }
    }

    func save(_ card: Card) {
        cards = sorted(cards.filter { $0.id != card.id } + [card])
        persist()
    }

    func delete(id: String) {
        cards.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        guard let data = try? CardJSON.encode(cards) else { return }
        try? data.write(to: file, options: .atomic)
    }

    private func sorted(_ list: [Card]) -> [Card] {
        list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
