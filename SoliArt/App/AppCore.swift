import ComposableArchitecture

struct AppState: Equatable {
    var game = GameState()
    var _drag = DragState()
    var score = ScoreState()
    var _hint = HintState()
}

enum AppAction: Equatable {
    case game(GameAction)
    case drag(DragAction)
    case score(ScoreAction)
    case hint(HintAction)
}

struct AppEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let shuffleCards: () -> [Card]
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
    Reducer { state, action, environment in
        switch action {
        case .game(.flipDeck):
            return Effect(value: .score(.score(.recycling)))
        case .game(.resetGame):
            state.score = ScoreState()
            return .none
        case .game:
            return .none
        case let .drag(.score(action)):
            return Effect(value: .score(action))
        case .drag:
            return .none
        case .score:
            return .none
        case .hint:
            return .none
        }
    }
)
