import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct AppView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                content
                if let position = viewStore.draggedCards?.position, let cards = viewStore.actualDraggedCards {
                    GeometryReader { geo in
                        CardVerticalDeckView(
                            store: store,
                            cards: cards,
                            cardHeight: 70,
                            facedDownSpacing: 0,
                            facedUpSpacing: 20
                        )
                        .position(position.applying(CGAffineTransform(translationX: 0, y: geo.size.height/2 - 80)))
                    }
                }
            }
            .task { viewStore.send(.shuffleCards) }
        }
    }

    private var content: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: 0) {
                ScoreView(store: store)
                FoundationsView(store: store)
                PilesView(store: store)
                Button { viewStore.send(.turnOverRandomCard) } label: {
                    Text("Turn over a random card")
                }
                Text("Faced up cards: \(viewStore.piles.flatMap(\.cards).filter(\.isFacedUp).count)")
            }
        }
    }
}

#if DEBUG
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(store: Store(
            initialState: AppState(),
            reducer: appReducer,
            environment: AppEnvironment(
                mainQueue: .main,
                shuffleCards: { .standard52Deck.shuffled() }
            )
        ))
    }
}

extension AppEnvironment {
    static let preview = AppEnvironment(
        mainQueue: .main,
        shuffleCards: { .standard52Deck.shuffled() }
    )

    static let superEasyGame = AppEnvironment(
        mainQueue: .main,
        shuffleCards: {
            var cards = Rank.allCases.flatMap { rank in
                Suit.allCases.map { suit in
                    StandardDeckCard(rank, of: suit, isFacedUp: false)
                }
            }
            cards.swapAt(5, 1)
            cards.swapAt(9, 3)
            cards.swapAt(14, 1)
            cards.swapAt(20, 4)
            cards.swapAt(27, 6)
            return cards
        }
    )
}
#endif
