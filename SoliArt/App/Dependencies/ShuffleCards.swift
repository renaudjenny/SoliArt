import Dependencies
import XCTestDynamicOverlay

struct ShuffleCardsDependencyKey: DependencyKey {
    static let liveValue: ShuffleCards = .live
    static let testValue: ShuffleCards = .test
    static let previewValue: ShuffleCards = .live
}
extension DependencyValues {
    var shuffleCards: ShuffleCards {
        get { self[ShuffleCardsDependencyKey.self] }
        set { self[ShuffleCardsDependencyKey.self] = newValue }
    }
}

struct ShuffleCards {
    private let shuffle: () -> [Card]

    static let live = Self { .standard52Deck.shuffled() }
    static let test = Self {
        XCTFail(#"Unimplemented: @Dependency(\.shuffleCards)"#)
        return .standard52Deck.shuffled()
    }

    init(shuffle: @escaping () -> [Card]) {
        self.shuffle = shuffle
    }

    func callAsFunction() -> [Card] {
        shuffle()
    }
}
