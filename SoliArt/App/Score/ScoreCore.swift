import ComposableArchitecture

struct ScoreState: Equatable {
    var score = 0
    var move = 0
}

enum ScoreAction: Equatable {
    case score(ScoreType)
    case incrementMove
    case resetMove
}

struct ScoreEnvironment {}

let scoreReducer = Reducer<ScoreState, ScoreAction, ScoreEnvironment> { state, action, environment in
    switch action {
    case let .score(type):
        state.score += type.score
        state.score = max(state.score, 0)
        return .none
    case .incrementMove:
        state.move += 1
        return .none
    case .resetMove:
        state.move = 0
        return .none
    }
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
