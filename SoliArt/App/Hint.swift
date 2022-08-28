import SwiftUI

struct Hint: Equatable {
    let card: Card
    let origin: Source
    let destination: Destination
    var cardPosition: CGPoint
}

extension Hint {
    enum Source: Equatable {
        case pile(id: Pile.ID)
        case deck
    }

    enum Destination: Equatable {
        case pile(id: Pile.ID)
        case foundation(id: Foundation.ID)
    }
}
