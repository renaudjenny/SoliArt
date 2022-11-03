import ComposableArchitecture

struct Score: ReducerProtocol {
    struct State: Equatable {
        var score = 0
        var moves = 0
    }

    enum Action: Equatable {
        case score(ScoreType)
        case incrementMove
        case resetMove
    }

    enum ScoreType {
        case moveToFoundation
        case turnOverPileCard
        case moveBackFromFoundation
        case recycling

        var score: Int {
            switch self {
            case .moveToFoundation: return 10
            case .turnOverPileCard: return 5
            case .moveBackFromFoundation: return -15
            case .recycling: return -100
            }
        }
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .score(type):
            state.score += type.score
            state.score = max(state.score, 0)
            return type == .recycling ? .none : Effect(value: .incrementMove)
        case .incrementMove:
            state.moves += 1
            return .none
        case .resetMove:
            state.moves = 0
            return .none
        }
    }
}
