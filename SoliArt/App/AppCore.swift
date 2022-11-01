import ComposableArchitecture
import Foundation
import SwiftUI

struct AppState: Equatable {
    var game = GameState()
    var _drag = DragState()
    var score = ScoreState()
    var _hint = HintState()
    var history = HistoryState()
}

enum AppAction: Equatable {
    case game(GameAction)
    case drag(DragAction)
    case score(ScoreAction)
    case hint(HintAction)
    case history(HistoryAction)
}

struct AppEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let shuffleCards: () -> [Card]
    let now: () -> Date
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    gameReducer.pullback(
        state: \.game,
        action: /AppAction.game,
        environment: { GameEnvironment(mainQueue: $0.mainQueue, shuffleCards: $0.shuffleCards) }
    ),
    dragReducer.pullback(
        state: \.drag,
        action: /AppAction.drag,
        environment: { DragEnvironment(mainQueue: $0.mainQueue) }
    ),
    scoreReducer.pullback(
        state: \.score,
        action: /AppAction.score,
        environment: { _ in ScoreEnvironment() }
    ),
    hintReducer.pullback(
        state: \.hint,
        action: /AppAction.hint,
        environment: { HintEnvironment(mainQueue: $0.mainQueue) }
    ),
    historyReducer.pullback(
        state: \.history,
        action: /AppAction.history,
        environment: { _ in HistoryEnvironment() }
    ),
    Reducer { state, action, environment in
        switch action {
        case .game(.flipDeck):
            return Effect.merge(
                Effect(value: .history(.addEntry(HistoryEntry(
                    date: environment.now(),
                    gameState: state.game,
                    scoreState: state.score
                )))),
                Effect(value: .score(.score(.recycling)))
            )
        case .game(.resetGame):
            state.score = ScoreState()
            return .none
        case .game(.shuffleCards), .game(.drawCard), .drag(.doubleTapCard), .drag(.dropCards):
            guard state.game != state.history.entries.last?.gameState else { return .none }
            return Effect(value: .history(.addEntry(HistoryEntry(
                date: environment.now(),
                gameState: state.game,
                scoreState: state.score
            ))))
        case .history(.undo):
            guard let last = state.history.entries.last else { return .none }
            state.game = last.gameState
            state.score = last.scoreState
            return .none
        case let .drag(.score(action)):
            return Effect(value: .score(action))
        case .hint(.autoFinish):
            let isFlipDeckNeeded = state.game.deck.downwards.count == 0 && state.game.deck.upwards.count > 1
            if isFlipDeckNeeded {
                return .run { send in
                    try await environment.mainQueue.sleep(for: 0.2)
                    await send(.game(.flipDeck))
                    try await environment.mainQueue.sleep(for: 0.2)
                    await send(.hint(.autoFinish))
                }
            }
            return .none
        case let .hint(.setAutoFinishHint(hint)):
            return .run { [frames = state.drag.frames] send in
                let position = hint.destination

                guard position != .deck else {
                    await send(.game(.drawCard))
                    await send(.hint(.autoFinish))
                    return
                }

                let frame = frames.first { frame in
                    switch (hint.destination, frame) {
                    case let (.pile(destinationPileID), .pile(framePileID, _)):
                        return destinationPileID == framePileID
                    case let (.foundation(destinationFoundationID), .foundation(frameFoundationID, _)):
                        return destinationFoundationID == frameFoundationID
                    case (_, _):
                        return false
                    }
                }
                guard let rect = frame?.rect else { return }
                let dragPosition = CGPoint(x: rect.midX, y: rect.midY)
                await send(.drag(.dragCard(hint.card, position: dragPosition)), animation: .linear)
                await send(.drag(.dropCards), animation: .linear)
                try await environment.mainQueue.sleep(for: 0.2)
                await send(.hint(.autoFinish))
            }
        case .game:
            return .none
        case .drag:
            return .none
        case .score:
            return .none
        case .hint:
            return .none
        case .history:
            return .none
        }
    }
)
