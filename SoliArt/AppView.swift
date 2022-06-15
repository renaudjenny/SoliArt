import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct AppView: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.green.brightness(-40/100).ignoresSafeArea()
                HStack(spacing: 40) {
                    Text("Score: \(0) points").foregroundColor(.white)
                    Text("Move: \(0)").foregroundColor(.white)
                    Spacer()
                }
                .padding()
            }
            .fixedSize(horizontal: false, vertical: true)

            HStack {
                HStack {
                    ForEach(suits) { suit in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: 50, height: 70)
                            .overlay(
                                suit.view
                                    .fill(style: .init(eoFill: true, antialiased: true))
                                    .foregroundColor(suit.color)
                                    .padding(4)
                            )
                            .brightness(-20/100)
                    }
                }
                .frame(maxHeight: .infinity)

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
                .fixedSize(horizontal: true, vertical: true)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .frame(height: 120)
            .background(Color.green.brightness(-30/100))

            ZStack {
                Color.green.brightness(-15/100).ignoresSafeArea()
                HStack {
                    ForEach(decks, id: \.indices) {
                        CardVerticalDeckView(cards: $0, cardHeight: 70, facedDownSpacing: 20, facedUpSpacing: 10)
                    }
                }
                .padding()
            }
        }
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
