import Foundation

protocol PlayerDataRepository {
    func load() -> PlayerData
    func save(_ data: PlayerData)
}

final class UserDefaultsPlayerDataRepository: PlayerDataRepository {
    private let key = "playerData"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PlayerData {
        guard let raw = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(PlayerData.self, from: raw)
        else { return PlayerData() }
        return decoded
    }

    func save(_ data: PlayerData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: key)
    }
}
