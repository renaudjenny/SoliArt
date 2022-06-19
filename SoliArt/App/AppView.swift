import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct AppView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: 0) {
                ZStack {
                    Color.green.brightness(-40/100).ignoresSafeArea()
                    HStack(spacing: 40) {
                        Text("Score: \(viewStore.score) points").foregroundColor(.white)
                        Text("Moves: \(viewStore.moves)").foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                }
                .fixedSize(horizontal: false, vertical: true)

                HStack {
                    HStack {
                        ForEach(viewStore.foundations) { foundation in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 50, height: 70)
                                .overlay(
                                    foundation.suit.view
                                        .fill(style: .init(eoFill: true, antialiased: true))
                                        .foregroundColor(foundation.suit.color)
                                        .padding(4)
                                )
                                .brightness(-20/100)
                        }
                    }
                    .frame(maxHeight: .infinity)

                    HStack {
                        CardVerticalDeckView(
                            cards: Array(viewStore.deck.upwards.prefix(3)),
                            cardHeight: 70,
                            facedDownSpacing: 3,
                            facedUpSpacing: 2
                        )
                        CardVerticalDeckView(
                            cards: Array(viewStore.deck.downwards.prefix(3)),
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
                        ForEach(viewStore.piles) {
                            CardVerticalDeckView(
                                cards: $0.cards.elements,
                                cardHeight: 70,
                                facedDownSpacing: 20,
                                facedUpSpacing: 10
                            )
                        }
                    }
                    .padding()
                }
            }
            .task { viewStore.send(.shuffleCards(.standard52Deck(
                action: { viewStore.send(.cardTapped(rank: $0, suit: $1)) }
            ))) }
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(store: Store(
            initialState: AppState(),
            reducer: appReducer,
            environment: AppEnvironment(shuffleCards: { $0.shuffled() })
        ))
    }
}
