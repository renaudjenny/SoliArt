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
            guard let card = deckUpwards.last else { return nil }
            return isValidScoring(card: deckUpwards.last, onto: foundation)
            ? Hint(
                card: card,
                origin: .deck,
                destination: .foundation(id: foundation.id),
                position: .source
            )
            : nil
        }
        return pileHints + deckHints
    }
}
