import SwiftUI

struct CardDetailView: View {
    let cardID: String

    @Environment(CardStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var confirmDelete = false
    @State private var previousBrightness: CGFloat?

    var body: some View {
        Group {
            if let card = store.card(id: cardID) {
                content(card)
            } else {
                Color.clear
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: brighten)
        .onDisappear(perform: restoreBrightness)
    }

    private func content(_ card: Card) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                // Immer weißer Hintergrund, auch im dunklen Design, damit die Kasse scannen kann
                VStack(spacing: 16) {
                    BrandLogo(cardName: card.name, size: 56)
                    BarcodeView(content: card.number, format: card.format)
                    Text(card.number)
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .textSelection(.enabled)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))

                Text(card.format.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !card.note.isEmpty {
                    Text(card.note)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .navigationTitle(card.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showingEdit = true
                } label: {
                    Label("Bearbeiten", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Löschen", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            CardEditView(existing: card) { store.save($0) }
        }
        .confirmationDialog("Karte löschen?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                store.delete(id: card.id)
                dismiss()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("„\(card.name)“ wird dauerhaft entfernt.")
        }
    }

    /// Dreht die Displayhelligkeit hoch und hält den Bildschirm an, solange der Barcode zu sehen ist.
    private func brighten() {
        if previousBrightness == nil {
            previousBrightness = UIScreen.main.brightness
        }
        UIScreen.main.brightness = 1
        UIApplication.shared.isIdleTimerDisabled = true
    }

    private func restoreBrightness() {
        if let previousBrightness {
            UIScreen.main.brightness = previousBrightness
        }
        previousBrightness = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
