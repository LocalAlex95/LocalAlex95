package de.localalex95.karten.ui

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.journeyapps.barcodescanner.ScanContract
import com.journeyapps.barcodescanner.ScanOptions
import de.localalex95.karten.R
import de.localalex95.karten.barcode.BarcodeEncoder
import de.localalex95.karten.barcode.CardFormat
import de.localalex95.karten.data.Card
import de.localalex95.karten.data.CardColors
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditScreen(
    existing: Card?,
    onBack: () -> Unit,
    onSave: (Card) -> Unit,
) {
    var name by rememberSaveable { mutableStateOf(existing?.name ?: "") }
    var number by rememberSaveable { mutableStateOf(existing?.number ?: "") }
    var formatName by rememberSaveable { mutableStateOf((existing?.format ?: CardFormat.CODE_128).name) }
    var color by rememberSaveable { mutableStateOf(existing?.color ?: CardColors.first()) }
    var note by rememberSaveable { mutableStateOf(existing?.note ?: "") }
    var showErrors by rememberSaveable { mutableStateOf(false) }

    val format = CardFormat.fromName(formatName) ?: CardFormat.CODE_128
    val nameOk = name.isNotBlank()
    val numberOk = number.isNotBlank()
    val formatOk = !numberOk || BarcodeEncoder.isValid(number.trim(), format)

    val scanPrompt = stringResource(R.string.scan_prompt)
    val scanner = rememberLauncherForActivityResult(ScanContract()) { result ->
        val contents = result.contents
        if (contents != null) {
            number = contents
            CardFormat.fromName(result.formatName)?.let { formatName = it.name }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(stringResource(if (existing == null) R.string.add_card else R.string.edit_card))
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, stringResource(R.string.back))
                    }
                },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .imePadding()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            FilledTonalButton(
                onClick = {
                    scanner.launch(
                        ScanOptions()
                            .setDesiredBarcodeFormats(CardFormat.entries.map { it.name })
                            .setPrompt(scanPrompt)
                            .setBeepEnabled(false)
                            .setOrientationLocked(false)
                    )
                },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(stringResource(R.string.scan))
            }

            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text(stringResource(R.string.field_name)) },
                singleLine = true,
                isError = showErrors && !nameOk,
                supportingText = if (showErrors && !nameOk) {
                    { Text(stringResource(R.string.error_name)) }
                } else null,
                modifier = Modifier.fillMaxWidth(),
            )

            OutlinedTextField(
                value = number,
                onValueChange = { number = it },
                label = { Text(stringResource(R.string.field_number)) },
                isError = showErrors && (!numberOk || !formatOk),
                supportingText = when {
                    showErrors && !numberOk -> {
                        { Text(stringResource(R.string.error_number)) }
                    }

                    !formatOk -> {
                        { Text(stringResource(R.string.error_format)) }
                    }

                    else -> null
                },
                modifier = Modifier.fillMaxWidth(),
            )

            FormatPicker(format, onSelect = { formatName = it.name })

            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(stringResource(R.string.field_color), style = MaterialTheme.typography.labelLarge)
                Row(
                    modifier = Modifier.horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    for (option in CardColors) {
                        ColorDot(option, selected = option == color, onClick = { color = option })
                    }
                }
            }

            OutlinedTextField(
                value = note,
                onValueChange = { note = it },
                label = { Text(stringResource(R.string.field_note)) },
                minLines = 2,
                modifier = Modifier.fillMaxWidth(),
            )

            // Vorschau, sobald der Code darstellbar ist
            if (numberOk && formatOk) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(Color.White)
                        .padding(16.dp),
                ) {
                    BarcodeImage(number.trim(), format)
                }
            }

            Button(
                onClick = {
                    if (nameOk && numberOk && formatOk) {
                        onSave(
                            Card(
                                id = existing?.id ?: UUID.randomUUID().toString(),
                                name = name.trim(),
                                number = number.trim(),
                                format = format,
                                color = color,
                                note = note.trim(),
                            )
                        )
                    } else {
                        showErrors = true
                    }
                },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(stringResource(R.string.save))
            }
        }
    }
}

@Composable
private fun FormatPicker(selected: CardFormat, onSelect: (CardFormat) -> Unit) {
    var expanded by rememberSaveable { mutableStateOf(false) }
    Box {
        OutlinedButton(onClick = { expanded = true }, modifier = Modifier.fillMaxWidth()) {
            Text(stringResource(R.string.field_format) + ": " + selected.label)
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            for (option in CardFormat.entries) {
                DropdownMenuItem(
                    text = { Text(option.label) },
                    onClick = {
                        expanded = false
                        onSelect(option)
                    },
                )
            }
        }
    }
}

@Composable
private fun ColorDot(color: Long, selected: Boolean, onClick: () -> Unit) {
    val outline = MaterialTheme.colorScheme.onSurface
    Box(
        modifier = Modifier
            .size(48.dp)
            .then(if (selected) Modifier.border(3.dp, outline, CircleShape) else Modifier)
            .padding(6.dp)
            .clip(CircleShape)
            .background(Color(color))
            .clickable(onClick = onClick),
    )
}
