import ComposableArchitecture

struct HistoryState: Equatable {
    var entries: [HistoryEntry] = []
}

enum HistoryAction: Equatable {
    case addEntry(GameState)
}

struct HistoryEnvironment {
    let now: () -> Date
}

let historyReducer = Reducer<HistoryState, HistoryAction, HistoryEnvironment> { state, action, environment in
    switch action {
    case let .addEntry(gameState):
        state.entries.append(HistoryEntry(date: environment.now(), gameState: gameState))
        return .none
    }
}
