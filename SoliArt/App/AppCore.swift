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
    var draggedCard: DragCard?
}

enum AppAction: Equatable {
    case shuffleCards
    case drawCard
    case flipDeck
    case updateFrame(Frame)
    case dragCard(DragCard?)
    case dropCard(DragCard)
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
    case let .dragCard(dragCard):
        guard let card = dragCard?.card else {
            let draggedCard = state.draggedCard
            state.draggedCard = nil
            return draggedCard.map { Effect(value: .dropCard($0)) } ?? .none
        }
        state.draggedCard = dragCard
        return .none
    case let .dropCard(dragCard):
        let dropFrame = state.frames.first { frame in
            frame.rect.contains(dragCard.position)
        }
        switch dropFrame {
        case let .pile(pile, _):
            guard
                var pile = state.piles[id: pile.id],
                isValidMove(card: dragCard.card, onto: pile.cards.last)
            else { return .none }

            pile.cards.updateOrAppend(dragCard.card)
            state.piles.updateOrAppend(pile)

            var origin = state.piles.first { $0.cards.contains(dragCard.card) }
            origin?.cards.remove(dragCard.card)
            _ = origin.map { state.piles.updateOrAppend($0) }

            return .none
        case .none: return .none
        }
    }
}

private func isValidMove(card: Card, onto: Card?) -> Bool {
    guard let onto = onto else { return false }

    let isColorDifferent: Bool
    switch card.suit {
    case .clubs, .spades: isColorDifferent = [.diamonds, .hearts].contains(onto.suit)
    case .diamonds, .hearts: isColorDifferent = [.clubs, .spades].contains(onto.suit)
    }

    let isRankLower = card.rank == onto.rank.lower

    return isColorDifferent && isRankLower
}

struct DragCard: Equatable {
    let card: Card
    var position: CGPoint
}

enum DragOrigin: Equatable {
    case pile(Pile)
}

enum Frame: Equatable, Hashable, Identifiable {
    case pile(Pile, CGRect)

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .pile(pile, _):
            hasher.combine("Pile")
            hasher.combine(pile.id)
        }
    }

    var id: Int { hashValue }

    var rect: CGRect {
        switch self {
        case let .pile(_, rect): return rect
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
