import ComposableArchitecture
import Foundation

struct HistoryState: Equatable {
    var entries: [HistoryEntry] = []
}

enum HistoryAction: Equatable {
    case addEntry(HistoryEntry)
    case undo
}

struct HistoryEnvironment {}

let historyReducer = Reducer<HistoryState, HistoryAction, HistoryEnvironment> { state, action, environment in
    switch action {
    case let .addEntry(entry):
        state.entries.append(entry)
        return .none
    case .undo:
        guard state.entries.count > 1 else { return .none }
        state.entries.removeLast()
        return .none
    }
}
