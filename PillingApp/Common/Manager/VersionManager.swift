import Foundation

final class VersionManager {
    static let shared = VersionManager()

    private let currentDataVersion = 2
    private let minimumSupportedVersion = 2
    private let versionKey = "dataVersion"

    private init() {}

    func checkAndResetIfNeeded() -> Bool {
        let savedVersion = UserDefaults.standard.integer(forKey: versionKey)

        if savedVersion == 0 {
            UserDefaults.standard.set(currentDataVersion, forKey: versionKey)
            return false
        }

        if savedVersion < minimumSupportedVersion {
            resetAllData()
            return true
        }

        return false
    }

    private func resetAllData() {
        CoreDataManager.shared.deleteAllDataSync()
        clearAppGroupDefaults()
        clearUserDefaults()

        UserDefaults.standard.set(currentDataVersion, forKey: versionKey)
    }

    private func clearAppGroupDefaults() {
        let appGroupIdentifier = "group.app.Pilltastic.Pilling"
        if let groupDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            groupDefaults.dictionaryRepresentation().keys.forEach { key in
                groupDefaults.removeObject(forKey: key)
            }
            groupDefaults.synchronize()
        }
    }

    private func clearUserDefaults() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        }
        UserDefaults.standard.synchronize()
    }
}
