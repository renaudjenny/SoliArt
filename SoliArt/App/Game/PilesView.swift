import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct PilesView: View {
    let store: StoreOf<App>
    let namespace: Namespace.ID

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                if viewStore.game.isWinDisplayed {
                    VStack {
                        Text("Congratulation!").font(.title).padding()
                        Text("You finished this game.").font(.title2)
                        Button { viewStore.send(.game(.resetGame)) } label: {
                            Label("New game", systemImage: "suit.spade.fill").foregroundColor(.white)
                        }
                        .padding()
                        .buttonStyle(.bordered)
                    }
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                }
                HStack {
                    ForEach(viewStore.game.piles) { pile in
                        GeometryReader { geo in
                            cards(pileID: pile.id)
                                .padding(.bottom, viewStore.drag.cardSize.height * 2)
                                .frame(maxWidth: .infinity)
                                .preference(
                                    key: FramesPreferenceKey.self,
                                    value: IdentifiedArrayOf(uniqueElements: [.pile(pile.id, geo.frame(in: .global))])
                                )
                        }
                        .ignoresSafeArea()
                        .zIndex(zIndex(priority: viewStore.drag.zIndexPriority, pileID: pile.id))
                    }
                }
            }
            .padding()
            .background(Color.board, ignoresSafeAreaEdges: .all)
        }
    }

    private func cards(pileID: Pile.ID) -> some View {
        WithViewStore(store) { viewStore in
            ZStack {
                ForEach(viewStore.drag.pileCardsAndOffsets(pileID: pileID), id: \.card.id) { card, offset in
                    DraggableCardView(
                        store: store.scope(state: \.drag, action: App.Action.drag),
                        card: card,
                        namespace: namespace
                    )
                    .frame(width: viewStore.drag.cardSize.width, height: viewStore.drag.cardSize.height)
                    .offset(y: offset)
                    .onTapGesture(count: 2) { viewStore.send(.drag(.doubleTapCard(card)), animation: .spring()) }
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
    @Namespace private static var namespace

    static var previews: some View {
        PilesView(store: .startedGame, namespace: namespace)
        PilesView(store: .finishedGame, namespace: namespace)
            .previewDisplayName("Finished game")
    }
}

extension Store where State == App.State, Action == App.Action {
    static var startedGame: Store<App.State, App.Action> {
        Store(initialState: .startedGame, reducer: App())
    }
    static var finishedGame: Store<App.State, App.Action> {
        Store(initialState: .finishedGame, reducer: App())
    }
}
#endif
