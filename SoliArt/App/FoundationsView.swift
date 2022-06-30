import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct FoundationsView: View {
    let store: Store<AppState, AppAction>
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                HStack {
                    ForEach(viewStore.foundations) { foundation in
                        let (suitColor, background) = foundationColors(foundation.suit)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(background)
                            .frame(width: 50, height: 70)
                            .overlay(
                                foundation.suit.view
                                    .fill(style: .init(eoFill: true, antialiased: true))
                                    .foregroundColor(suitColor)
                                    .padding(4)
                            )
                    }
                }
                .frame(maxHeight: .infinity)

                HStack {
                    CardVerticalDeckView(
                        store: store,
                        cards: IdentifiedArrayOf(uniqueElements: viewStore.deck.upwards.suffix(3)),
                        cardHeight: 70,
                        facedDownSpacing: 3,
                        facedUpSpacing: 2
                    )
                    if viewStore.deck.downwards.count > 0 {
                        Button { viewStore.send(.drawCard) } label: {
                            CardVerticalDeckView(
                                store: store,
                                cards: IdentifiedArrayOf(
                                    uniqueElements:viewStore.deck.downwards.prefix(3)
                                ),
                                cardHeight: 70,
                                facedDownSpacing: 3,
                                facedUpSpacing: 0,
                                isInteractionEnabled: false
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button { viewStore.send(.flipDeck) } label: {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green)
                                .frame(width: 50, height: 70)
                                .brightness(-40/100)
                                .overlay(Text("Flip").foregroundColor(.white).padding(4))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .fixedSize(horizontal: true, vertical: true)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .frame(height: 120)
            .background(Color.piles)
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
}
