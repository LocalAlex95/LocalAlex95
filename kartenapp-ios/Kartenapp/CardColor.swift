import SwiftUI

extension Color {
    /// Farbe aus einem ARGB-Wert wie 0xFF1E5AA8
    init(argb: Int64) {
        self.init(
            .sRGB,
            red: Double((argb >> 16) & 0xFF) / 255,
            green: Double((argb >> 8) & 0xFF) / 255,
            blue: Double(argb & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// Schwarz auf hellen, Weiß auf dunklen Kartenfarben.
func contentColor(onARGB argb: Int64) -> Color {
    func linear(_ value: Int64) -> Double {
        let c = Double(value & 0xFF) / 255
        return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
    let luminance = 0.2126 * linear(argb >> 16) + 0.7152 * linear(argb >> 8) + 0.0722 * linear(argb)
    return luminance > 0.5 ? .black : .white
}
