import Foundation

struct HistoryEntry: Equatable {
    let date: Date
    let gameState: Game.State
    let scoreState: Score.State
}
