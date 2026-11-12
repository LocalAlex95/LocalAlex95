package de.localalex95.karten.ui

import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.google.zxing.common.BitMatrix
import de.localalex95.karten.R
import de.localalex95.karten.barcode.BarcodeEncoder
import de.localalex95.karten.barcode.CardFormat

/** Zeichnet den Code schwarz auf weiß. Der Aufrufer sorgt für den weißen Hintergrund. */
@Composable
fun BarcodeImage(content: String, format: CardFormat, modifier: Modifier = Modifier) {
    BoxWithConstraints(modifier.fillMaxWidth()) {
        val widthPx = constraints.maxWidth
        val heightPx = when (format) {
            CardFormat.PDF_417 -> widthPx / 3
            else -> if (format.twoDimensional) widthPx else with(LocalDensity.current) { 140.dp.roundToPx() }
        }
        val heightDp = with(LocalDensity.current) { heightPx.toDp() }

        val bitmap = remember(content, format, widthPx, heightPx) {
            try {
                BarcodeEncoder.encode(content, format, widthPx, heightPx).toBitmap()
            } catch (e: Exception) {
                null
            }
        }

        if (bitmap != null) {
            Image(
                bitmap = bitmap.asImageBitmap(),
                contentDescription = stringResource(R.string.barcode_description),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(heightDp),
                contentScale = ContentScale.Fit,
                // Keine Glättung, sonst verschwimmen die Kanten und Scanner tun sich schwer
                filterQuality = FilterQuality.None,
            )
        } else {
            Text(
                stringResource(R.string.barcode_error),
                color = Color(0xFFB3261E),
                modifier = Modifier.padding(16.dp),
            )
        }
    }
}

private fun BitMatrix.toBitmap(): Bitmap {
    val pixels = IntArray(width * height)
    for (y in 0 until height) {
        val offset = y * width
        for (x in 0 until width) {
            pixels[offset + x] = if (get(x, y)) 0xFF000000.toInt() else 0xFFFFFFFF.toInt()
        }
    }
    return Bitmap.createBitmap(pixels, width, height, Bitmap.Config.ARGB_8888)
}
