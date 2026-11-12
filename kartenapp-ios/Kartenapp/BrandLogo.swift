import SwiftUI

/// Zeigt das Logo des Anbieters, der im Kartennamen erkannt wird.
/// Ohne Treffer oder ohne geladenes Logo wird nichts gezeichnet.
struct BrandLogo: View {
    let cardName: String
    let size: CGFloat

    @State private var image: UIImage?

    private var domain: String? { Brands.match(cardName)?.domain }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(size / 10)
                    .frame(width: size, height: size)
                    // Weißer Grund, weil viele Logos transparente Flächen haben
                    .background(Color.white, in: RoundedRectangle(cornerRadius: size / 5))
            }
        }
        .task(id: domain) {
            if let domain {
                image = await LogoLoader.shared.logo(for: domain)
            } else {
                image = nil
            }
        }
    }
}
