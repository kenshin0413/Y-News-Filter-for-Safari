# Y!News Filter for Safari

Yahoo!ニュースの記事タイトルに登録済みの除外ワードが含まれる場合、記事カードをSafari上で非表示にするiOSアプリ＋Safari Web Extensionです。

## 実機での確認手順

1. Xcodeで `Y!News Filter for Safari/Y!News Filter for Safari.xcodeproj` を開く。
2. 本体と `Y!News Filter Extension` の Signing & Capabilities で同じTeamを選び、App Group `group.com.kenshin.Y-News-Filter-for-Safari` が利用できることを確認する。
3. 本体アプリを実機へインストールし、テスト用の除外ワードを追加する。
4. iPhoneの「設定」→「アプリ」→「Safari」→「機能拡張」で `Y!News Filter Extension` をオンにする。
5. Yahoo!ニュースへのアクセスを許可し、Safariで `https://news.yahoo.co.jp/` を開く。
6. 登録ワードを含む記事カードが非表示になることを確認する。

フィルターのDOMセレクタとカード特定処理は `Y!News Filter Extension/Resources/content.js` の先頭付近に分離しています。Yahoo!ニュースのDOM変更時は `ARTICLE_LINK_SELECTORS` と `ARTICLE_CARD_SELECTORS` を中心に調整してください。

## AdMob

現在はGoogle公式のiOSリワード広告テストIDとテスト用App IDを設定しています。本番公開前に次をAdMob管理画面で発行した値へ差し替えてください。

- `RewardedAdService.swift` の `adUnitID`
- 本体アプリの `Info.plist` にある `GADApplicationIdentifier`

枠の追加は、`RewardedAd.present` のリワード獲得ハンドラが呼ばれた場合だけ実行されます。解放済み最大枠数はApp Groupの `UserDefaults` に保存され、ワードを削除しても減りません。
