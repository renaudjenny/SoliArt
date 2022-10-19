import ComposableArchitecture
import SwiftUI

struct AppActionsView: View {
    let store: Store<HintState, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                if viewStore.isAutoFinishAvailable {
                    Button { viewStore.send(.hint(.checkForAutoFinish)) } label: {
                        Label("Auto finish", systemImage: "wand.and.stars").labelStyle(.iconOnly)
                    }
                    .disabled(viewStore.isAutoFinishing)
                    .foregroundColor(.white)
                    .buttonStyle(.bordered)
                    .padding()
                }

                if !viewStore.isAutoFinishing {
                    Button { viewStore.send(.game(.confirmResetGame)) } label: {
                        Label("Reset", systemImage: "exclamationmark.arrow.circlepath").labelStyle(.iconOnly)
                    }
                    .foregroundColor(.white)
                    .buttonStyle(.bordered)
                    .padding()
                }

                Spacer()

                Button { viewStore.send(.history(.undo), animation: .linear) } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward").labelStyle(.iconOnly)
                }
                .foregroundColor(.white)
                .buttonStyle(.bordered)
                .padding([.vertical, .leading])

                Button("Hint") { viewStore.send(.hint(.hint), animation: .linear) }
                    .foregroundColor(.white)
                    .buttonStyle(.bordered)
                    .padding()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(Color.toolbar, ignoresSafeAreaEdges: .all)
        }
    }
}

#if DEBUG
struct AppActionsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AppActionsView(store: Store(
                initialState: AppState(),
                reducer: appReducer,
                environment: .preview
            ).scope(state: \.hint))

            AppActionsView(store: Store(
                initialState: AppState(
                    game: GameState(
                        foundations: [Foundation(suit: .spades, cards: [])],
                        piles: [Pile(id: 1, cards: [Card(.ace, of: .spades, isFacedUp: true)])]
                    )),
                reducer: appReducer,
                environment: .preview
            ).scope(state: \.hint))
        }
    }
}
#endif
