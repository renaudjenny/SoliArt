import ComposableArchitecture
import SwiftUI

struct PilesView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                Color.board.ignoresSafeArea()
                HStack {
                    ForEach(viewStore.piles) { pile in
                        GeometryReader { geo in
                            CardVerticalDeckView(
                                store: store,
                                cards: pile.cards.elements,
                                cardHeight: 70,
                                facedDownSpacing: 20,
                                facedUpSpacing: 10
                            )
                            .task { viewStore.send(.updateFrame(.pile(pile, geo.frame(in: .global)))) }
                        }
                    }
                }
                .padding()
            }
        }
    }
}
