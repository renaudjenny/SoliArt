import Foundation

struct HistoryEntry: Equatable {
    let date: Date
    let gameState: GameState
    let scoreState: Score.State
}
