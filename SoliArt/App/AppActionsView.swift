import ComposableArchitecture
import SwiftUI

struct AppActionsView: View {
    let store: Store<Void, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                Button { viewStore.send(.history(.undo), animation: .linear) } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .foregroundColor(.white)
                .buttonStyle(.bordered)
                .padding()

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
        AppActionsView(store: Store(
            initialState: AppState(),
            reducer: appReducer,
            environment: .preview
        ).stateless)
    }
}
#endif
