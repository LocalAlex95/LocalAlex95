import UIKit

/// Lädt das Website-Icon eines Anbieters über öffentliche Icon-Dienste und legt es im
/// App-Speicher ab. Übertragen wird dabei nur die Domain des Anbieters (z. B. "ikea.com"),
/// niemals Kartennummern oder andere Kartendaten.
actor LogoLoader {
    static let shared = LogoLoader()

    private static let minSize: CGFloat = 32
    private static let maxBytes = 1_000_000

    private var memory: [String: UIImage] = [:]
    /// Domains, bei denen der Abruf in dieser Sitzung schon gescheitert ist.
    private var failed: Set<String> = []

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 8
        return URLSession(configuration: configuration)
    }()

    private func sources(_ domain: String) -> [URL] {
        [
            "https://www.google.com/s2/favicons?domain=\(domain)&sz=128",
            "https://icons.duckduckgo.com/ip3/\(domain).ico",
        ].compactMap(URL.init(string:))
    }

    func logo(for domain: String) async -> UIImage? {
        if let image = memory[domain] { return image }
        if failed.contains(domain) { return nil }

        let file = Self.folder.appendingPathComponent(domain + ".png")
        if let data = try? Data(contentsOf: file), let image = UIImage(data: data) {
            memory[domain] = image
            return image
        }

        for url in sources(domain) {
            guard let (data, response) = try? await session.data(from: url),
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  data.count <= Self.maxBytes,
                  let image = UIImage(data: data),
                  // Zu kleine Bilder sind meist nur Platzhalter und sähen unscharf aus
                  image.size.width * image.scale >= Self.minSize,
                  image.size.height * image.scale >= Self.minSize
            else { continue }
            try? image.pngData()?.write(to: file, options: .atomic)
            memory[domain] = image
            return image
        }

        failed.insert(domain)
        return nil
    }

    private static let folder: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("logos")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }()
}
