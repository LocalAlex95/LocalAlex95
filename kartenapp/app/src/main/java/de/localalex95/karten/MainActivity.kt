package de.localalex95.karten

import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import de.localalex95.karten.ui.DetailScreen
import de.localalex95.karten.ui.EditScreen
import de.localalex95.karten.ui.ListScreen

class MainActivity : ComponentActivity() {

    private val viewModel: CardsViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent {
            KartenTheme {
                App(viewModel)
            }
        }
    }
}

@Composable
private fun App(vm: CardsViewModel) {
    val screen = vm.screen
    BackHandler(enabled = screen != Screen.List) { vm.back() }

    when (screen) {
        Screen.List -> ListScreen(
            cards = vm.cards,
            onOpen = { vm.open(Screen.Detail(it.id)) },
            onAdd = { vm.open(Screen.Edit(null)) },
        )

        is Screen.Detail -> {
            val card = vm.card(screen.cardId)
            if (card == null) {
                vm.open(Screen.List)
            } else {
                DetailScreen(
                    card = card,
                    onBack = vm::back,
                    onEdit = { vm.open(Screen.Edit(card.id)) },
                    onDelete = { vm.delete(card.id) },
                )
            }
        }

        is Screen.Edit -> EditScreen(
            existing = vm.card(screen.cardId),
            onBack = vm::back,
            onSave = vm::save,
        )
    }
}

@Composable
private fun KartenTheme(content: @Composable () -> Unit) {
    val dark = isSystemInDarkTheme()
    val context = LocalContext.current
    val colors = when {
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
            if (dark) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)

        dark -> darkColorScheme()
        else -> lightColorScheme()
    }
    MaterialTheme(colorScheme = colors, content = content)
}
