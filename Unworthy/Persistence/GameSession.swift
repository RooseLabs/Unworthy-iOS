import Foundation

final class GameSession {
    static let shared = GameSession()

    private let repository: PlayerDataRepository
    private(set) var data: PlayerData

    weak var activeLevel: LevelScene?

    private init(repository: PlayerDataRepository = UserDefaultsPlayerDataRepository()) {
        self.repository = repository
        self.data = repository.load()
    }

    func recordSession(kills: Int, deaths: Int) {
        guard kills > 0 || deaths > 0 else { return }
        data.enemiesDefeated += kills
        data.deaths += deaths
        repository.save(data)
    }

    func flushFromActiveLevel() {
        activeLevel?.flushSessionStats()
    }
}
