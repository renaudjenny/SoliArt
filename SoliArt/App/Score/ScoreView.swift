import ComposableArchitecture
import SwiftUI

struct ScoreView: View {
    let store: StoreOf<Score>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                Text("Score: \(viewStore.score) points")
                    .foregroundColor(.white)
                    .padding(.trailing)
                Text("Moves: \(viewStore.moves)")
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .fixedSize(horizontal: false, vertical: true)
            .background(Color.toolbar, ignoresSafeAreaEdges: .all)
        }
    }
}

#if DEBUG
struct ScoreView_Previews: PreviewProvider {
    static var previews: some View {
        ScoreView(store: Store(
            initialState: Score.State(score: 123, moves: 123),
            reducer: Score()
        ))
    }
}
#endif
