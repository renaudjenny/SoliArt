enum Scoring {
    case moveToFoundation
    case turnOverPileCard
    case moveBackFromFoundation
    case incrementMoveOnly
    case recycling

    var score: Int {
        switch self {
        case .moveToFoundation: return 10
        case .turnOverPileCard: return 5
        case .moveBackFromFoundation: return -15
        case .incrementMoveOnly: return 0
        case .recycling: return -100
        }
    }
}
