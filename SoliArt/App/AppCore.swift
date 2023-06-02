import ComposableArchitecture
import Foundation
import SwiftUI

struct App: ReducerProtocol {
    struct State: Equatable {
        var game = Game.State()
        var _drag = Drag.State()
        var score = Score.State()
        var _hint = Hint.State()
        var history = History.State()
        var _autoFinish = AutoFinish.State()
    }

    enum Action: Equatable {
        case game(Game.Action)
        case drag(Drag.Action)
        case score(Score.Action)
        case hint(Hint.Action)
        case history(History.Action)
        case autoFinish(AutoFinish.Action)
    }

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.date) var date

    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.game, action: /Action.game) {
            Game()
        }
        Scope(state: \.drag, action: /Action.drag) {
            Drag()
        }
        Scope(state: \.score, action: /Action.score) {
            Score()
        }
        Scope(state: \.hint, action: /Action.hint) {
            Hint()
        }
        Scope(state: \.history, action: /Action.history) {
            History()
        }
        Scope(state: \.autoFinish, action: /Action.autoFinish) {
            AutoFinish()
        }
        Reduce { state, action in
            switch action {
            case .game(.flipDeck):
                return .merge(
                    addHistoryEntry(state: &state),
                    flipDeck(state: &state)
                )
            case .game(.resetGame):
                state.score = Score.State()
                return .none
            case .game(.shuffleCards), .game(.drawCard), .drag(.doubleTapCard), .drag(.dropCards):
                guard state.game != state.history.entries.last?.gameState else { return .none }
                return addHistoryEntry(state: &state)
            case .history(.undo):
                guard let last = state.history.entries.last else { return .none }
                state.game = last.gameState
                state.score = last.scoreState
                return .none
            case let .drag(.score(action)):
                // TODO: check score actions and find a better way to share actions between drag and score
                return Effect(value: .score(action))
            case .autoFinish(.autoFinish):
                guard let hint = state.hint.hints.first else { return .none }

                return .run { [frames = state.drag.frames] send in
                    let position = hint.destination

                    guard position != .deck else {
                        await send(.game(.drawCard))
                        await send(.autoFinish(.autoFinish))
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
                    try await mainQueue.sleep(for: 0.2)
                    await send(.autoFinish(.autoFinish))
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
            case .autoFinish:
                return .none
            }
        }
    }

    private func addHistoryEntry(state: inout State) -> EffectTask<Action> {
        state.history.entries.append(HistoryEntry(
            date: date(),
            gameState: state.game,
            scoreState: state.score
        ))
        return .none
    }

    private func flipDeck(state: inout State) -> EffectTask<Action> {
        state.score.score += Score.ScoreType.recycling.score
        state.score.score = max(state.score.score, 0)
        return .none
    }
}
