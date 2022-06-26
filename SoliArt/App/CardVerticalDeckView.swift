import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct CardVerticalDeckView: View {
    let store: Store<AppState, AppAction>

    let cards: [Card]
    let cardHeight: CGFloat
    let facedDownSpacing: CGFloat
    let facedUpSpacing: CGFloat
    private(set) var isInteractionEnabled = true

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack(alignment: .top) {
                Color.clear
                ForEach(cardsAndYOffset, id: \.yOffset) { card, yOffset in
                    let content = card.frame(height: cardHeight).offset(x: 0, y: yOffset)
                    if isInteractionEnabled {
                        content
                        .gesture(DragGesture(coordinateSpace: .global)
                            .onChanged { value in
                                viewStore.send(.dragCard(DragCard(card: card, position: value.location)))
                            }
                            .onEnded { value in
                                viewStore.send(.dragCard(nil))
                            }
                        )
                    } else {
                        content
                    }
                }
            }
        }
    }

    private var cardsAndYOffset: [(card: StandardDeckCard<CardBackground>, yOffset: CGFloat)] {
        cards.reduce([]) { result, card in
            guard let previous = result.last else { return [(card, 0)] }
            let spacing = previous.card.isFacedUp ? facedUpSpacing : facedDownSpacing
            return result + [(card, previous.yOffset + spacing)]
        }
    }
}

#if DEBUG
struct CardVerticalDeckView_Previews: PreviewProvider {
    static var previews: some View {
        Preview(store: Store(
            initialState: AppState(),
            reducer: appReducer,
            environment: .preview
        ))
    }

    private struct Preview: View {
        let store: Store<AppState, AppAction>

        @State private var cards: [StandardDeckCard<CardBackground>] = .standard52Deck
            .enumerated()
            .map { index, card in
                if index == 51 || index == 50 || index == 49 || index == 48 {
                    var lastCard = card
                    lastCard.isFacedUp = true
                    return lastCard
                }
                return card
            }
            .suffix(15)

        var body: some View {
            WithViewStore(store) { viewStore in
                VStack {
                    CardVerticalDeckView(
                        store: store,
                        cards: cards,
                        cardHeight: 250,
                        facedDownSpacing: 6,
                        facedUpSpacing: 50
                    )
                    .padding()

                    Button("Next card") {
                        cards = cards
                            .enumerated()
                            .map { index, card in
                                if index == cards.count - 1 {
                                    return nil
                                } else if index == cards.count - 2 {
                                    var secondCard = card
                                    secondCard.isFacedUp = true
                                    return secondCard
                                }
                                return card
                            }
                            .compactMap { $0 }
                    }.padding()
                }
            }
        }
    }
}
#endif
