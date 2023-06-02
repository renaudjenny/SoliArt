import ComposableArchitecture
import SwiftUI

struct Hint: ReducerProtocol {
    struct State: Equatable {
        var hint: HintMove?
        var foundations: IdentifiedArrayOf<Foundation> = []
        var piles: IdentifiedArrayOf<Pile> = []
        var deck = Deck(downwards: [], upwards: [])
    }

    enum Action: Equatable {
        case hint
        case setHintCardPosition(HintMove.Position)
        case removeHint
    }

    @Dependency(\.mainQueue) var mainQueue

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        enum CancelID {
            case hint
        }

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
            .cancellable(id: CancelID.hint)
        case let .setHintCardPosition(position):
            state.hint?.position = position
            return .none
        case .removeHint:
            state.hint = nil
            return .none
        }
    }
}


extension App.State {
    var hint: Hint.State {
        get {
            Hint.State(
                hint: _hint.hint,
                foundations: game.foundations,
                piles: game.piles,
                deck: game.deck
            )
        }
        set { _hint.hint = newValue.hint }
    }

    var hintCardPosition: CGPoint {
        guard let hint = hint.hint else { return .zero }
        switch hint.position {
        case .source: return drag.cardPosition(hint.card)
        case .destination: return drag.destinationPosition(hint.destination)
        }
    }
}
