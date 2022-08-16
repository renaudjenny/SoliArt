import ComposableArchitecture

extension AlertState where Action == AppAction {
    static var resetGame: Self {
        AlertState(
            title: TextState("Are you sure? You will lost your progress"),
            primaryButton: .cancel(TextState("Cancel")),
            secondaryButton: .destructive(TextState("New game"), action: .send(.resetGame))
        )
    }
}
