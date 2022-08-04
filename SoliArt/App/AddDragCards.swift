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
            .offset(viewStore.draggedCards.map { draggedCards in
                guard
                    draggedCards.origin == origin,
                    let origin = origin.frame(state: viewStore.state)?.rect.origin
                else { return .zero }
                let position = draggedCards.position
                let width = position.x - origin.x - viewStore.cardWidth/2
                let height = position.y - origin.y - viewStore.cardWidth * 7/5
                return CGSize(width: width, height: height)
            } ?? .zero)
        }
    }
}

private extension DragCards.Origin {
    func frame(state: AppState) -> Frame? {
        switch self {
        case let .pile(id: pileID, _):
            return state.frames.first { frame in
                if case let .pile(id, _) = frame, id == pileID {
                    return true
                } else {
                    return false
                }
            }
        case let.foundation(id: foundationID, _):
            return state.frames.first { frame in
                if case let .foundation(id, _) = frame, id == foundationID {
                    return true
                } else {
                    return false
                }
            }
        case .deck:
            return state.frames.first { if case .deck = $0 { return true } else { return false } }
        }
    }
}
