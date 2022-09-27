extension HintState {
    var hints: [Hint] {
        let pileHints: [Hint] = piles.flatMap { pile in
            foundations.compactMap { foundation in
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

        let deckHints: [Hint] = foundations.compactMap { foundation in
            guard let card = deck.upwards.last else { return nil }
            return isValidScoring(card: deck.upwards.last, onto: foundation)
            ? Hint(
                card: card,
                origin: .deck,
                destination: .foundation(id: foundation.id),
                position: .source
            )
            : nil
        }

        let drawCardHint = [deck.downwards.first.map {
            var card = $0
            card.isFacedUp = true
            return Hint(
                card: card,
                origin: .deckDownwards,
                destination: .deck,
                position: .source
            )
        }].compactMap { $0 }

        return pileHints + deckHints + drawCardHint
    }

    var isAutoFinishAvailable: Bool {
        piles.flatMap(\.cards).allSatisfy(\.isFacedUp) && hints.count > 0
    }
}
