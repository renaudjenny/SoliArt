import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct AppView: View {
    let store: Store<AppState, AppAction>
    @Namespace private var namespace

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                content
                draggedCards
                hint
            }
            .task { viewStore.send(.game(.shuffleCards)) }
            .task { viewStore.send(.drag(.setNamespace(namespace))) }
            .confirmationDialog(
                store.scope(state: \.game.resetGameConfirmationDialog, action: AppAction.game),
                dismiss: .cancelResetGame
            )
            .confirmationDialog(
                store.scope(state: { $0._hint.autoFinishConfirmationDialog }, action: AppAction.hint),
                dismiss: .cancelAutoFinish
            )
        }
    }

    private var content: some View {
        WithViewStore(store) { viewStore in
            GeometryReader { geo in
                VStack(spacing: 0) {
                    ScoreView(store: store.actionless.scope(state: \.score))
                    FoundationsView(store: store).zIndex(foundationIndex(priority: viewStore.drag.zIndexPriority))
                    PilesView(store: store)
                    AppActionsView(store: store.scope(state: \.hint))
                }
                .preference(key: WindowSizePreferenceKey.self, value: geo.size)
            }
            .onPreferenceChange(FramesPreferenceKey.self) { frames in
                viewStore.send(.drag(.updateFrames(frames)))
            }
            .onPreferenceChange(WindowSizePreferenceKey.self) { size in
                viewStore.send(.drag(.updateWindowSize(size)))
            }
        }
    }

    private var draggedCards: some View {
        WithViewStore(store.scope(state: \.drag)) { viewStore in
            if let position = viewStore.draggingState?.position {
                let spacing = viewStore.cardSize.width * 2/5 + 4
                let yOffset = viewStore.cardSize.width * 7/15

                ForEach(viewStore.draggedCards) { card in
                    StandardDeckCardView(card: card, backgroundContent: EmptyView.init)
                        .frame(width: viewStore.cardSize.width, height: viewStore.cardSize.height)
                        .offset(y: (-yOffset) + Double(viewStore.draggedCards.firstIndex(of: card) ?? 0) * spacing)
                        .matchedGeometryEffect(id: card, in: namespace)
                        .position(position)
                }
                .ignoresSafeArea()
            }
        }
    }

    private func foundationIndex(priority: DraggingSource) -> Double {
        switch priority {
        case .pile, .removed: return 0
        case .foundation, .deckUpwards, .deckDownwards: return 1
        }
    }

    private var hint: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                if let hint = viewStore.hint.hint {
                    StandardDeckCardView(card: hint.card, backgroundContent: EmptyView.init)
                        .frame(width: viewStore.drag.cardSize.width, height: viewStore.drag.cardSize.height)
                        .position(viewStore.hintCardPosition)
                }
            }
            .ignoresSafeArea()
        }
    }

    #if DEBUG
    private var debugDragFrames: some View {
        WithViewStore(store.scope(state: \.drag)) { viewStore in
            ForEach(viewStore.frames) { frame in
                VStack {
                    switch frame {
                    case let .foundation(id, _):
                        Color.red.overlay { Text(id) }
                    case let .pile(id, _):
                        Color.blue.overlay { Text("Pile \(id)") }
                    case .deckUpwards:
                        Color.green.overlay { Text("Deck U") }
                    case .deckDownwards:
                        Color.yellow.overlay { Text("Deck D") }
                    }
                }
                .frame(width: frame.rect.width, height: frame.rect.height)
                .position(CGPoint(x: frame.rect.midX, y: frame.rect.midY))
            }
            .ignoresSafeArea()
        }
    }
    #endif
}

struct FramesPreferenceKey: PreferenceKey {
    static var defaultValue: IdentifiedArrayOf<Frame> = []
    static func reduce(value: inout IdentifiedArrayOf<Frame>, nextValue: () -> IdentifiedArrayOf<Frame>) {
        value.append(contentsOf: nextValue())
    }
}

struct WindowSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private extension Frame {
    var isPile: Bool { if case .pile = self { return true } else { return false } }
}

#if DEBUG
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(store: Store(
            initialState: AppState(),
            reducer: appReducer,
            environment: .preview
        ))
    }
}

extension AppEnvironment {
    static let preview = AppEnvironment(
        mainQueue: .main,
        shuffleCards: { .standard52Deck.shuffled() },
        now: Date.init
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
        },
        now: Date.init
    )
}

extension AppState {
    static let almostFinishedGame = AppState(
        game: GameState(
            foundations: IdentifiedArrayOf(uniqueElements: Suit.allCases.map { suit in
                Foundation(
                    suit: suit,
                    cards: IdentifiedArrayOf(uniqueElements: Rank.allCases.map { rank in
                        StandardDeckCard(rank, of: suit, isFacedUp: true)
                    }.dropLast(2))
                )
            }),
            piles: [
                Pile(id: 1, cards: [Card(.queen, of: .clubs, isFacedUp: true)]),
                Pile(id: 2, cards: [Card(.queen, of: .diamonds, isFacedUp: true)]),
                Pile(id: 3, cards: [Card(.queen, of: .hearts, isFacedUp: true)]),
                Pile(id: 4, cards: [Card(.queen, of: .spades, isFacedUp: true)]),
                Pile(id: 5, cards: []),
                Pile(id: 6, cards: []),
                Pile(id: 7, cards: [])
            ],
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
    )

    static let finishedGame = AppState(game: GameState(
        foundations: IdentifiedArrayOf(uniqueElements: Suit.allCases.map { suit in
            Foundation(
                suit: suit,
                cards: IdentifiedArrayOf(uniqueElements: Rank.allCases.map { rank in
                    StandardDeckCard(rank, of: suit, isFacedUp: true)
                })
            )
        }),
        isGameOver: false
    ))

    static let startedGame = AppState(
        game: GameState(foundations: .startedGame, piles: .startedGame, deck: .startedGame, isGameOver: false),
        _drag: DragState(windowSize: CGSize(width: 300, height: 500), namespace: namespace)
    )

    @Namespace private static var namespace: Namespace.ID
}

private extension IdentifiedArray<Foundation.ID, Foundation> {
    static let startedGame: Self = IdentifiedArrayOf(uniqueElements: [
        Foundation(
            suit: .hearts,
            cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.ace, of: .hearts, isFacedUp: true),
            ])
        ),
        Foundation(suit: .clubs, cards: []),
        Foundation(
            suit: .diamonds,
            cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.ace, of: .diamonds, isFacedUp: true),
                StandardDeckCard(.two, of: .diamonds, isFacedUp: true),
            ])
        ),
        Foundation(
            suit: .spades,
            cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.ace, of: .spades, isFacedUp: true),
                StandardDeckCard(.two, of: .spades, isFacedUp: true),
                StandardDeckCard(.three, of: .spades, isFacedUp: true),
                StandardDeckCard(.four, of: .spades, isFacedUp: true),
            ])
        ),
    ])
}

private extension IdentifiedArray<Pile.ID, Pile> {
    static let startedGame: Self = IdentifiedArrayOf(uniqueElements: [
        Pile(
            id: 1,
            cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.four, of: .hearts, isFacedUp: true),
            ])
        ),
        Pile(
            id: 2,
            cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.two, of: .clubs, isFacedUp: false),
                StandardDeckCard(.ace, of: .clubs, isFacedUp: true),
            ])
        ),
        Pile(
            id: 3,
            cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.five, of: .clubs, isFacedUp: false),
                StandardDeckCard(.four, of: .clubs, isFacedUp: false),
                StandardDeckCard(.three, of: .clubs, isFacedUp: true),
            ])
        ),
        Pile(
            id: 4,
            cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.king, of: .clubs, isFacedUp: true),
                StandardDeckCard(.queen, of: .hearts, isFacedUp: true),
                StandardDeckCard(.jack, of: .clubs, isFacedUp: true),
                StandardDeckCard(.ten, of: .hearts, isFacedUp: true),
                StandardDeckCard(.nine, of: .clubs, isFacedUp: true),
            ])
        ),
        Pile(
            id: 5,
            cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.king, of: .spades, isFacedUp: true),
                StandardDeckCard(.queen, of: .diamonds, isFacedUp: true),
                StandardDeckCard(.jack, of: .spades, isFacedUp: true),
                StandardDeckCard(.ten, of: .diamonds, isFacedUp: true),
                StandardDeckCard(.nine, of: .spades, isFacedUp: true),
            ])
        ),
        Pile(id: 6, cards: []),
        Pile(
            id: 7,
            cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.eight, of: .clubs, isFacedUp: false),
                StandardDeckCard(.seven, of: .clubs, isFacedUp: false),
                StandardDeckCard(.six, of: .clubs, isFacedUp: false),
                StandardDeckCard(.eight, of: .diamonds, isFacedUp: false),
                StandardDeckCard(.seven, of: .diamonds, isFacedUp: false),
                StandardDeckCard(.six, of: .diamonds, isFacedUp: false),
                StandardDeckCard(.five, of: .hearts, isFacedUp: true),
            ])
        ),
    ])
}

private extension Deck {
    static let startedGame = Deck(
        downwards: IdentifiedArrayOf(uniqueElements: [Card].standard52Deck.filter { card in
            !IdentifiedArray<Foundation.ID, Foundation>.startedGame.flatMap(\.cards).contains(where: {
                $0.rank == card.rank && $0.suit == card.suit
            })
            && !IdentifiedArray<Pile.ID, Pile>.startedGame.flatMap(\.cards).contains(where: {
                $0.rank == card.rank && $0.suit == card.suit
            })
        }),
        upwards: []
    )
}
#endif
