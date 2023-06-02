import ComposableArchitecture

extension ConfirmationDialogState where Action == AutoFinish.Action {
    static var autoFinish: Self {
        ConfirmationDialogState(
            title: TextState("Looks like the game is almost finished"),
            message: TextState("Looks like the game is almost finished"),
            buttons: [
                .cancel(TextState("Cancel")),
                .default(TextState("Finish now"), action: .send(.autoFinish)),
            ]
        )
    }
}
