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
                        .padding(.trailing)
                    Text("Moves: \(viewStore.moves)")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Button { viewStore.send(.history(.undo), animation: .linear) } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }
                    .foregroundColor(.white)
                    .buttonStyle(.bordered)

                    Button("Hint") { viewStore.send(.hint(.hint), animation: .linear) }
                        .foregroundColor(.white)
                        .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .fixedSize(horizontal: false, vertical: true)
            .background(Color.toolbar, ignoresSafeAreaEdges: .all)
        }
    }
}
