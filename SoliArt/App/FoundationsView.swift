import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct FoundationsView: View {
    let store: Store<AppState, AppAction>
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                foundations.zIndex(viewStore.state.zIndex(source: .foundation(nil)))
                deck.zIndex(viewStore.state.zIndex(source: .deck))
            }
            .padding()
            .background(Color.piles)
        }
    }

    private var foundations: some View {
        WithViewStore(store) { viewStore in
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
                        .zIndex(viewStore.state.zIndex(source: .foundation(foundation.id)))
                }
            }
        }
    }

    private var deck: some View {
        WithViewStore(store) { viewStore in
            HStack {
                Spacer()
                deckUpwards.frame(width: viewStore.cardWidth).offset(x: -10).zIndex(1)
                deckDownwards.frame(width: viewStore.cardWidth)
            }
        }
    }

    private var deckUpwards: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                let upwards = IdentifiedArrayOf(uniqueElements: viewStore.deck.upwards.suffix(3))
                ForEach(upwards) { card in
                    let content = StandardDeckCardView(card: card) { EmptyView() }

                    if card == viewStore.deck.upwards.last {
                        content
                            .modifier(AddDragCards(store: store, origin: .deck(card: card)))
                            .overlay { GeometryReader { geo in Color.clear.task(id: viewStore.cardWidth) { @MainActor in
                                viewStore.send(.updateFrame(.deck(geo.frame(in: .global))))
                            }}}
                            .offset(x: 5 * Double(upwards.firstIndex(of: card) ?? 0))
                    } else {
                        content.offset(x: 5 * Double(upwards.firstIndex(of: card) ?? 0))
                    }
                }
            }
        }
    }

    private var deckDownwards: some View {
        WithViewStore(store) { viewStore in
            if viewStore.deck.downwards.count > 0 {
                Button { viewStore.send(.drawCard) } label: {
                    let cards = IdentifiedArrayOf(uniqueElements:viewStore.deck.downwards.prefix(3))
                    ZStack {
                        ForEach(cards) { card in
                            StandardDeckCardView(card: card) { CardBackground() }
                                .offset(y: Double(cards.firstIndex(of: card) ?? 0) * 5)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else if viewStore.deck.downwards.count == 0 && viewStore.deck.upwards.count > 1 {
                Button { viewStore.send(.flipDeck) } label: {
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
                    StandardDeckCardView(card: last) { EmptyView() }
                        .modifier(AddDragCards(store: store, origin: .foundation(id: foundation.id, card: last)))
                }
            }
        }
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
                .onAppear { viewStore.send(.shuffleCards) }
                .onAppear { viewStore.send(.drawCard); viewStore.send(.drawCard); viewStore.send(.drawCard) }
            }
        }
    }
}
#endif
