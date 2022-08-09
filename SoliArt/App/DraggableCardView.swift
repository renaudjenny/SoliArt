import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct DraggableCardView: View {
    let store: Store<AppState, AppAction>
    let card: Card
    let origin: DragCards.Origin // TODO: lets get rid of that

    var body: some View {
        WithViewStore(store) { viewStore in
            StandardDeckCardView(card: card, backgroundContent: CardBackground.init)
                .gesture(DragGesture(coordinateSpace: .global)
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
                        viewStore.send(.dropCards, animation: .spring())
                    })
                .offset(viewStore.draggedCardsOffsets[card] ?? .zero)
                .matchedGeometryEffect(id: card, in: viewStore.namespace!)
        }
    }
}
