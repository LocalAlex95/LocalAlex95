package de.localalex95.karten.barcode

import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.MultiFormatWriter
import com.google.zxing.common.BitMatrix

/** Unterstützte Barcode-Typen. Die Namen entsprechen den ZXing-Formatnamen. */
enum class CardFormat(val label: String, val zxing: BarcodeFormat, val twoDimensional: Boolean) {
    CODE_128("Code 128", BarcodeFormat.CODE_128, false),
    EAN_13("EAN-13", BarcodeFormat.EAN_13, false),
    EAN_8("EAN-8", BarcodeFormat.EAN_8, false),
    UPC_A("UPC-A", BarcodeFormat.UPC_A, false),
    UPC_E("UPC-E", BarcodeFormat.UPC_E, false),
    CODE_39("Code 39", BarcodeFormat.CODE_39, false),
    CODE_93("Code 93", BarcodeFormat.CODE_93, false),
    ITF("ITF (2 aus 5)", BarcodeFormat.ITF, false),
    CODABAR("Codabar", BarcodeFormat.CODABAR, false),
    QR_CODE("QR-Code", BarcodeFormat.QR_CODE, true),
    AZTEC("Aztec", BarcodeFormat.AZTEC, true),
    DATA_MATRIX("Data Matrix", BarcodeFormat.DATA_MATRIX, true),
    PDF_417("PDF417", BarcodeFormat.PDF_417, true);

    companion object {
        fun fromName(name: String?): CardFormat? = entries.firstOrNull { it.name == name }
    }
}

object BarcodeEncoder {

    /**
     * Erzeugt die Schwarz-Weiß-Matrix für den Code.
     * Wirft eine Exception, wenn der Inhalt nicht zum Format passt (z. B. Buchstaben bei EAN-13).
     */
    fun encode(content: String, format: CardFormat, width: Int, height: Int): BitMatrix {
        val hints = mapOf(EncodeHintType.CHARACTER_SET to "UTF-8")
        return MultiFormatWriter().encode(content, format.zxing, width, height, hints)
    }

    fun isValid(content: String, format: CardFormat): Boolean {
        if (content.isEmpty()) return false
        return try {
            encode(content, format, 0, 0)
            true
        } catch (e: Exception) {
            false
        }
    }
}
