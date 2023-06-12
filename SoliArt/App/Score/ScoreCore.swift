import ComposableArchitecture

// This should actually be a state only, in App directly
struct Score: ReducerProtocol {
    struct State: Equatable {
        var score = 0
        var moves = 0
    }

    typealias Action = Never

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        return .none
    }
}
