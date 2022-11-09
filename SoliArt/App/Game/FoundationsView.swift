import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct FoundationsView: View {
    let store: StoreOf<App>
    let namespace: Namespace.ID
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                foundations.zIndex(zIndex(priority: viewStore.drag.zIndexPriority))
                deck
            }
            .padding()
            .background(Color.piles)
        }
    }

    private var foundations: some View {
        WithViewStore(store.scope(state: \.drag, action: App.Action.drag)) { viewStore in
            HStack {
                ForEach(viewStore.foundations) { foundation in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(foundationColors(foundation.suit).background)
                        .frame(width: viewStore.cardSize.width, height: viewStore.cardSize.height)
                        .overlay { overlay(foundation: foundation) }
                        .overlay { GeometryReader { geo in Color.clear.preference(
                            key: FramesPreferenceKey.self,
                            value: IdentifiedArrayOf(
                                uniqueElements: [.foundation(foundation.id, geo.frame(in: .global))]
                            )
                        )}}
                        .zIndex(zIndex(priority: viewStore.zIndexPriority, foundationID: foundation.id))
                }
            }
        }
    }

    private var deck: some View {
        WithViewStore(store.scope(state: \.drag)) { viewStore in
            HStack {
                Spacer()
                deckUpwards
                    .frame(width: viewStore.cardSize.width, height: viewStore.cardSize.height)
                    .padding(.trailing, viewStore.cardSize.width * 1/5)
                    .zIndex(1)
                deckDownwards
                    .frame(width: viewStore.cardSize.width, height: viewStore.cardSize.height * 1.3)
            }
        }
    }

    private var deckUpwards: some View {
        WithViewStore(store.scope(state: \.drag, action: App.Action.drag)) { viewStore in
            ZStack {
                ForEach(viewStore.state.deckUpwardsCardsAndOffsets, id: \.card) { card, xOffset, isDraggable in
                    if isDraggable {
                        DraggableCardView(
                            store: store.scope(state: \.drag, action: App.Action.drag),
                            card: card,
                            namespace: namespace
                        )
                        .onTapGesture(count: 2) { viewStore.send(.doubleTapCard(card), animation: .spring()) }
                        .offset(x: xOffset)
                    } else {
                        StandardDeckCardView(card: card) { EmptyView() }
                            .offset(x: xOffset)
                    }
                }
            }
            .overlay { GeometryReader { geo in Color.clear.preference(
                key: FramesPreferenceKey.self,
                value: IdentifiedArrayOf(uniqueElements: [.deckUpwards(geo.frame(in: .global))])
            )}}
        }
    }

    private var deckDownwards: some View {
        WithViewStore(store) { viewStore in
            if viewStore.game.deck.downwards.count > 0 {
                Button { viewStore.send(.game(.drawCard)) } label: {
                    let cards = IdentifiedArrayOf(uniqueElements:viewStore.game.deck.downwards.prefix(3))
                    ZStack {
                        ForEach(cards) { card in
                            StandardDeckCardView(card: card) { CardBackground() }.offset(
                                y: Double(cards.firstIndex(of: card) ?? 0) * viewStore.drag.cardSize.width * 1/10
                            )
                        }
                    }
                }
                .buttonStyle(.plain)
                .overlay { GeometryReader { geo in Color.clear.preference(
                    key: FramesPreferenceKey.self,
                    value: IdentifiedArrayOf(uniqueElements: [.deckDownwards(geo.frame(in: .global))])
                )}}
            } else if viewStore.game.deck.downwards.count == 0 && viewStore.game.deck.upwards.count > 1 {
                Button { viewStore.send(.game(.flipDeck)) } label: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .brightness(-40/100)
                        .frame(width: viewStore.drag.cardSize.width, height: viewStore.drag.cardSize.height)
                        .overlay(Text("Flip").foregroundColor(.white).padding(4))
                }
                .buttonStyle(.plain)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green)
                    .brightness(-40/100)
                    .frame(width: viewStore.drag.cardSize.width, height: viewStore.drag.cardSize.height)
            }
        }
    }

    private func foundationColors(_ suit: Suit) -> (suitColor: Color, background: Color) {
        let suitColor: Color
        switch (suit, colorScheme) {
        case (.clubs, .light), (.spades, .light):
            suitColor = Color(red: 120/255, green: 134/255, blue: 142/255)
        case (.hearts, .light), (.diamonds, .light):
            suitColor = Color(red: 191/255, green: 155/255, blue: 181/255)
        case (.clubs, .dark), (.spades, .dark):
            suitColor = Color(red: 11/255, green: 16/255, blue: 45/255)
        case (.hearts, .dark), (.diamonds, .dark):
            suitColor = Color(red: 65/255, green: 19/255, blue: 58/255)
        case (_, _):
            suitColor = .black
        }
        let background = colorScheme == .dark
            ? Color(red: 17/255, green: 25/255, blue: 59/255)
            : Color(red: 185/255, green: 206/255, blue: 207/255)
        return (suitColor, background)
    }

    private func overlay(foundation: Foundation) -> some View {
        WithViewStore(store) { viewStore in
            ZStack {
                foundation.suit.view
                    .fill(style: .init(eoFill: true, antialiased: true))
                    .foregroundColor(foundationColors(foundation.suit).suitColor)
                    .padding(4)

                if foundation.cards.count > 1 {
                    let previous = foundation.cards[foundation.cards.count - 2]
                    StandardDeckCardView(card: previous) { EmptyView() }
                }

                foundation.cards.last.map { last in
                    DraggableCardView(
                        store: store.scope(state: \.drag, action: App.Action.drag),
                        card: last,
                        namespace: namespace
                    )
                }
            }
        }
    }

    private func zIndex(priority: DraggingSource, foundationID: Foundation.ID? = nil) -> Double {
        if case let .foundation(id) = priority {
            return id == foundationID ? 2 : 1
        }
        return 0
    }
}

#if DEBUG
struct FoundationsView_Previews: PreviewProvider {
    @Namespace private static var namespace

    static var previews: some View {
        let store1 = Store(
            initialState: .previewWithDrawnCards,
            reducer: App()
        )
        VStack(spacing: 0) {
            FoundationsView(store: store1, namespace: namespace)
            PilesView(store: store1, namespace: namespace)
        }
        .previewDisplayName("With Drawn Cards")

        let store2 = Store(
            initialState: .previewWithAllCardsDrawned,
            reducer: App()
        )
        VStack(spacing: 0) {
            FoundationsView(store: store2, namespace: namespace)
            PilesView(store: store2, namespace: namespace)
        }
        .previewDisplayName("With All Cards Drawn")

        let store3 = Store(
            initialState: .previewWithAnEmptyDeck,
            reducer: App()
        )
        VStack(spacing: 0) {
            FoundationsView(store: store3, namespace: namespace)
            PilesView(store: store3, namespace: namespace)
        }
        .previewDisplayName("With Empty Deck")
    }
}

extension App.State {
    static var previewWithDrawnCards: Self {
        App.State(
            game: .previewWithDrawnCards,
            _drag: Drag.State(windowSize: UIScreen.main.bounds.size)
        )
    }

    static var previewWithAllCardsDrawned: Self {
        App.State(
            game: .previewWithAllCardsDrawned,
            _drag: Drag.State(windowSize: UIScreen.main.bounds.size)
        )
    }

    static var previewWithAnEmptyDeck: Self {
        App.State(
            game: .previewWithEmptyDeck,
            _drag: Drag.State(windowSize: UIScreen.main.bounds.size)
        )
    }

    @Namespace private static var namespace: Namespace.ID
}

extension Game.State {
    static var previewWithDrawnCards: Self {
        Game.State(
                foundations: .preview,
                piles: .preview,
                deck: Deck(
                    downwards: [
                        Card(.ace, of: .hearts, isFacedUp: false),
                        Card(.two, of: .hearts, isFacedUp: false),
                        Card(.three, of: .hearts, isFacedUp: false),
                    ],
                    upwards: [
                        Card(.five, of: .hearts, isFacedUp: true),
                        Card(.six, of: .hearts, isFacedUp: true),
                        Card(.seven, of: .hearts, isFacedUp: true),
                    ]
                ),
                isGameOver: false
            )
    }

    static var previewWithAllCardsDrawned: Self {
        Game.State(
                foundations: .preview,
                piles: .preview,
                deck: Deck(
                    downwards: [],
                    upwards: [
                        Card(.seven, of: .hearts, isFacedUp: true),
                        Card(.five, of: .hearts, isFacedUp: true),
                        Card(.six, of: .hearts, isFacedUp: true)
                    ]
                ),
                isGameOver: false
            )
    }

    static var previewWithEmptyDeck: Self {
        Game.State(
                foundations: .preview,
                piles: .preview,
                deck: Deck(
                    downwards: [],
                    upwards: [Card(.seven, of: .hearts, isFacedUp: true)]
                ),
                isGameOver: false
            )
    }
}

extension IdentifiedArrayOf where Element == Foundation {
    static var preview: IdentifiedArrayOf<Foundation> {
        IdentifiedArrayOf(uniqueElements: [
            Foundation(suit: .hearts, cards: []),
            Foundation(suit: .clubs, cards: []),
            Foundation(suit: .diamonds, cards: []),
            Foundation(suit: .spades, cards: []),
        ])
    }
}

extension IdentifiedArrayOf where Element == Pile {
    static var preview: IdentifiedArrayOf<Pile> {
        [
            Pile(
                id: 1,
                cards: [
                    StandardDeckCard(.four, of: .hearts, isFacedUp: true),
                ]
            ),
            Pile(
                id: 2,
                cards: [
                    StandardDeckCard(.two, of: .clubs, isFacedUp: false),
                    StandardDeckCard(.ace, of: .clubs, isFacedUp: true),
                ]
            ),
            Pile(
                id: 3,
                cards: [
                    StandardDeckCard(.five, of: .clubs, isFacedUp: false),
                    StandardDeckCard(.four, of: .clubs, isFacedUp: false),
                    StandardDeckCard(.three, of: .clubs, isFacedUp: true),
                ]
            ),
            Pile(
                id: 4,
                cards: [
                    StandardDeckCard(.king, of: .clubs, isFacedUp: false),
                    StandardDeckCard(.queen, of: .hearts, isFacedUp: false),
                    StandardDeckCard(.jack, of: .clubs, isFacedUp: false),
                    StandardDeckCard(.ten, of: .hearts, isFacedUp: true),
                ]
            ),
            Pile(
                id: 5,
                cards: [
                    StandardDeckCard(.king, of: .spades, isFacedUp: false),
                    StandardDeckCard(.queen, of: .diamonds, isFacedUp: false),
                    StandardDeckCard(.jack, of: .spades, isFacedUp: false),
                    StandardDeckCard(.ten, of: .diamonds, isFacedUp: false),
                    StandardDeckCard(.nine, of: .spades, isFacedUp: true),
                ]
            ),
            Pile(
                id: 6,
                cards: [
                    StandardDeckCard(.six, of: .hearts, isFacedUp: false),
                    StandardDeckCard(.five, of: .diamonds, isFacedUp: false),
                    StandardDeckCard(.four, of: .diamonds, isFacedUp: false),
                    StandardDeckCard(.three, of: .diamonds, isFacedUp: false),
                    StandardDeckCard(.two, of: .diamonds, isFacedUp: false),
                    StandardDeckCard(.ace, of: .diamonds, isFacedUp: true),
                ]
            ),
            Pile(
                id: 7,
                cards: [
                    StandardDeckCard(.eight, of: .clubs, isFacedUp: false),
                    StandardDeckCard(.seven, of: .clubs, isFacedUp: false),
                    StandardDeckCard(.six, of: .clubs, isFacedUp: false),
                    StandardDeckCard(.eight, of: .diamonds, isFacedUp: false),
                    StandardDeckCard(.seven, of: .diamonds, isFacedUp: false),
                    StandardDeckCard(.six, of: .diamonds, isFacedUp: false),
                    StandardDeckCard(.five, of: .hearts, isFacedUp: true),
                ]
            ),
        ]
    }
}
#endif
