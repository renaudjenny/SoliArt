import ComposableArchitecture
import SwiftUI

struct Drag: ReducerProtocol {
    struct State: Equatable {
        var frames: IdentifiedArrayOf<Frame> = []
        var windowSize: CGSize = .zero
        var draggingState: DraggingState?
        var zIndexPriority: DraggingSource = .pile(id: 1)
        var piles: IdentifiedArrayOf<Pile> = []
        var foundations: IdentifiedArrayOf<Foundation> = []
        var deck = Deck(downwards: [], upwards: [])
    }

    enum Action: Equatable {
        case updateFrames(IdentifiedArrayOf<Frame>)
        case updateWindowSize(CGSize)
        case dragCard(Card, position: CGPoint)
        case dropCards
        case doubleTapCard(Card)
        case resetZIndexPriority
        case score(Score.Action)
    }

    @Dependency(\.mainQueue) var mainQueue: AnySchedulerOf<DispatchQueue>

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .updateFrames(frames):
            state.frames = frames
            return .none
        case let .updateWindowSize(size):
            state.windowSize = size
            return .none
        case let .dragCard(card, position):
            guard card.isFacedUp else { return .none }
            state.draggingState = DraggingState(card: card, position: position)
            state.zIndexPriority = DraggingSource.card(card, in: state)
            return .none
        case .dropCards:
            return state.dropCards(mainQueue: mainQueue)
        case .resetZIndexPriority:
            state.zIndexPriority = .pile(id: 1)
            return .none
        case let .doubleTapCard(card):
            // TODO: add a test for isPileLastCard
            let isPileLastCard = state.piles.first(where: { $0.cards.contains(card) })?.cards.last == card
            // TODO: add a test for isFromDeck
            let isFromDeck = state.deck.upwards.last == card
            guard
                card.isFacedUp,
                isPileLastCard || isFromDeck,
                let foundation = state.foundations.first(where: { $0.suit == card.suit })
            else { return .none }

            return state.move(card: card, foundation: foundation)
        case .score:
            return .none
        }
    }
}

extension Drag.State {
    var cardSize: CGSize {
        let height = min(windowSize.height * 16/100, windowSize.width * 15/100)
        return CGSize(width: height * 5/7, height: height)
    }
}

extension App.State {
    var drag: Drag.State {
        get {
            Drag.State(
                frames: _drag.frames,
                windowSize: _drag.windowSize,
                draggingState: _drag.draggingState,
                zIndexPriority: _drag.zIndexPriority,
                piles: game.piles,
                foundations: game.foundations,
                deck: game.deck
            )
        }
        set {
            (
                _drag.frames,
                _drag.windowSize,
                _drag.draggingState,
                _drag.zIndexPriority,

                game.piles,
                game.foundations,
                game.deck
            ) = (
                newValue.frames,
                newValue.windowSize,
                newValue.draggingState,
                newValue.zIndexPriority,

                newValue.piles,
                newValue.foundations,
                newValue.deck
            )
        }
    }
}
