import ComposableArchitecture
import Foundation

struct History: ReducerProtocol {
    struct State: Equatable {
        var entries: [HistoryEntry] = []
    }

    enum Action: Equatable {
        case addEntry(HistoryEntry)
        case undo
    }
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
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
}
