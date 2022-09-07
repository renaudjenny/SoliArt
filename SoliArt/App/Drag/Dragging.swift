import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct DraggingState: Equatable {
    let card: Card
    var position: CGPoint
}

enum DraggingSource: Equatable {
    case pile(id: Pile.ID)
    case foundation(id: Foundation.ID)
    case deck
    case removed

    static func card(_ card: Card, in state: DragState) -> Self {
        if let pileID = state.piles.first(where: { $0.cards.contains(card) })?.id {
            return .pile(id: pileID)
        } else if let foundationID = state.foundations.first(where: { $0.cards.contains(card) })?.id {
            return .foundation(id: foundationID)
        } else if state.deckUpwards.contains(card) {
            return .deck
        }
        return .removed
    }
}


extension DragState {
    var draggedCards: [Card] {
        guard let card = draggingState?.card else { return [] }
        switch DraggingSource.card(card, in: self) {
        case let .pile(id):
            guard let pile = piles[id: id], let index = pile.cards.firstIndex(of: card) else { return [] }
            return Array(pile.cards[index...])
        case .foundation, .deck, .removed:
            return [card]
        }
    }

    @discardableResult
    mutating func removePileCards(pileID: Pile.ID, cards: [Card]) -> Bool {
        piles[id: pileID]?.cards.removeAll { cards.contains($0) }
        if var lastCard = piles[id: pileID]?.cards.last {
            lastCard.isFacedUp = true
            piles[id: pileID]?.cards.updateOrAppend(lastCard)
            return true
        }
        return false
    }

    mutating func dropCards(mainQueue: AnySchedulerOf<DispatchQueue>) -> Effect<DragAction, Never> {
        guard let draggingState = draggingState else { return .none }

        let dropFrame = frames.first { frame in
            frame.rect.contains(draggingState.position)
        }

        let dropEffect = Effect<DragAction, Never>(value: .resetZIndexPriority)
            .delay(for: 0.5, scheduler: mainQueue)
            .eraseToEffect()

        switch dropFrame {
        case let .pile(pileID, _):
            let draggedCards = draggedCards
            guard var pile = piles[id: pileID],
                  isValidMove(cards: draggedCards, onto: pile.cards.elements)
            else {
                self.draggingState = nil
                return dropEffect
            }

            let scoringEffect: Effect<DragAction, Never>
            switch DraggingSource.card(draggingState.card, in: self) {
            case let .pile(pileID):
                let hasTurnOverCard = removePileCards(pileID: pileID, cards: draggedCards)
                scoringEffect = hasTurnOverCard
                ? Effect(value: .score(.score(.turnOverPileCard)))
                : Effect(value: .score(.incrementMove))
            case let .foundation(foundationID):
                foundations[id: foundationID]?.cards.remove(draggingState.card)
                scoringEffect = Effect(value: .score(.score(.moveBackFromFoundation)))
            case .deck:
                deckUpwards.remove(draggingState.card)
                scoringEffect = Effect(value: .score(.incrementMove))
            case .removed:
                self.draggingState = nil
                return dropEffect
            }

            pile.cards.append(contentsOf: draggedCards)
            piles.updateOrAppend(pile)

            self.draggingState = nil
            return Effect.merge(dropEffect, scoringEffect)
        case let .foundation(foundationID, _):
            guard let foundation = foundations[id: foundationID], draggedCards.count == 1 else {
                self.draggingState = nil
                return dropEffect
            }
            self.draggingState = nil
            return Effect.merge(dropEffect, move(card: draggingState.card, foundation: foundation))
        case .deck, .none:
            self.draggingState = nil
            return dropEffect
        }
    }

    mutating func move(card: Card, foundation: Foundation) -> Effect<DragAction, Never> {
        guard isValidScoring(card: card, onto: foundation) else { return .none }

        let scoringEffect: Effect<DragAction, Never>
        switch DraggingSource.card(card, in: self) {
        case let .pile(pileID):
            removePileCards(pileID: pileID, cards: [card])
            scoringEffect = Effect(value: .score(.score(.moveToFoundation)))
        case .deck:
            deckUpwards.remove(card)
            scoringEffect = Effect(value: .score(.score(.moveToFoundation)))
        case .foundation, .removed:
            return .none
        }

        var foundation = foundation
        foundation.cards.updateOrAppend(card)
        foundations.updateOrAppend(foundation)

        return scoringEffect
    }
}

private func isValidMove(cards: [Card], onto: [Card]) -> Bool {
    if onto.count == 0, cards.first?.rank == .king { return true }
    guard let first = cards.first, let onto = onto.last, onto.isFacedUp else { return false }

    let isColorDifferent: Bool
    switch first.suit {
    case .clubs, .spades: isColorDifferent = [.diamonds, .hearts].contains(onto.suit)
    case .diamonds, .hearts: isColorDifferent = [.clubs, .spades].contains(onto.suit)
    }

    let isRankLower = first.rank == onto.rank.lower

    return isColorDifferent && isRankLower
}

func isValidScoring(card: Card?, onto foundation: Foundation) -> Bool {
    guard let card = card else { return false }
    let canScore = card.rank == .ace || card.rank.lower == foundation.cards.last?.rank
    return card.suit == foundation.suit && canScore
}

private extension Rank {
    var lower: Rank? {
        guard let index = Rank.allCases.firstIndex(of: self) else { return nil }
        return index > 0 ? Rank.allCases[index - 1] : nil
    }
}