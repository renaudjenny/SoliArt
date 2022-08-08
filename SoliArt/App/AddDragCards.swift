import ComposableArchitecture
import SwiftUI

struct AddDragCards: ViewModifier {
    let store: Store<AppState, AppAction>
    let origin: DragCards.Origin

    func body(content: Content) -> some View {
        WithViewStore(store) { viewStore in
            content.gesture(DragGesture(coordinateSpace: .global)
                .onChanged { value in
                    if var draggedCards = viewStore.draggedCards {
                        draggedCards.position = value.location
                        viewStore.send(.dragCards(draggedCards), animation: .interactiveSpring())
                    } else {
                        viewStore.send(
                            .dragCards(DragCards(origin: origin, position: value.location)),
                            animation: .spring()
                        )
                    }
                }
                .onEnded { value in
                    viewStore.send(.dragCards(nil), animation: .spring())
                })
            .offset(viewStore.draggedCardsOffsets.first(where: { $0.key ~= origin })?.value ?? .zero)
            .matchedGeometryEffect(id: origin.cards, in: viewStore.namespace!)
        }
    }
}
