import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct DraggableCardView: View {
    let store: Store<DragState, DragAction>
    let card: Card

    var body: some View {
        WithViewStore(store) { viewStore in
            viewStore.namespace.map { namespace in
                StandardDeckCardView(card: card, backgroundContent: CardBackground.init)
                    .gesture(DragGesture(coordinateSpace: .global)
                        .onChanged { value in
                            viewStore.send(.dragCard(card, position: value.location), animation: .interactiveSpring())
                        }
                        .onEnded { value in
                            viewStore.send(.dropCards, animation: .spring())
                        })
                    .opacity(viewStore.draggedCards.contains(card) ? 0 : 1)
                    .matchedGeometryEffect(id: card, in: namespace, isSource: viewStore.draggingState == nil)
            }
        }
    }
}
