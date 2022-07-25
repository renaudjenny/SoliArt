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
                        cards(pileID: pile.id)
                            .task { viewStore.send(.updateFrame(.pile(pile.id, geo.frame(in: .global)))) }
                    }
                }
            }
            .padding()
            .background(Color.board, ignoresSafeAreaEdges: .bottom)
        }
    }

    private func cards(pileID: Pile.ID) -> some View {
        WithViewStore(store) { viewStore in
            ZStack(alignment: .top) {
                let cards = viewStore.piles[id: pileID]?.cards ?? []
                ForEach(cardsAndOffsets(cards: cards), id: \.card.id) { card, offset in
                    let content = StandardDeckCardView(card: card, backgroundContent: CardBackground.init)
                        .frame(height: 56)
                        .offset(y: offset)

                    content
                        .gesture(DragGesture(coordinateSpace: .global)
                            .onChanged { value in
                                if var draggedCards = viewStore.draggedCards {
                                    draggedCards.position = value.location
                                    viewStore.send(.dragCards(draggedCards))
                                } else {
                                    guard let cardIndex = cards.firstIndex(of: card) else { return }
                                    viewStore.send(.dragCards(DragCards(
                                        origin: .pile(cardIDs: cards[cardIndex...].map(\.id)),
                                        position: value.location
                                    )))
                                }
                            }
                            .onEnded { value in
                                viewStore.send(.dragCards(nil))
                            })
                        .opacity(viewStore.actualDraggedCards?.contains(card) ?? false
                                 ? 50/100
                                 : 100/100
                        )
                }
            }
        }
    }

    private func cardsAndOffsets(cards: IdentifiedArrayOf<Card>) -> [(card: Card, yOffset: Double)] {
        cards.reduce([]) { result, card in
            guard let previous = result.last else { return [(card, 0)] }
            let spacing: Double = previous.card.isFacedUp ? 20 : 5
            return result + [(card, previous.yOffset + spacing)]
        }
    }
}
