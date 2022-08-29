import ComposableArchitecture

extension AlertState where Action == AppAction {
    static var resetGame: Self {
        AlertState(
            title: TextState("Are you sure? Your progress will be lost"),
            primaryButton: .cancel(TextState("Cancel")),
            secondaryButton: .destructive(TextState("New game"), action: .send(.game(.resetGame)))
        )
    }
}
