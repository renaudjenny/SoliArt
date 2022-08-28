import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct PilesView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                ForEach(viewStore.piles) { pile in
                    GeometryReader { geo in
                        cards(pileID: pile.id)
                            .frame(maxHeight: 2/5 * geo.size.height, alignment: .top)
                            .task(id: viewStore.frames) {
                                viewStore.send(.updateFrame(.pile(pile.id, geo.frame(in: .global))))
                            }
                    }
                    .ignoresSafeArea()
                    .zIndex(zIndex(priority: viewStore.zIndexPriority, pileID: pile.id))
                }
            }
            .padding()
            .background(Color.board, ignoresSafeAreaEdges: .all)
        }
    }

    private func cards(pileID: Pile.ID) -> some View {
        WithViewStore(store) { viewStore in
            ZStack {
                ForEach(viewStore.state.pileCardsAndOffsets(pileID: pileID), id: \.card.id) { card, offset in
                    DraggableCardView(store: store, card: card)
                        .offset(y: offset)
                        .onTapGesture(count: 2) { viewStore.send(.doubleTapCard(card), animation: .spring()) }
                }
            }
        }
    }

    private func zIndex(priority: DraggingSource, pileID: Pile.ID) -> Double {
        if case let .pile(id) = priority {
            return id == pileID ? 2 : 1
        }
        return 0
    }
}

#if DEBUG
struct PilesView_Previews: PreviewProvider {
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
                PilesView(store: store).onAppear { viewStore.send(.shuffleCards) }
            }
        }
    }
}
#endif
