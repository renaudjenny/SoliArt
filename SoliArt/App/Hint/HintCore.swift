import ComposableArchitecture
import SwiftUI

struct HintState: Equatable {
    var hint: Hint?
    var autoFinishAlert: AlertState<HintAction>?
    var isAutoFinishing = false
    var foundations: IdentifiedArrayOf<Foundation> = []
    var piles: IdentifiedArrayOf<Pile> = []
    var deckUpwards: IdentifiedArrayOf<Card> = []
}

enum HintAction: Equatable {
    case hint
    case setHintCardPosition(Hint.Position)
    case removeHint
    case checkForAutoFinish
    case cancelAutoFinish
    case autoFinish
    case setAutoFinishHint(Hint)
    case stopAutoFinish
}

struct HintEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
}

let hintReducer = Reducer<HintState, HintAction, HintEnvironment> { state, action, environment in
    enum HintCancelID {}
    enum AutoFinishCancelID {}

    switch action {
    case .hint:
        guard let hint = state.hints.first else { return .none }
        state.hint = hint

        return .run { send in
            try await environment.mainQueue.sleep(for: 0.5)
            await send(.setHintCardPosition(.destination), animation: .linear)
            try await environment.mainQueue.sleep(for: 1)
            await send(.setHintCardPosition(.source))
            try await environment.mainQueue.sleep(for: 1)
            await send(.setHintCardPosition(.destination), animation: .linear)
            try await environment.mainQueue.sleep(for: 1)
            await send(.removeHint)
        }
        .cancellable(id: HintCancelID.self)
    case let .setHintCardPosition(position):
        state.hint?.position = position
        return .none
    case .removeHint:
        state.hint = nil
        return .none
    case .checkForAutoFinish:
        guard state.piles.flatMap(\.cards).allSatisfy(\.isFacedUp), !state.isAutoFinishing else { return .none }
        state.autoFinishAlert = .autoFinish
        return .none
    case .cancelAutoFinish:
        state.autoFinishAlert = nil
        return .none
    case .autoFinish:
        state.isAutoFinishing = true
        state.autoFinishAlert = nil
        guard let hint = state.hints.first else { return Effect(value: .stopAutoFinish) }
        return Effect(value: .setAutoFinishHint(hint))
    case let .setAutoFinishHint(hint):
        return .none
    case .stopAutoFinish:
        state.isAutoFinishing = false
        return .none
    }
}

extension AppState {
    var hint: HintState {
        get {
            HintState(
                hint: _hint.hint,
                autoFinishAlert: _hint.autoFinishAlert,
                isAutoFinishing: _hint.isAutoFinishing,
                foundations: game.foundations,
                piles: game.piles,
                deckUpwards: game.deck.upwards
            )
        }
        set { (
            _hint.hint,
            _hint.autoFinishAlert,
            _hint.isAutoFinishing
        ) = (
            newValue.hint,
            newValue.autoFinishAlert,
            newValue.isAutoFinishing
        )}
    }

    var hintCardPosition: CGPoint {
        guard let hint = hint.hint else { return .zero }
        switch hint.position {
        case .source: return drag.cardPosition(hint.card)
        case .destination: return drag.destinationPosition(hint.destination)
        }
    }
}
