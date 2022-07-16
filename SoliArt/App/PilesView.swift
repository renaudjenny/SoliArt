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
                                cards: pile.cards,
                                cardHeight: 56,
                                facedDownSpacing: 20,
                                facedUpSpacing: 30
                            )
                            .task { viewStore.send(.updateFrame(.pile(pile.id, geo.frame(in: .global)))) }
                        }
                    }
                }
                .padding()
            }
        }
    }
}
