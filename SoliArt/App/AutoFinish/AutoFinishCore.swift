import ComposableArchitecture
import SwiftUI

struct AutoFinish: ReducerProtocol {
    struct State: Equatable {
        var confirmationDialog: ConfirmationDialogState<Action>?
        var isAutoFinishing = false
        var foundations: IdentifiedArrayOf<Foundation> = []
        var piles: IdentifiedArrayOf<Pile> = []
        var deck = Deck(downwards: [], upwards: [])
        var nextHint: HintMove?
    }

    enum Action: Equatable {
        case checkForAutoFinish
        case autoFinish
        case cancelAutoFinish
    }

    @Dependency(\.mainQueue) var mainQueue

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .checkForAutoFinish:
            guard state.isAutoFinishAvailable else { return .none }
            state.confirmationDialog = .autoFinish
            return .none
        case .autoFinish:
            state.confirmationDialog = nil
            state.isAutoFinishing = state.nextHint != nil
            return .none
        case .cancelAutoFinish:
            state.confirmationDialog = nil
            return .none
        }
    }
}


extension App.State {
    var autoFinish: AutoFinish.State {
        get {
            AutoFinish.State(
                confirmationDialog: _autoFinish.confirmationDialog,
                isAutoFinishing: _autoFinish.isAutoFinishing,
                foundations: game.foundations,
                piles: game.piles,
                deck: game.deck,
                nextHint: hint.hints.first
            )
        }
        set { (
            _autoFinish.confirmationDialog,
            _autoFinish.isAutoFinishing
        ) = (
            newValue.confirmationDialog,
            newValue.isAutoFinishing
        )}
    }
}

extension AutoFinish.State {
    var isAutoFinishAvailable: Bool {
        piles.count > 0 && piles.flatMap(\.cards).allSatisfy(\.isFacedUp)
    }
}
