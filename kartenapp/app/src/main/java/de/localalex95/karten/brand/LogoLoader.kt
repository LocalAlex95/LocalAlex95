package de.localalex95.karten.brand

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.ConcurrentHashMap

/**
 * Lädt das Website-Icon eines Anbieters über öffentliche Icon-Dienste und legt es im
 * App-Speicher ab. Übertragen wird dabei nur die Domain des Anbieters (z. B. "ikea.com"),
 * niemals Kartennummern oder andere Kartendaten.
 */
object LogoLoader {

    private const val MIN_SIZE_PX = 32
    private const val MAX_BYTES = 1_000_000

    private val memory = ConcurrentHashMap<String, ImageBitmap>()

    /** Domains, bei denen der Abruf in dieser Sitzung schon gescheitert ist. */
    private val failed: MutableSet<String> = ConcurrentHashMap.newKeySet()

    private fun sources(domain: String) = listOf(
        "https://www.google.com/s2/favicons?domain=$domain&sz=128",
        "https://icons.duckduckgo.com/ip3/$domain.ico",
    )

    /** Bereits im Arbeitsspeicher vorhandenes Logo, ohne Datei- oder Netzwerkzugriff. */
    fun cached(domain: String): ImageBitmap? = memory[domain]

    suspend fun load(context: Context, domain: String): ImageBitmap? {
        memory[domain]?.let { return it }
        if (domain in failed) return null

        return withContext(Dispatchers.IO) {
            val file = File(File(context.filesDir, "logos").apply { mkdirs() }, "$domain.png")

            val bitmap = readFile(file) ?: download(domain)?.also { save(it, file) }
            if (bitmap == null) {
                failed += domain
                null
            } else {
                bitmap.asImageBitmap().also { memory[domain] = it }
            }
        }
    }

    private fun readFile(file: File): Bitmap? =
        if (file.exists()) BitmapFactory.decodeFile(file.path) else null

    private fun save(bitmap: Bitmap, file: File) {
        try {
            file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        } catch (e: Exception) {
            file.delete()
        }
    }

    private fun download(domain: String): Bitmap? {
        for (source in sources(domain)) {
            val bitmap = try {
                fetch(source)
            } catch (e: Exception) {
                null
            }
            // Zu kleine Bilder sind meist nur Platzhalter und sähen unscharf aus
            if (bitmap != null && bitmap.width >= MIN_SIZE_PX && bitmap.height >= MIN_SIZE_PX) {
                return bitmap
            }
        }
        return null
    }

    private fun fetch(url: String): Bitmap? {
        val connection = URL(url).openConnection() as HttpURLConnection
        try {
            connection.connectTimeout = 8000
            connection.readTimeout = 8000
            if (connection.responseCode != HttpURLConnection.HTTP_OK) return null
            val bytes = connection.inputStream.use { input ->
                val buffer = java.io.ByteArrayOutputStream()
                val chunk = ByteArray(8192)
                while (true) {
                    val read = input.read(chunk)
                    if (read < 0) break
                    buffer.write(chunk, 0, read)
                    if (buffer.size() > MAX_BYTES) return null
                }
                buffer.toByteArray()
            }
            return BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        } finally {
            connection.disconnect()
        }
    }
}
