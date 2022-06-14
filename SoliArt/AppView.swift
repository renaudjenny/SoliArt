import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct AppView: View {
    var body: some View {
        VStack {
            HStack {
                HStack {
                    ForEach(suits) { suit in
                        RoundedRectangle(cornerRadius: 4)
                            .stroke()
                            .frame(width: 50, height: 70)
                            .overlay(
                                suit.view
                                    .fill(style: .init(eoFill: true, antialiased: true))
                                    .foregroundColor(suit.color)
                                    .padding()
                        )
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)

                HStack {
                    CardVerticalDeckView(
                        cards: Array(
                            [StandardDeckCard].standard52Deck(action: { _, _ in })
                                .map {
                                    var card = $0
                                    card.isFacedUp = true
                                    return card
                                }
                                .prefix(3)
                        ),
                        cardHeight: 70,
                        facedDownSpacing: 3,
                        facedUpSpacing: 2
                    )
                    CardVerticalDeckView(
                        cards: Array([StandardDeckCard].standard52Deck(action: { _, _ in }).prefix(3)),
                        cardHeight: 70,
                        facedDownSpacing: 3,
                        facedUpSpacing: 0
                    )
                }
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(height: 150)
            HStack {
                ForEach(decks, id: \.indices) {
                    CardVerticalDeckView(cards: $0, cardHeight: 70, facedDownSpacing: 20, facedUpSpacing: 10)
                }
            }
        }.padding()
    }

    var suits: [StandardDeckCard.Suit] { [.hearts, .spades, .diamonds, .spades] }

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
