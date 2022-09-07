import ComposableArchitecture
import SwiftUI

struct HintState: Equatable {
    var hint: Hint?
    var foundations: IdentifiedArrayOf<Foundation> = []
    var piles: IdentifiedArrayOf<Pile> = []
    var deckUpwards: IdentifiedArrayOf<Card> = []
    var autoFinishAlert: AlertState<HintAction>?
}

enum HintAction: Equatable {
    case hint
    case setHintCardPosition(Hint.Position)
    case removeHint
    case checkForAutoFinish
    case cancelAutoFinish
    case autoFinish
}

struct HintEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
}

let hintReducer = Reducer<HintState, HintAction, HintEnvironment> { state, action, environment in
    enum CancelID {}

    switch action {
    case .hint:
        let pileHints: [Hint] = state.piles.flatMap { pile in
            state.foundations.compactMap { foundation in
                guard let card = pile.cards.last else { return nil }
                return isValidScoring(card: card, onto: foundation)
                ? Hint(
                    card: card,
                    origin: .pile(id: pile.id),
                    destination: .foundation(id: foundation.id),
                    position: .source
                )
                : nil
            }
        }

        let deckHints: [Hint] = state.foundations.compactMap { foundation in
            guard let card = state.deckUpwards.last else { return nil }
            return isValidScoring(card: state.deckUpwards.last, onto: foundation)
            ? Hint(
                card: card,
                origin: .deck,
                destination: .foundation(id: foundation.id),
                position: .source
            )
            : nil
        }

        guard let hint = (pileHints + deckHints).first else { return .none }
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
        .cancellable(id: CancelID.self)
    case let .setHintCardPosition(position):
        state.hint?.position = position
        return .none
    case .removeHint:
        state.hint = nil
        return .none
    case .checkForAutoFinish:
        guard state.piles.flatMap(\.cards).allSatisfy(\.isFacedUp) else { return .none }
        state.autoFinishAlert = .autoFinish
        return .none
    case .cancelAutoFinish:
        state.autoFinishAlert = nil
        return .none
    case .autoFinish:
        state.autoFinishAlert = nil
        return .none
    }
}

extension AppState {
    var hint: HintState {
        get {
            HintState(
                hint: _hint.hint,
                foundations: game.foundations,
                piles: game.piles,
                deckUpwards: game.deck.upwards
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
