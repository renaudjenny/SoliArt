import ComposableArchitecture

extension ConfirmationDialogState where Action == Game.Action {
    static var resetGame: Self {
        ConfirmationDialogState(
            title: TextState("Confirm reset game"),
            message: TextState("Are you sure you want to reset that game?\nYour progress will be lost."),
            buttons: [
                .cancel(TextState("Cancel")),
                .destructive(TextState("New game"), action: .send(.resetGame)),
            ]
        )
    }
}
