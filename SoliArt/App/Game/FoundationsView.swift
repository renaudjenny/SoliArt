import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct FoundationsView: View {
    let store: Store<AppState, AppAction>
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
        WithViewStore(store.scope(state: \.drag, action: AppAction.drag)) { viewStore in
            HStack {
                ForEach(viewStore.foundations) { foundation in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(foundationColors(foundation.suit).background)
                        .overlay { overlay(foundation: foundation) }
                        .aspectRatio(5/7, contentMode: .fit)
                        .frame(width: viewStore.cardWidth)
                        .overlay { GeometryReader { geo in Color.clear.task(id: viewStore.cardWidth) { @MainActor in
                            viewStore.send(.updateFrame(.foundation(foundation.id, geo.frame(in: .global))))
                        }}}
                        .zIndex(zIndex(priority: viewStore.zIndexPriority, foundationID: foundation.id))
                }
            }
        }
    }

    private var deck: some View {
        WithViewStore(store.scope(state: \.drag)) { viewStore in
            HStack {
                Spacer()
                deckUpwards.frame(width: viewStore.cardWidth).padding(.trailing, viewStore.cardWidth * 1/5).zIndex(1)
                deckDownwards.frame(width: viewStore.cardWidth)
            }
            .frame(minHeight: viewStore.cardWidth * 17/10)
        }
    }

    private var deckUpwards: some View {
        WithViewStore(store.scope(state: \.drag, action: AppAction.drag)) { viewStore in
            ZStack {
                ForEach(viewStore.state.deckUpwardsCardsAndOffsets, id: \.card) { card, xOffset, isDraggable in
                    if isDraggable {
                        DraggableCardView(store: store.scope(state: \.drag, action: AppAction.drag), card: card)
                            .onTapGesture(count: 2) { viewStore.send(.doubleTapCard(card), animation: .spring()) }
                            .offset(x: xOffset)
                    } else {
                        StandardDeckCardView(card: card) { EmptyView() }
                            .offset(x: xOffset)
                    }
                }
            }
            .overlay { GeometryReader { geo in Color.clear.task(id: viewStore.cardWidth) { @MainActor in
                viewStore.send(.updateFrame(.deckUpwards(geo.frame(in: .global))))
            }}}
        }
    }

    private var deckDownwards: some View {
        WithViewStore(store) { viewStore in
            if viewStore.game.deck.downwards.count > 0 {
                Button { viewStore.send(.game(.drawCard)) } label: {
                    let cards = IdentifiedArrayOf(uniqueElements:viewStore.game.deck.downwards.prefix(3))
                    ZStack {
                        ForEach(cards) { card in
                            StandardDeckCardView(card: card) { CardBackground() }
                                .offset(y: Double(cards.firstIndex(of: card) ?? 0) * viewStore.drag.cardWidth * 1/10)
                        }
                    }
                }
                .buttonStyle(.plain)
                .overlay { GeometryReader { geo in Color.clear.task(id: viewStore.drag.cardWidth) { @MainActor in
                    viewStore.send(.drag(.updateFrame(.deckDownwards(geo.frame(in: .global)))))
                }}}
            } else if viewStore.game.deck.downwards.count == 0 && viewStore.game.deck.upwards.count > 1 {
                Button { viewStore.send(.game(.flipDeck)) } label: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .aspectRatio(5/7, contentMode: .fit)
                        .brightness(-40/100)
                        .overlay(Text("Flip").foregroundColor(.white).padding(4))
                }
                .buttonStyle(.plain)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green)
                    .aspectRatio(5/7, contentMode: .fit)
                    .brightness(-40/100)
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
                    DraggableCardView(store: store.scope(state: \.drag, action: AppAction.drag), card: last)
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
                VStack(spacing: 0) {
                    FoundationsView(store: store)
                    PilesView(store: store)
                }
                .task { viewStore.send(.game(.shuffleCards)) }
                .task {
                    viewStore.send(.game(.drawCard))
                    viewStore.send(.game(.drawCard))
                    viewStore.send(.game(.drawCard))
                }
            }
        }
    }
}
#endif
