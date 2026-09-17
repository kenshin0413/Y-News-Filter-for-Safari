import SafariServices

final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private static let appGroupID = "group.com.kenshin.Y-News-Filter-for-Safari"
    private enum Key {
        static let words = "excludedWords"
        static let isEnabled = "filterEnabled"
        static let maxWordCount = "maxWordCount"
        static let hiddenArticleCount = "hiddenArticleCount"
        static let hiddenArticleCountDate = "hiddenArticleCountDate"
    }

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem
        let message = request?.userInfo?[SFExtensionMessageKey] as? [String: Any] ?? [:]
        let result = handle(message)

        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: result]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }

    private func handle(_ message: [String: Any]) -> [String: Any] {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID) else {
            return ["ok": false, "error": "共有設定を開けませんでした。"]
        }
        defaults.register(defaults: [Key.words: [String](), Key.isEnabled: true, Key.maxWordCount: 5])

        switch message["action"] as? String {
        case "getSettings":
            return payload(from: defaults)

        case "addWord":
            let input = message["word"] as? String ?? ""
            let word = input.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !word.isEmpty else { return failure("空のワードは登録できません。", defaults: defaults) }

            var words = defaults.stringArray(forKey: Key.words) ?? []
            guard !words.contains(where: { normalized($0) == normalized(word) }) else {
                return failure("このワードは登録済みです。", defaults: defaults)
            }
            guard words.count < maximum(from: defaults) else {
                return failure("登録枠が足りません。アプリで広告を見て＋1枠解放してください。", defaults: defaults)
            }
            words.append(word)
            defaults.set(words, forKey: Key.words)
            return payload(from: defaults)

        case "removeWord":
            let word = message["word"] as? String ?? ""
            var words = defaults.stringArray(forKey: Key.words) ?? []
            words.removeAll { $0 == word }
            defaults.set(words, forKey: Key.words)
            return payload(from: defaults)

        case "setEnabled":
            guard let enabled = message["enabled"] as? Bool else {
                return failure("設定値が正しくありません。", defaults: defaults)
            }
            defaults.set(enabled, forKey: Key.isEnabled)
            return payload(from: defaults)

        case "recordHiddenArticles":
            let count = max(0, message["count"] as? Int ?? 0)
            let today = dayKey(for: Date())
            if defaults.string(forKey: Key.hiddenArticleCountDate) != today {
                defaults.set(today, forKey: Key.hiddenArticleCountDate)
                defaults.set(0, forKey: Key.hiddenArticleCount)
            }
            defaults.set(defaults.integer(forKey: Key.hiddenArticleCount) + count, forKey: Key.hiddenArticleCount)
            return payload(from: defaults)

        default:
            return failure("未対応の操作です。", defaults: defaults)
        }
    }

    private func maximum(from defaults: UserDefaults) -> Int {
        max(5, defaults.integer(forKey: Key.maxWordCount))
    }

    private func normalized(_ value: String) -> String {
        value.precomposedStringWithCompatibilityMapping
            .lowercased(with: Locale(identifier: "ja_JP"))
            .filter { !$0.isWhitespace }
    }

    private func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func payload(from defaults: UserDefaults) -> [String: Any] {
        [
            "ok": true,
            "words": defaults.stringArray(forKey: Key.words) ?? [],
            "enabled": defaults.object(forKey: Key.isEnabled) as? Bool ?? true,
            "maxWordCount": maximum(from: defaults)
        ]
    }

    private func failure(_ error: String, defaults: UserDefaults) -> [String: Any] {
        var response = payload(from: defaults)
        response["ok"] = false
        response["error"] = error
        return response
    }
}
