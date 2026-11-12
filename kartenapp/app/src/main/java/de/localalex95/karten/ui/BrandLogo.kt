package de.localalex95.karten.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import de.localalex95.karten.brand.Brands
import de.localalex95.karten.brand.LogoLoader

/**
 * Zeigt das Logo des Anbieters, der im Kartennamen erkannt wird.
 * Ohne Treffer oder ohne geladenes Logo wird nichts gezeichnet (auch [modifier] entfällt dann).
 */
@Composable
fun BrandLogo(cardName: String, size: Dp, modifier: Modifier = Modifier) {
    val domain = remember(cardName) { Brands.match(cardName)?.domain }
    val context = LocalContext.current.applicationContext

    val logo by produceState<ImageBitmap?>(
        initialValue = domain?.let { LogoLoader.cached(it) },
        key1 = domain,
    ) {
        value = if (domain == null) null else LogoLoader.load(context, domain)
    }

    val image = logo ?: return
    Box(
        modifier = modifier
            .size(size)
            .clip(RoundedCornerShape(size / 5))
            // Weißer Grund, weil viele Logos transparente Flächen haben
            .background(Color.White)
            .padding(size / 10),
    ) {
        Image(
            bitmap = image,
            contentDescription = null,
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Fit,
        )
    }
}
