# Meine Karten

Android-App für Mitglieds- und Bonuskarten (z. B. IKEA Family). Kotlin + Jetpack Compose.

## Funktionen

- Karten anlegen: Barcode/QR-Code per Kamera scannen oder Nummer von Hand eintippen
- 13 Barcode-Typen (Code 128, EAN-13, QR-Code, PDF417, ...)
- Karte antippen zeigt den Code groß auf weißem Grund, Display wird dabei hell gestellt
- Name, Farbe und Notiz pro Karte, bearbeiten und löschen
- Daten bleiben lokal auf dem Gerät (`cards.json` im privaten App-Speicher), kein Konto, kein Internet

## Bauen

```bash
./gradlew assembleDebug
```

Die APK liegt danach unter `app/build/outputs/apk/debug/app-debug.apk`.

Bei jedem Push baut außerdem der GitHub-Actions-Workflow `Kartenapp bauen` die Debug-APK
und hängt sie als Artefakt `kartenapp-debug-apk` an den Workflow-Lauf.

## Tests

```bash
./gradlew testDebugUnitTest
```
