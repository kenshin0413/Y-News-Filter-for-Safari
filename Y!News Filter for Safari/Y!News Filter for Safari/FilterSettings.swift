import Combine
import Foundation

enum FilterSettingsError: LocalizedError {
    case empty
    case duplicate
    case limitReached

    var errorDescription: String? {
        switch self {
        case .empty: "空のワードは登録できません。"
        case .duplicate: "このワードは登録済みです。"
        case .limitReached: "登録枠が足りません。広告を見て＋1枠解放してください。"
        }
    }
}

@MainActor
final class FilterSettings: ObservableObject {
    static let appGroupID = "group.com.kenshin.Y-News-Filter-for-Safari"
    private enum Key {
        static let words = "excludedWords"
        static let isEnabled = "filterEnabled"
        static let maxWordCount = "maxWordCount"
        static let hasCompletedSetup = "hasCompletedSetup"
        static let hiddenArticleCount = "hiddenArticleCount"
        static let hiddenArticleCountDate = "hiddenArticleCountDate"
    }

    @Published private(set) var words: [String] = []
    @Published private(set) var isEnabled = true
    @Published private(set) var maxWordCount = 5
    @Published private(set) var hiddenArticleCountToday = 0
    private let defaults: UserDefaults

    var remainingSlots: Int { max(0, maxWordCount - words.count) }

    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults ?? UserDefaults(suiteName: Self.appGroupID) ?? .standard
        self.defaults.register(defaults: [
            Key.words: [String](),
            Key.isEnabled: true,
            Key.maxWordCount: 5,
            Key.hasCompletedSetup: false
        ])
        reload()
    }

    var hasCompletedSetup: Bool {
        get { defaults.bool(forKey: Key.hasCompletedSetup) }
        set { defaults.set(newValue, forKey: Key.hasCompletedSetup) }
    }

    func reload() {
        words = defaults.stringArray(forKey: Key.words) ?? []
        isEnabled = defaults.object(forKey: Key.isEnabled) as? Bool ?? true
        maxWordCount = max(5, defaults.integer(forKey: Key.maxWordCount))
        hiddenArticleCountToday = hiddenCountForToday()
    }

    func addWord(_ input: String) -> Result<Void, FilterSettingsError> {
        let word = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !word.isEmpty else { return .failure(.empty) }
        guard !words.contains(where: { Self.normalized($0) == Self.normalized(word) }) else {
            return .failure(.duplicate)
        }
        guard words.count < maxWordCount else { return .failure(.limitReached) }
        words.append(word)
        persistWords()
        return .success(())
    }

    func removeWord(_ word: String) {
        words.removeAll { $0 == word }
        persistWords()
    }

    func removeWords(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            words.remove(at: index)
        }
        persistWords()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        defaults.set(enabled, forKey: Key.isEnabled)
    }

    func unlockOneSlot() {
        maxWordCount += 1
        defaults.set(maxWordCount, forKey: Key.maxWordCount)
    }

    private func persistWords() {
        defaults.set(words, forKey: Key.words)
    }

    private func hiddenCountForToday() -> Int {
        let today = Self.dayKey(for: Date())
        guard defaults.string(forKey: Key.hiddenArticleCountDate) == today else { return 0 }
        return defaults.integer(forKey: Key.hiddenArticleCount)
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func normalized(_ value: String) -> String {
        value.precomposedStringWithCompatibilityMapping
            .lowercased(with: Locale(identifier: "ja_JP"))
            .filter { !$0.isWhitespace }
    }
}
