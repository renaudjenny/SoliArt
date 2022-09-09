import ComposableArchitecture
import Foundation

struct HistoryState: Equatable {
    var entries: [HistoryEntry] = []
}

enum HistoryAction: Equatable {
    case addEntry(GameState)
    case undo
}

struct HistoryEnvironment {
    var now: () -> Date
}

let historyReducer = Reducer<HistoryState, HistoryAction, HistoryEnvironment> { state, action, environment in
    switch action {
    case let .addEntry(gameState):
        state.entries.append(HistoryEntry(date: environment.now(), gameState: gameState))
        return .none
    case .undo:
        guard state.entries.count > 1 else { return .none }
        state.entries.removeLast()
        return .none
    }
}
