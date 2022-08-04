import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct PilesView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                ForEach(viewStore.piles) { pile in
                    GeometryReader { geo in
                        cards(pileID: pile.id, origin: geo.frame(in: .global).origin)
                            .frame(maxHeight: 2/5 * geo.size.height, alignment: .top)
                            .task(id: viewStore.frames) {
                                viewStore.send(.updateFrame(.pile(pile.id, geo.frame(in: .global))))
                            }
                    }
                    .zIndex({
                        let cards = viewStore.piles[id: pile.id]?.cards ?? []
                        return Set(viewStore.draggedCards?.origin.cards ?? []).intersection(cards).count > 0 ? 1 : 0
                    }())
                    .ignoresSafeArea()
                }
            }
            .padding()
            .background(Color.board, ignoresSafeAreaEdges: .all)
        }
    }

    private func cards(pileID: Pile.ID, origin: CGPoint) -> some View {
        WithViewStore(store) { viewStore in
            ZStack {
                let cards = viewStore.piles[id: pileID]?.cards ?? []
                let spacing = viewStore.cardWidth * 2/5 + 4
                ForEach(cardsAndOffsets(cards: cards, spacing: spacing), id: \.card.id) { card, offset in
                    let view = StandardDeckCardView(card: card, backgroundContent: CardBackground.init)
                        .offset(y: offset)
                    if let cardIndex = cards.firstIndex(of: card), card.isFacedUp {
                        view.modifier(AddDragCards(
                            store: store,
                            origin: .pile(id: pileID, cards: Array(cards[cardIndex...]))
                        ))
                    } else {
                        view
                    }
                }
            }
        }
    }

    private func cardsAndOffsets(cards: IdentifiedArrayOf<Card>, spacing: Double) -> [(card: Card, yOffset: Double)] {
        cards.reduce([]) { result, card in
            guard let previous = result.last else { return [(card, 0)] }
            let spacing: Double = previous.card.isFacedUp ? spacing : 5
            return result + [(card, previous.yOffset + spacing)]
        }
    }
}

#if DEBUG
struct PilesView_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    private struct Preview: View {
        let store = Store(
            initialState: AppState(),
            reducer: appReducer,
            environment: .preview
        )

        var body: some View {
            WithViewStore(store) { viewStore in
                PilesView(store: store).onAppear { viewStore.send(.shuffleCards) }
            }
        }
    }
}
#endif
