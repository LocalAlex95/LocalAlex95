import SwiftUI

struct CardEditView: View {
    let existing: Card?
    let onSave: (Card) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var number: String
    @State private var format: CardFormat
    @State private var color: Int64
    @State private var note: String
    @State private var showingScanner = false

    init(existing: Card?, onSave: @escaping (Card) -> Void) {
        self.existing = existing
        self.onSave = onSave
        _name = State(initialValue: existing?.name ?? "")
        _number = State(initialValue: existing?.number ?? "")
        _format = State(initialValue: existing?.format ?? .code128)
        _color = State(initialValue: existing?.color ?? Card.colors[0])
        _note = State(initialValue: existing?.note ?? "")
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedNumber: String { number.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var formatOK: Bool { BarcodeEncoder.isValid(trimmedNumber, format: format) }
    private var canSave: Bool { !trimmedName.isEmpty && !trimmedNumber.isEmpty && formatOK }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showingScanner = true
                    } label: {
                        Label("Barcode scannen", systemImage: "barcode.viewfinder")
                    }
                }

                Section("Name") {
                    HStack {
                        TextField("z. B. IKEA Family", text: $name)
                        // Logo erscheint, sobald der Name zu einem bekannten Anbieter passt
                        BrandLogo(cardName: name, size: 32)
                    }
                    let suggestions = Brands.suggest(name)
                    if !suggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(suggestions, id: \.self) { brand in
                                    Button(brand.name) { name = brand.name }
                                        .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }

                Section {
                    TextField("Kartennummer / Code-Inhalt", text: $number, axis: .vertical)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Picker("Barcode-Typ", selection: $format) {
                        ForEach(CardFormat.allCases) { Text($0.label).tag($0) }
                    }
                } header: {
                    Text("Code")
                } footer: {
                    if !trimmedNumber.isEmpty && !formatOK {
                        Text("Die Nummer passt nicht zum gewählten Barcode-Typ.")
                            .foregroundStyle(.red)
                    }
                }

                Section("Farbe") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Card.colors, id: \.self) { option in
                                Circle()
                                    .fill(Color(argb: option))
                                    .frame(width: 36, height: 36)
                                    .padding(4)
                                    .overlay {
                                        if option == color {
                                            Circle().stroke(Color.primary, lineWidth: 3)
                                        }
                                    }
                                    .onTapGesture { color = option }
                                    .accessibilityAddTraits(option == color ? [.isButton, .isSelected] : .isButton)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Notiz (optional)") {
                    TextField("Notiz", text: $note, axis: .vertical)
                        .lineLimit(2...6)
                }

                // Vorschau, sobald der Code darstellbar ist
                if formatOK {
                    Section("Vorschau") {
                        BarcodeView(content: trimmedNumber, format: format)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                            .listRowInsets(EdgeInsets())
                    }
                }
            }
            .navigationTitle(existing == nil ? "Karte hinzufügen" : "Karte bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern", action: save).disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingScanner) {
                ScannerSheet { scannedNumber, scannedFormat in
                    number = scannedNumber
                    if let scannedFormat { format = scannedFormat }
                }
            }
        }
    }

    private func save() {
        onSave(Card(
            id: existing?.id ?? UUID().uuidString,
            name: trimmedName,
            number: trimmedNumber,
            format: format,
            color: color,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        dismiss()
    }
}
