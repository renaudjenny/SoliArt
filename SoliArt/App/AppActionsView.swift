import ComposableArchitecture
import SwiftUI

struct AppActionsView: View {
    let store: Store<App.State, App.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                if viewStore.autoFinish.isAutoFinishAvailable {
                    Button { viewStore.send(.autoFinish(.checkForAutoFinish)) } label: {
                        Label("Auto finish", systemImage: "wand.and.stars").labelStyle(.iconOnly)
                    }
                    .disabled(viewStore._autoFinish.isAutoFinishing)
                    .foregroundColor(.white)
                    .buttonStyle(.bordered)
                    .padding()
                    .confirmationDialog(
                        store.scope(state: { $0._autoFinish.confirmationDialog }, action: App.Action.autoFinish),
                        dismiss: .cancelAutoFinish
                    )
                }

                if !viewStore._autoFinish.isAutoFinishing {
                    Button { viewStore.send(.game(.confirmResetGame)) } label: {
                        Label("Reset", systemImage: "exclamationmark.arrow.circlepath").labelStyle(.iconOnly)
                    }
                    .foregroundColor(.white)
                    .buttonStyle(.bordered)
                    .padding()
                    .confirmationDialog(
                        store.scope(state: \.game.resetGameConfirmationDialog, action: App.Action.game),
                        dismiss: .cancelResetGame
                    )
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
                initialState: App.State(),
                reducer: App()
            ))

            AppActionsView(store: Store(
                initialState: App.State(
                    game: Game.State(
                        foundations: [Foundation(suit: .spades, cards: [])],
                        piles: [Pile(id: 1, cards: [Card(.ace, of: .spades, isFacedUp: true)])]
                    )),
                reducer: App()
            ))
        }
    }
}
#endif
