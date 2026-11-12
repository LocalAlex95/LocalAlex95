# Meine Karten (iOS)

iOS-Version der Karten-App. SwiftUI, ab iOS 17.

## Aufs iPhone bringen (mit Mac)

Voraussetzungen: Xcode aus dem Mac App Store und [Homebrew](https://brew.sh).

```bash
brew install xcodegen
```

```bash
cd kartenapp-ios && xcodegen generate && open Kartenapp.xcodeproj
```

Dann in Xcode:

1. **Xcode > Settings > Accounts**: Apple-ID hinzufügen.
2. Links das Projekt **Kartenapp** anklicken, Target **Kartenapp**, Reiter **Signing & Capabilities**:
   „Automatically manage signing“ anhaken und bei **Team** das eigene Konto wählen.
3. iPhone per Kabel anschließen, am iPhone „Diesem Computer vertrauen“ bestätigen.
4. Am iPhone den Entwicklermodus einschalten:
   **Einstellungen > Datenschutz & Sicherheit > Entwicklermodus** (erscheint, sobald das iPhone mit Xcode verbunden war).
5. Oben in Xcode das iPhone als Ziel wählen und mit **⌘R** starten.

Das Xcode-Projekt wird aus `project.yml` erzeugt und liegt nicht im Repo. Nach `xcodegen generate`
muss das Team in Schritt 2 erneut gewählt werden, solange es nicht in `project.yml` eingetragen ist.

## Tests

In Xcode mit **⌘U**. Der Workflow `Kartenapp iOS bauen` führt sie bei jedem Push im Simulator aus.
