import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct DraggableCardView: View {
    let store: Store<AppState, AppAction>
    let card: Card

    var body: some View {
        WithViewStore(store) { viewStore in
            StandardDeckCardView(card: card, backgroundContent: CardBackground.init)
                .gesture(DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        viewStore.send(.dragCard(card, position: value.location), animation: .interactiveSpring())
                    }
                    .onEnded { value in
                        viewStore.send(.dropCards, animation: .spring())
                    })
                .offset(viewStore.draggedCardsOffsets[card] ?? .zero)
                .matchedGeometryEffect(id: card, in: viewStore.namespace!)
        }
    }
}
