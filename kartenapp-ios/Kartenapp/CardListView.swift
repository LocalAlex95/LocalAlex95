import SwiftUI

struct CardListView: View {
    @Environment(CardStore.self) private var store
    @State private var showingAdd = false
    @State private var path: [String] = []

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if store.cards.isEmpty {
                    ContentUnavailableView {
                        Label("Noch keine Karten", systemImage: "creditcard")
                    } description: {
                        Text("Lege deine erste Mitglieds- oder Bonuskarte an, zum Beispiel per Barcode-Scan.")
                    } actions: {
                        Button("Karte hinzufügen") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(store.cards) { card in
                                NavigationLink(value: card.id) {
                                    CardTile(card: card)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Meine Karten")
            .navigationDestination(for: String.self) { id in
                CardDetailView(cardID: id)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Karte hinzufügen", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                CardEditView(existing: nil) { card in
                    store.save(card)
                    path = [card.id]
                }
            }
        }
    }
}

private struct CardTile: View {
    let card: Card

    var body: some View {
        VStack(spacing: 8) {
            BrandLogo(cardName: card.name, size: 40)
            Text(card.name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(contentColor(onARGB: card.color))
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1.586, contentMode: .fit) // Scheckkartenformat
        .background(Color(argb: card.color), in: RoundedRectangle(cornerRadius: 12))
    }
}
