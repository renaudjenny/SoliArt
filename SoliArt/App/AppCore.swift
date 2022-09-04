import ComposableArchitecture

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
        environment: { HistoryEnvironment(now: $0.now) }
    ),
    Reducer { state, action, environment in
        switch action {
        case .game(.flipDeck):
            return Effect.merge(
                Effect(value: .history(.addEntry(state.game))),
                Effect(value: .score(.score(.recycling)))
            )
        case .game(.resetGame):
            state.score = ScoreState()
            return .none
        case .game(.shuffleCards), .game(.drawCard), .drag(.doubleTapCard), .drag(.dropCards):
            // TODO: add unit test
            guard state.game != state.history.entries.last?.gameState else { return .none }
            return Effect(value: .history(.addEntry(state.game)))
        case .history(.undo):
            // TODO: add unit test
            guard let last = state.history.entries.last else { return .none }
            state.game = last.gameState
            return .none
        case let .drag(.score(action)):
            return Effect(value: .score(action))
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
