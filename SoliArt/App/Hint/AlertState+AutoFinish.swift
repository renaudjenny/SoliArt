import ComposableArchitecture

extension AlertState where Action == HintAction {
    static var autoFinish: Self {
        AlertState(
            title: TextState("Looks like the game is almost finished"),
            primaryButton: .cancel(TextState("Cancel")),
            secondaryButton: .destructive(TextState("Finish now"), action: .send(.autoFinish))
        )
    }
}
