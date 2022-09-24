import ComposableArchitecture
import SwiftUI

struct DragState: Equatable {
    var frames: IdentifiedArrayOf<Frame> = []
    var draggingState: DraggingState?
    var zIndexPriority: DraggingSource = .pile(id: 1)
    var namespace: Namespace.ID?
    var piles: IdentifiedArrayOf<Pile> = []
    var foundations: IdentifiedArrayOf<Foundation> = []
    var deck = Deck(downwards: [], upwards: [])
}

enum DragAction: Equatable {
    @available(*, deprecated)
    case updateFrame(Frame)
    case updateFrames(IdentifiedArrayOf<Frame>)
    case dragCard(Card, position: CGPoint)
    case dropCards
    case doubleTapCard(Card)
    case setNamespace(Namespace.ID)
    case resetZIndexPriority
    case score(ScoreAction)
}

struct DragEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
}

let dragReducer = Reducer<DragState, DragAction, DragEnvironment> { state, action, environment in
    switch action {
    case let .updateFrame(frame):
        state.frames.updateOrAppend(frame)
        return .none
    case let .updateFrames(frames):
        state.frames = frames
        return .none
    case let .dragCard(card, position):
        guard card.isFacedUp else { return .none }
        state.draggingState = DraggingState(card: card, position: position)
        state.zIndexPriority = DraggingSource.card(card, in: state)
        return .none
    case .dropCards:
        return state.dropCards(mainQueue: environment.mainQueue)
    case .resetZIndexPriority:
        state.zIndexPriority = .pile(id: 1)
        return .none
    case let .doubleTapCard(card):
        guard
            card.isFacedUp,
            let foundation = state.foundations.first(where: { $0.suit == card.suit })
        else { return .none }

        return state.move(card: card, foundation: foundation)
    case let .setNamespace(namespace):
        state.namespace = namespace
        return .none
    case .score:
        return .none
    }
}

extension DragState {
    var cardSize: CGSize {
        guard let rect = frames.first(where: { if case .pile = $0 { return true } else { return false } })?.rect
        else { return .zero }
        let height: CGFloat
        if ProcessInfo.processInfo.isiOSAppOnMac {
            height = max(100, min(rect.height/3, rect.width * 7/5))
        } else {
            height = min(rect.height/3, rect.width * 7/5)
        }
        return CGSize(width: height * 5/7, height: height)
    }
}

extension AppState {
    var drag: DragState {
        get {
            DragState(
                frames: _drag.frames,
                draggingState: _drag.draggingState,
                zIndexPriority: _drag.zIndexPriority,
                namespace: _drag.namespace,
                piles: game.piles,
                foundations: game.foundations,
                deck: game.deck
            )
        }
        set {
            (
                _drag.frames,
                _drag.draggingState,
                _drag.zIndexPriority,
                _drag.namespace,

                game.piles,
                game.foundations,
                game.deck
            ) = (
                newValue.frames,
                newValue.draggingState,
                newValue.zIndexPriority,
                newValue.namespace,

                newValue.piles,
                newValue.foundations,
                newValue.deck
            )
        }
    }
}
