import ComposableArchitecture
import SwiftUI

struct ScoreView: View {
    let store: Store<ScoreState, AppAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            HStack(spacing: 40) {
                HStack {
                    Text("Score: \(viewStore.score) points")
                        .foregroundColor(.white)
                    Spacer()
                    Text("Moves: \(viewStore.moves)")
                        .foregroundColor(.white)
                }
                Spacer()
                Button { viewStore.send(.history(.undo), animation: .linear) } label: {
                    Label("Undo", image: "arrow.uturn.backward")
                }
                Button("Hint") { viewStore.send(.hint(.hint), animation: .linear) }
                    .foregroundColor(.white)
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .fixedSize(horizontal: false, vertical: true)
            .background(Color.toolbar, ignoresSafeAreaEdges: .all)
        }
    }
}
