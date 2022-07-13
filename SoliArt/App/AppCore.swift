import ComposableArchitecture
import SwiftUICardGame
import SwiftUI

struct AppState: Equatable {
    var foundations = IdentifiedArrayOf<Foundation>(
        uniqueElements: Suit.orderedCases.map { Foundation(suit: $0, cards: []) }
    )
    var piles = IdentifiedArrayOf<Pile>(uniqueElements: (1...7).map { Pile(id: $0, cards: []) })
    var deck = Deck(downwards: [], upwards: [])
    var score = 0
    var moves = 0
    var frames: IdentifiedArrayOf<Frame> = []
    var draggedCards: DragCards?
}

enum AppAction: Equatable {
    case shuffleCards
    case drawCard
    case flipDeck
    case updateFrame(Frame)
    case dragCards(DragCards?)
    case dropCards(DragCards)
}

struct AppEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let shuffleCards: () -> [Card]
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    switch action {
    case .shuffleCards:
        var cards = environment.shuffleCards()

        state.piles = IdentifiedArrayOf(uniqueElements: state.piles.map {
            var pile = $0
            pile.cards = IdentifiedArrayOf(uniqueElements: cards[..<$0.id])
            cards = Array(cards[$0.id...])

            if var last = pile.cards.last {
                last.isFacedUp = true
                pile.cards.updateOrAppend(last)
            }

            return pile
        })

        state.deck.downwards = IdentifiedArrayOf(uniqueElements: cards)

        return .none
    case .drawCard:
        let cards = state.deck.downwards
        guard cards.count > 0 else { return .none }

        let upwardsToAdd: [Card] = cards[..<1].map {
            var card = $0
            card.isFacedUp = true
            return card
        }
        state.deck.upwards = IdentifiedArrayOf(uniqueElements: state.deck.upwards.elements + upwardsToAdd)
        state.deck.downwards = IdentifiedArrayOf(uniqueElements: cards[1...])
        return .none
    case .flipDeck:
        state.deck.downwards = IdentifiedArrayOf(uniqueElements: state.deck.upwards.map {
            var card = $0
            card.isFacedUp = false
            return card
        })
        state.deck.upwards = []
        return Effect(value: .drawCard).delay(for: 0.4, scheduler: environment.mainQueue).eraseToEffect()
    case let .updateFrame(frame):
        state.frames.updateOrAppend(frame)
        return .none
    case let .dragCards(dragCards):
        if dragCards == nil {
            let draggedCards = state.draggedCards
            state.draggedCards = nil
            return draggedCards.map { Effect(value: .dropCards($0)) } ?? .none
        } else {
            state.draggedCards = dragCards
            return .none
        }
    case let .dropCards(dragCards):
        let dropFrame = state.frames.first { frame in
            frame.rect.contains(dragCards.position)
        }
        switch dropFrame {
        case let .pile(pileID, _):
            guard var pile = state.piles[id: pileID] else { return .none }
            let cards = dragCards.cardIDs.compactMap(state.card(id:))
            guard isValidMove(cards: cards, onto: pile.cards.elements) else { return .none }

            switch dragCards.origin {
            case let .pile(cardIDs): state.removeCardsFromPile(cardIDs: cardIDs)
            case let .foundation(cardID): state.removeCardFromFoundation(cardID: cardID)
            case let .deck(cardID): state.deck.upwards.remove(id: cardID)
            }

            pile.cards.append(contentsOf: cards)
            state.piles.updateOrAppend(pile)

            return .none
        case let .foundation(foundationID, _):
            guard
                dragCards.cardIDs.count == 1,
                var foundation = state.foundations[id: foundationID],
                let card = dragCards.cardIDs.first.flatMap({ state.card(id: $0) }),
                isValidScoring(card: card, onto: foundation)
            else { return .none }

            switch dragCards.origin {
            case let .pile(cardIDs): state.removeCardsFromPile(cardIDs: cardIDs)
            case let .foundation(cardID): return .none
            case let .deck(cardID): state.deck.upwards.remove(id: cardID)
            }

            foundation.cards.updateOrAppend(card)
            state.foundations.updateOrAppend(foundation)

            return .none
        case .none: return .none
        }
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

private func isValidScoring(card: Card?, onto foundation: Foundation) -> Bool {
    guard let card = card else { return false }
    let canScore = card.rank == .ace || card.rank.lower == foundation.cards.last?.rank
    return card.suit == foundation.suit && canScore
}

extension AppState {
    func card(id: Card.ID) -> Card? {
        piles.flatMap(\.cards).first { $0.id == id }
            ?? foundations.flatMap(\.cards).first { $0.id == id }
            ?? deck.upwards.first { $0.id == id }
    }

    var actualDraggedCards: IdentifiedArrayOf<Card>? {
        guard let cardIDs = draggedCards?.cardIDs else { return nil }
        return IdentifiedArrayOf(uniqueElements: cardIDs.compactMap(card(id:)))
    }

    mutating func removeCardsFromPile(cardIDs: [Card.ID]) {
        guard
            let firstCardID = cardIDs.first,
            var origin = piles.first(where: { $0.cards.map(\.id).contains(firstCardID) })
        else { return }
        for cardID in cardIDs { origin.cards.remove(id: cardID) }

        guard var lastCard = origin.cards.last else {
            piles.updateOrAppend(origin)
            return
        }
        lastCard.isFacedUp = true
        origin.cards.updateOrAppend(lastCard)
        piles.updateOrAppend(origin)
    }

    mutating func removeCardFromFoundation(cardID: Card.ID) {
        guard var origin = foundations.first(where: { $0.cards.map(\.id).contains(cardID) }) else { return }
        origin.cards.remove(id: cardID)
        foundations.updateOrAppend(origin)
    }
}

struct DragCards: Equatable {
    enum Origin: Equatable {
        case pile(cardIDs: [Card.ID])
        case foundation(cardID: Card.ID)
        case deck(cardID: Card.ID)
    }

    let origin: Origin
    var position: CGPoint

    var cardIDs: [Card.ID] {
        switch origin {
        case let .pile(cardIDs): return cardIDs
        case let .foundation(cardID), let .deck(cardID): return [cardID]
        }
    }
}

enum Frame: Equatable, Hashable, Identifiable {
    case pile(Pile.ID, CGRect)
    case foundation(Foundation.ID, CGRect)

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .pile(pileID, _):
            hasher.combine("Pile")
            hasher.combine(pileID)
        case let .foundation(foundationID, _):
            hasher.combine("Foundation")
            hasher.combine(foundationID)
        }
    }

    var id: Int { hashValue }

    var rect: CGRect {
        switch self {
        case let .pile(_, rect), let .foundation(_, rect): return rect
        }
    }
}

private extension Suit {
    static var orderedCases: [Self] { [.hearts, .clubs, .diamonds, .spades] }
}

private extension Rank {
    var lower: Rank? {
        guard let index = Rank.allCases.firstIndex(of: self) else { return nil }
        return index > 0 ? Rank.allCases[index - 1] : nil
    }
}
