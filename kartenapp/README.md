# Meine Karten

Android-App für Mitglieds- und Bonuskarten (z. B. IKEA Family). Kotlin + Jetpack Compose.

## Funktionen

- Karten anlegen: Barcode/QR-Code per Kamera scannen oder Nummer von Hand eintippen
- 13 Barcode-Typen (Code 128, EAN-13, QR-Code, PDF417, ...)
- Karte antippen zeigt den Code groß auf weißem Grund, Display wird dabei hell gestellt
- Name, Farbe und Notiz pro Karte, bearbeiten und löschen
- Logo bekannter Anbieter (IKEA, PAYBACK, dm, REWE ...) erscheint automatisch, sobald der Kartenname passt
- Kartendaten bleiben lokal auf dem Gerät (`cards.json` im privaten App-Speicher), kein Konto
- Internet wird nur für die Logos genutzt: Die App ruft das Website-Icon des Anbieters über die
  Icon-Dienste von Google und DuckDuckGo ab und sendet dabei nur dessen Domain (z. B. `ikea.com`)

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
