import CoreImage
import SwiftUI

enum BarcodeEncoder {

    private static let context = CIContext()

    /// Formate, deren Strichfolge die App selbst berechnet (iOS kann sie nicht erzeugen).
    static func isOwn1D(_ format: CardFormat) -> Bool {
        switch format {
        case .ean13, .ean8, .upcA, .itf, .code39, .codabar: return true
        case .code128, .qr, .aztec, .pdf417: return false
        }
    }

    static func isValid(_ content: String, format: CardFormat) -> Bool {
        guard !content.isEmpty else { return false }
        if isOwn1D(format) {
            return Barcode1D.modules(content, format: format) != nil
        }
        return systemImage(content, format: format) != nil
    }

    /// Code 128 und die 2D-Codes kommen aus Core Image.
    static func systemImage(_ content: String, format: CardFormat) -> CGImage? {
        let filterName: String
        let message: Data?
        switch format {
        case .code128:
            filterName = "CICode128BarcodeGenerator"
            message = content.data(using: .ascii)
        case .qr:
            filterName = "CIQRCodeGenerator"
            message = content.data(using: .utf8)
        case .aztec:
            filterName = "CIAztecCodeGenerator"
            message = content.data(using: .isoLatin1)
        case .pdf417:
            filterName = "CIPDF417BarcodeGenerator"
            message = content.data(using: .isoLatin1)
        default:
            return nil
        }
        guard let message, let filter = CIFilter(name: filterName) else { return nil }
        filter.setValue(message, forKey: "inputMessage")
        guard let output = filter.outputImage, !output.extent.isEmpty, !output.extent.isInfinite else { return nil }
        return context.createCGImage(output, from: output.extent)
    }
}

/// Zeichnet den Code schwarz auf weiß. Der Aufrufer sorgt für den weißen Hintergrund.
struct BarcodeView: View {
    let content: String
    let format: CardFormat

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        if BarcodeEncoder.isOwn1D(format) {
            if let modules = Barcode1D.modules(content, format: format) {
                bars(modules).frame(height: 140)
            } else {
                errorText
            }
        } else if let image = BarcodeEncoder.systemImage(content, format: format) {
            let picture = Image(decorative: image, scale: 1)
                .interpolation(.none) // keine Glättung, sonst verschwimmen die Kanten
                .resizable()
            if format == .code128 {
                picture.frame(height: 140)
            } else {
                picture.scaledToFit()
            }
        } else {
            errorText
        }
    }

    private var errorText: some View {
        Text("Der Code kann mit diesem Barcode-Typ nicht dargestellt werden.")
            .foregroundStyle(.red)
            .padding()
    }

    private func bars(_ modules: [Bool]) -> some View {
        Canvas { context, size in
            let quietZone = 10
            let total = CGFloat(modules.count + 2 * quietZone)
            // Modulbreite auf ganze Pixel abrunden, damit alle Striche gleich scharf sind
            var moduleWidth = (size.width * displayScale / total).rounded(.down) / displayScale
            if moduleWidth <= 0 { moduleWidth = size.width / total }
            let start = (size.width - moduleWidth * total) / 2 + moduleWidth * CGFloat(quietZone)

            var index = 0
            while index < modules.count {
                guard modules[index] else { index += 1; continue }
                var end = index
                while end < modules.count, modules[end] { end += 1 }
                let rect = CGRect(x: start + CGFloat(index) * moduleWidth, y: 0,
                                  width: CGFloat(end - index) * moduleWidth, height: size.height)
                context.fill(Path(rect), with: .color(.black))
                index = end
            }
        }
    }
}
