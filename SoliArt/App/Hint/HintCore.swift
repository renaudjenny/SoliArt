import ComposableArchitecture
import SwiftUI

struct Hint: ReducerProtocol {
    struct State: Equatable {
        var hint: HintMove?
        var autoFinishConfirmationDialog: ConfirmationDialogState<Hint.Action>?
        var isAutoFinishing = false
        var foundations: IdentifiedArrayOf<Foundation> = []
        var piles: IdentifiedArrayOf<Pile> = []
        var deck = Deck(downwards: [], upwards: [])
    }

    enum Action: Equatable {
        case hint
        case setHintCardPosition(HintMove.Position)
        case removeHint
        case checkForAutoFinish
        case cancelAutoFinish
        case autoFinish
        case setAutoFinishHint(HintMove)
        case stopAutoFinish
    }

    @Dependency(\.mainQueue) var mainQueue

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        enum HintCancelID {}
        enum AutoFinishCancelID {}

        switch action {
        case .hint:
            guard let hint = state.hints.first else { return .none }
            state.hint = hint

            return .run { send in
                try await mainQueue.sleep(for: 0.5)
                await send(.setHintCardPosition(.destination), animation: .linear)
                try await mainQueue.sleep(for: 1)
                await send(.setHintCardPosition(.source))
                try await mainQueue.sleep(for: 1)
                await send(.setHintCardPosition(.destination), animation: .linear)
                try await mainQueue.sleep(for: 1)
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
            guard state.isAutoFinishAvailable else { return .none }
            state.autoFinishConfirmationDialog = .autoFinish
            return .none
        case .cancelAutoFinish:
            state.autoFinishConfirmationDialog = nil
            return .none
        case .autoFinish:
            state.isAutoFinishing = true
            state.autoFinishConfirmationDialog = nil
            guard let hint = state.hints.first else { return Effect(value: .stopAutoFinish) }
            return Effect(value: .setAutoFinishHint(hint))
        case .setAutoFinishHint:
            return .none
        case .stopAutoFinish:
            state.isAutoFinishing = false
            return .none
        }
    }
}


extension AppState {
    var hint: Hint.State {
        get {
            Hint.State(
                hint: _hint.hint,
                autoFinishConfirmationDialog: _hint.autoFinishConfirmationDialog,
                isAutoFinishing: _hint.isAutoFinishing,
                foundations: game.foundations,
                piles: game.piles,
                deck: game.deck
            )
        }
        set { (
            _hint.hint,
            _hint.autoFinishConfirmationDialog,
            _hint.isAutoFinishing
        ) = (
            newValue.hint,
            newValue.autoFinishConfirmationDialog,
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
