package de.localalex95.karten

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import de.localalex95.karten.data.Card
import de.localalex95.karten.data.CardStore
import java.io.File

sealed interface Screen {
    data object List : Screen
    data class Detail(val cardId: String) : Screen

    /** cardId == null bedeutet: neue Karte anlegen. */
    data class Edit(val cardId: String?) : Screen
}

class CardsViewModel(app: Application) : AndroidViewModel(app) {

    private val store = CardStore(File(app.filesDir, "cards.json"))

    var cards by mutableStateOf(sorted(store.load()))
        private set

    var screen by mutableStateOf<Screen>(Screen.List)
        private set

    fun card(id: String?): Card? = cards.firstOrNull { it.id == id }

    fun open(target: Screen) {
        screen = target
    }

    fun back() {
        val current = screen
        screen = if (current is Screen.Edit && card(current.cardId) != null) {
            Screen.Detail(current.cardId!!)
        } else {
            Screen.List
        }
    }

    fun save(card: Card) {
        cards = sorted(cards.filter { it.id != card.id } + card)
        store.save(cards)
        screen = Screen.Detail(card.id)
    }

    fun delete(id: String) {
        cards = cards.filter { it.id != id }
        store.save(cards)
        screen = Screen.List
    }

    private fun sorted(list: List<Card>) = list.sortedBy { it.name.lowercase() }
}
