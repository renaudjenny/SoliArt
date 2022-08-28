import ComposableArchitecture
import SwiftUI

struct ScoreView: View {
    let store: Store<AppState, AppAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            HStack(spacing: 40) {
                Text("Score: \(viewStore.score.score) points").foregroundColor(.white)
                Text("Moves: \(viewStore.score.moves)").foregroundColor(.white)
                Spacer()
                Button("Hint") { viewStore.send(.hint, animation: .linear) }
            }
            .padding()
            .fixedSize(horizontal: false, vertical: true)
            .background(Color.toolbar, ignoresSafeAreaEdges: .all)
        }
    }
}
