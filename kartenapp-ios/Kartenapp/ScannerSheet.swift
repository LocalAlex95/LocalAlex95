import SwiftUI
import Vision
import VisionKit

/// Kamera-Scanner als Sheet. Meldet den ersten erkannten Code und schließt sich dann.
struct ScannerSheet: View {
    let onScan: (String, CardFormat?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DataScanner { number, format in
                        onScan(number, format)
                        dismiss()
                    }
                    .ignoresSafeArea()
                } else {
                    ContentUnavailableView(
                        "Scannen nicht möglich",
                        systemImage: "camera",
                        description: Text("Bitte erlaube der App in den iOS-Einstellungen den Kamerazugriff oder gib die Nummer von Hand ein.")
                    )
                }
            }
            .navigationTitle("Barcode scannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}

private struct DataScanner: UIViewControllerRepresentable {
    let onScan: (String, CardFormat?) -> Void

    private static let symbologies: [VNBarcodeSymbology] = [
        .code128, .ean13, .ean8, .code39, .itf14, .i2of5, .codabar, .qr, .aztec, .pdf417,
    ]

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: Self.symbologies)],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {}

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        scanner.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScan: (String, CardFormat?) -> Void
        private var done = false

        init(onScan: @escaping (String, CardFormat?) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                guard !done, case .barcode(let barcode) = item, let text = barcode.payloadStringValue else { continue }
                done = true
                dataScanner.stopScanning()
                onScan(text, Self.format(for: barcode.observation.symbology))
            }
        }

        private static func format(for symbology: VNBarcodeSymbology) -> CardFormat? {
            switch symbology {
            case .code128: return .code128
            case .ean13: return .ean13
            case .ean8: return .ean8
            case .code39, .code39Checksum, .code39FullASCII, .code39FullASCIIChecksum: return .code39
            case .itf14, .i2of5, .i2of5Checksum: return .itf
            case .codabar: return .codabar
            case .qr: return .qr
            case .aztec: return .aztec
            case .pdf417: return .pdf417
            default: return nil
            }
        }
    }
}
