import SwiftUI
import SwiftUICardGame

struct AppView: View {
    var body: some View {
        VStack {
            HStack {
                CardVerticalDeckView(
                    cards:
                        Array(repeating: StandardDeckCard(.ace, of: .spades, isFacedUp: false, action: {}), count: 2)
                        + [StandardDeckCard(.ace, of: .spades, isFacedUp: true, action: {})],
                    cardHeight: 100,
                    facedDownSpacing: 10,
                    facedUpSpacing: 20
                )
                Spacer()
                HStack {
                    ForEach(StandardDeckCard.Suit.allCases) { suit in
                        suit.view.fill(style: .init(eoFill: true, antialiased: true))
                    }
                }
            }
            HStack {
                ForEach(decks, id: \.indices) {
                    CardVerticalDeckView(cards: $0, cardHeight: 100, facedDownSpacing: 20, facedUpSpacing: 10)
                }
            }
        }.padding()
    }

    var cards: [StandardDeckCard] {
        .standard52Deck(action: { _, _ in })
    }

    var decks: [[StandardDeckCard]] {
        (1...7).map { Array(
            repeating: StandardDeckCard(.ace, of: .spades, isFacedUp: false, action: {}),
            count: $0
        ) }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView()
    }
}
