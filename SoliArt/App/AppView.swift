import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct AppView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                content
                draggedCards
//                debugDragFrames
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
            }
        }
    }

    private var draggedCards: some View {
        WithViewStore(store) { viewStore in
            if let position = viewStore.draggedCards?.position, let cards = viewStore.actualDraggedCards {
                ZStack {
                    ForEach(cards) { card in
                        StandardDeckCardView(card: card, backgroundContent: { EmptyView() })
                            .frame(width: viewStore.cardWidth)
                            .offset(y: (viewStore.cardWidth * 2/5 + 4) * CGFloat(cards.firstIndex(of: card) ?? 0))
                    }
                }
                .position(position)
                .offset(y: -viewStore.cardWidth * 2/5 - 4 - 20)
                .ignoresSafeArea()
            }
        }
    }

    private var debugDragFrames: some View {
        WithViewStore(store) { viewStore in
            ForEach(viewStore.frames) { frame in
                switch frame {
                case let .foundation(id, rect):
                    Color.red
                        .overlay { Text(id) }
                        .frame(width: rect.width, height: rect.height)
                        .position(CGPoint(x: rect.midX, y: rect.midY))
                case let .pile(id, rect):
                    Color.blue
                        .overlay { Text("Pile \(id)") }
                        .frame(width: rect.width, height: rect.height)
                        .position(CGPoint(x: rect.midX, y: rect.midY))
                }
            }
            .ignoresSafeArea()
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

extension AppState {
    static let almostFinishedGame = AppState(
        foundations: IdentifiedArrayOf(uniqueElements: Suit.allCases.map {
            Foundation(suit: $0, cards: .allButLast(for: $0))
        }),
        piles: IdentifiedArrayOf<Pile>(uniqueElements: (1...7).map { Pile(id: $0, cards: []) }),
        deck: Deck(
            downwards: IdentifiedArrayOf(uniqueElements: [Card(.king, of: .clubs, isFacedUp: false)]),
            upwards: IdentifiedArrayOf(uniqueElements: [
                Card(.king, of: .diamonds, isFacedUp: true),
                Card(.king, of: .hearts, isFacedUp: true),
                Card(.king, of: .spades, isFacedUp: true)
            ])
        ),
        isGameOver: false
    )
}

private extension IdentifiedArray where Element == Card {
    static var all: IdentifiedArrayOf<Card> {
        IdentifiedArrayOf(uniqueElements: Suit.allCases.flatMap { suit in
            Rank.allCases.map { rank in
                StandardDeckCard(rank, of: suit, isFacedUp: true)
            }
        })
    }

    static func allButLast(for suit: Suit) -> IdentifiedArrayOf<Card> {
        IdentifiedArrayOf(uniqueElements: Rank.allCases.map { rank in
            StandardDeckCard(rank, of: suit, isFacedUp: true)
        }.dropLast())
    }
}
#endif
