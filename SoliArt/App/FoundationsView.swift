import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct FoundationsView: View {
    let store: Store<AppState, AppAction>
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                foundations
                deck
            }
            .padding()
            .frame(height: 100)
            .background(Color.piles)
        }
    }

    private var foundations: some View {
        WithViewStore(store) { viewStore in
            HStack {
                ForEach(viewStore.foundations) { foundation in
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(foundationColors(foundation.suit).background)
                            .overlay { overlay(foundation: foundation) }
                            .task { @MainActor in
                                viewStore.send(.updateFrame(
                                    .foundation(foundation.id, geo.frame(in: .global))
                                ))
                            }
                    }
                    .frame(width: 40, height: 56)
                }
            }
        }
    }

    private var deck: some View {
        HStack {
            Spacer()
            deckUpwards.frame(height: 56).offset(x: -30)
            deckDownwards.frame(height: 62).fixedSize()
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
                            .gesture(DragGesture(coordinateSpace: .global)
                                .onChanged { value in
                                    if var draggedCards = viewStore.draggedCards {
                                        draggedCards.position = value.location
                                        viewStore.send(.dragCards(draggedCards))
                                    } else {
                                        viewStore.send(.dragCards(
                                            DragCards(
                                                origin: .deck(cardID: card.id),
                                                position: value.location
                                            )
                                        ))
                                    }
                                }
                                .onEnded { value in
                                    viewStore.send(.dragCards(nil))
                                }
                            )
                            .opacity(
                                viewStore.actualDraggedCards?.contains(card) == true
                                ? 0.5
                                : 1
                            )
                            .offset(x: 10 * Double(upwards.firstIndex(of: card) ?? 0))
                    } else {
                        content.offset(x: 10 * Double(upwards.firstIndex(of: card) ?? 0))
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
                    VStack(spacing: -50) {
                        ForEach(cards) { card in StandardDeckCardView(card: card) { CardBackground() } }
                    }
                }
                .buttonStyle(.plain)
            } else if viewStore.deck.downwards.count == 0 && viewStore.deck.upwards.count > 3 { // TODO: test this
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
                        .gesture(DragGesture(coordinateSpace: .global)
                            .onChanged { value in
                                if var draggedCards = viewStore.draggedCards {
                                    draggedCards.position = value.location
                                    viewStore.send(.dragCards(draggedCards))
                                } else {
                                    viewStore.send(.dragCards(
                                        DragCards(
                                            origin: .foundation(cardID: last.id),
                                            position: value.location
                                        )
                                    ))
                                }
                            }
                            .onEnded { value in
                                viewStore.send(.dragCards(nil))
                            }
                        )
                        .opacity(
                            viewStore.actualDraggedCards?.contains(last) == true
                            ? 0
                            : 1
                        )
                }
            }
        }
    }
}
