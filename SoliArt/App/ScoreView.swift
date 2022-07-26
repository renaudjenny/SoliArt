import ComposableArchitecture
import SwiftUI

struct ScoreView: View {
    let store: Store<AppState, AppAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            HStack(spacing: 40) {
                Text("Score: \(viewStore.score) points").foregroundColor(.white)
                Text("Moves: \(viewStore.moves)").foregroundColor(.white)
                Spacer()
            }
            .padding()
            .fixedSize(horizontal: false, vertical: true)
            .background(Color.toolbar, ignoresSafeAreaEdges: .all)
        }
    }
}
