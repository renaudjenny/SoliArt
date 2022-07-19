import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct PilesView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                Color.board.ignoresSafeArea()
                HStack {
                    ForEach(viewStore.piles) { pile in
                        GeometryReader { geo in
                            cards(pile.cards)
                            .task { viewStore.send(.updateFrame(.pile(pile.id, geo.frame(in: .global)))) }
                        }
                    }
                }
                .padding()
            }
        }
    }

    private func cards(_ cards: IdentifiedArrayOf<Card>) -> some View {
        WithViewStore(store) { viewStore in
            ZStack(alignment: .top) {
                ForEach(cards) { card in
                    let content = StandardDeckCardView(card: card, backgroundContent: CardBackground.init)
                        .frame(height: 56)
                        .offset(y: yOffset(cards: cards, card: card))

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

    private func yOffset(cards: IdentifiedArrayOf<Card>, card: Card) -> Double {
        guard let index = cards.index(id: card.id), index > 0 else { return 0 }
        let previous = cards[index - 1]
        return (previous.isFacedUp ? 30 : 20) * Double(cards.firstIndex(of: card) ?? 0)
    }
}
