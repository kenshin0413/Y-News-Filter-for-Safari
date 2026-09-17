import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var settings = FilterSettings()
    @StateObject private var rewardedAds = RewardedAdService()
    @StateObject private var advertisingConsent = AdvertisingConsentService.shared
    @State private var newWord = ""
    @State private var message: String?
    @State private var showingSetup = false
    @State private var shieldPulse = false
    @FocusState private var wordFieldFocused: Bool

    private let accent = Color(red: 0.35, green: 0.29, blue: 0.95)

    var body: some View {
        ZStack {
            pageBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    hero
                    managementPanel
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(edges: .top)
        }
        .tint(accent)
        .sheet(isPresented: $showingSetup) { SetupGuideView() }
        .alert("お知らせ", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK", role: .cancel) { message = nil }
        } message: {
            Text(message ?? "")
        }
        .onAppear {
            settings.reload()
            AppAnalytics.screen("home")
            startShieldAnimation()
            showInitialSetupIfReady()
        }
        .onChange(of: advertisingConsent.isFinished) { _, _ in showInitialSetupIfReady() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                settings.reload()
                startShieldAnimation()
            }
        }
    }

    private var hero: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.15, blue: 0.64),
                    Color(red: 0.28, green: 0.20, blue: 0.93),
                    Color(red: 0.47, green: 0.29, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.07))
                .frame(width: 360, height: 360)
                .offset(x: -155, y: 120)

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 330, height: 330)
                .offset(x: 170, y: -90)

            VStack(spacing: 0) {
                heroHeader
                    .padding(.top, 58)

                Button {
                    let enabled = !settings.isEnabled
                    settings.setEnabled(enabled)
                    AppAnalytics.log("filter_toggled", parameters: ["enabled": enabled ? 1 : 0])
                } label: {
                    ZStack {
                        if settings.isEnabled {
                            Circle()
                                .stroke(.white.opacity(shieldPulse ? 0.02 : 0.22), lineWidth: 1.5)
                                .frame(width: 132, height: 132)
                                .scaleEffect(shieldPulse ? 1.22 : 0.92)

                        }

                        Circle()
                            .fill(.white.opacity(0.08))
                            .frame(width: 132, height: 132)
                        Circle()
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                            .frame(width: 108, height: 108)
                        if settings.isEnabled {
                            ZStack {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 57, weight: .medium))
                                    .foregroundStyle(.white)
                                Image(systemName: "line.3.horizontal.decrease")
                                    .font(.system(size: 21, weight: .bold))
                                    .foregroundStyle(accent)
                            }
                        } else {
                            Image(systemName: "shield.slash")
                                .font(.system(size: 52, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.isEnabled ? "フィルターを停止" : "フィルターを開始")
                .padding(.top, 17)
                .animation(.easeInOut(duration: 0.35), value: settings.isEnabled)

                Text(settings.isEnabled ? "フィルタリングは有効です" : "フィルタリングは停止中")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 12)

                Text(settings.isEnabled
                     ? "登録した除外ワードを含む記事を\nYahoo!ニュースから自動で隠します。"
                     : "タップしてフィルターを有効にできます。")
                    .font(.system(size: 14, weight: .medium))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.top, 6)

                Label("今日 \(settings.hiddenArticleCountToday)件の記事を非表示にしました", systemImage: "eye.slash.fill")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .frame(height: 32)
                    .background(.white.opacity(0.12), in: Capsule())
                    .padding(.top, 13)

                HStack(spacing: 0) {
                    metric(value: "\(settings.words.count) / \(settings.maxWordCount)", label: "登録済みの除外ワード")
                    Rectangle()
                        .fill(.white.opacity(0.22))
                        .frame(width: 1, height: 44)
                        .padding(.horizontal, 26)
                    metric(value: "あと \(settings.remainingSlots) 件", label: "登録可能な残り枠")
                }
                .padding(.top, 18)
                .padding(.bottom, 27)
            }
            .padding(.horizontal, 22)
        }
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 38, bottomTrailingRadius: 38))
        .shadow(color: accent.opacity(0.18), radius: 24, y: 10)
    }

    private var heroHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                (Text("Y!News")
                    .foregroundStyle(Color(red: 1.0, green: 0.0, blue: 0.20))
                 + Text(" Filter")
                    .foregroundStyle(.white))
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                Text("見たくないニュースを、見ない毎日に。")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
            }
            Spacer()
            Button {
                AppAnalytics.log("setup_guide_opened", parameters: ["source": "header"])
                showingSetup = true
            } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.14), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.16), lineWidth: 1))
            }
            .accessibilityLabel("使い方")
        }
    }

    private func metric(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.67))
        }
        .frame(maxWidth: .infinity)
    }

    private var managementPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("除外ワードを追加")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Spacer()
                Text("部分一致で判定")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)
            }

            addWordField
                .padding(.top, 15)

            Text("このワードを含む記事タイトルを非表示にします。")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.top, 8)
                .padding(.leading, 10)

            wordList
                .padding(.top, 28)

            VStack(alignment: .leading, spacing: 11) {
                Text("その他")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 2)
                unlockRow
                safariRow
            }
            .padding(.top, 24)
        }
        .padding(.horizontal, 22)
        .padding(.top, 27)
        .padding(.bottom, 34)
        .background(panelBackground)
    }

    private var addWordField: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 18, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(accent)
                .frame(width: 26)

            TextField("例：芸能、ネタバレ、炎上", text: $newWord)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($wordFieldFocused)
                .onSubmit(addWord)

            Button("追加", action: addWord)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(accent, in: Capsule())
                .opacity(canAddWord ? 1 : 0.42)
                .disabled(!canAddWord)
        }
        .padding(.leading, 15)
        .padding(.trailing, 5)
        .frame(height: 54)
        .background(fieldBackground, in: Capsule())
        .overlay(Capsule().stroke(fieldBorderColor, lineWidth: 1))
    }

    @ViewBuilder
    private var wordList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("登録済みの除外ワード")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Text("\(settings.words.count) / \(settings.maxWordCount)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            if settings.words.isEmpty {
                Button {
                    wordFieldFocused = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "tag")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(accent)
                            .frame(width: 40, height: 40)
                            .background(accent.opacity(0.10), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text("最初の除外ワードを追加")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text("気になる話題や人名を登録できます")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            } else {
                ForEach(Array(settings.words.enumerated()), id: \.element) { index, word in
                    wordRow(word)
                    if index < settings.words.count - 1 { Divider().padding(.leading, 52) }
                }
            }
        }
    }

    private func wordRow(_ word: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "tag.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 40, height: 40)
                .background(accent.opacity(0.10), in: Circle())
            Text(word)
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Button {
                settings.removeWord(word)
                AppAnalytics.log("excluded_word_removed", parameters: ["word_count": settings.words.count])
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(Color.secondary.opacity(0.10), in: Circle())
            }
            .accessibilityLabel("\(word)を削除")
        }
        .padding(.vertical, 8)
    }

    private var unlockRow: some View {
        Button {
            rewardedAds.showAd {
                settings.unlockOneSlot()
                AppAnalytics.log("reward_slot_unlocked", parameters: ["max_word_count": settings.maxWordCount])
                message = "登録枠を1つ解放しました。最大\(settings.maxWordCount)ワード登録できます。"
            }
        } label: {
            HStack(spacing: 13) {
                ZStack {
                    Circle().fill(Color.orange.opacity(0.13))
                    if rewardedAds.isLoading {
                        ProgressView().tint(.orange)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(rewardedAds.isLoading ? "広告を準備しています" : "広告を見て＋1枠解放")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(rewardedAds.errorMessage ?? "解放した登録枠はずっと使えます")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
        .disabled(rewardedAds.isLoading)
        .padding(14)
        .background(Color.orange.opacity(0.075), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke(Color.orange.opacity(0.16), lineWidth: 1)
        }
    }

    private var safariRow: some View {
        Button {
            AppAnalytics.log("setup_guide_opened", parameters: ["source": "home_card"])
            showingSetup = true
        } label: {
            HStack(spacing: 13) {
                Image(systemName: "safari.fill")
                    .font(.system(size: 23))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.blue, .white)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.11), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Safari拡張機能の設定")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("有効化の手順と使い方を確認")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
        .padding(14)
        .background(Color.blue.opacity(0.065), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke(Color.blue.opacity(0.13), lineWidth: 1)
        }
    }

    private var canAddWord: Bool {
        !newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addWord() {
        switch settings.addWord(newWord) {
        case .success:
            newWord = ""
            wordFieldFocused = false
            AppAnalytics.log("excluded_word_added", parameters: ["word_count": settings.words.count])
        case .failure(let error):
            message = error.localizedDescription
        }
    }

    private func startShieldAnimation() {
        shieldPulse = false
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            shieldPulse = true
        }
    }

    private func showInitialSetupIfReady() {
        guard advertisingConsent.isFinished, !settings.hasCompletedSetup else { return }
        showingSetup = true
        settings.hasCompletedSetup = true
    }

    private var pageBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.025, green: 0.028, blue: 0.070)
            : Color(red: 0.965, green: 0.968, blue: 0.985)
    }

    private var panelBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.050, green: 0.052, blue: 0.105)
            : Color(uiColor: .systemBackground)
    }

    private var fieldBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.095, green: 0.095, blue: 0.165)
            : Color(red: 0.965, green: 0.968, blue: 0.985)
    }

    private var fieldBorderColor: Color {
        colorScheme == .dark ? .white.opacity(0.10) : .black.opacity(0.06)
    }
}

private struct SetupGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private let accent = Color(red: 0.35, green: 0.29, blue: 0.95)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "safari.fill")
                            .font(.system(size: 46))
                            .symbolRenderingMode(.multicolor)

                        Text("Safari拡張の設定")
                            .font(.system(size: 30, weight: .bold, design: .rounded))

                        Text("最初に一度だけ設定すれば、次回からは自動で記事を非表示にします。")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }

                    HStack(alignment: .top, spacing: 10) {
                        Text("※")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(accent)
                        Text("設定はとても簡単です。下の手順を順番に確認しましょう。")
                            .font(.system(size: 15, weight: .semibold))
                            .lineSpacing(2)
                    }
                    .padding(16)
                    .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(accent.opacity(0.14), lineWidth: 1)
                    }

                    SetupSection(
                        number: 1,
                        title: "iPhoneの設定で許可する",
                        caption: "初回だけ行います",
                        color: accent,
                        steps: [
                            SetupInstruction(icon: "gearshape.fill", title: "ホーム画面で「設定」を開く", detail: "このアプリの設定画面ではなく、歯車アイコンの「設定」アプリです。"),
                            SetupInstruction(icon: "apps.iphone", title: "「アプリ」→「Safari」を開く", detail: "「アプリ」がないiOSでは、設定画面を下へスクロールして「Safari」をタップします。"),
                            SetupInstruction(icon: "puzzlepiece.extension.fill", title: "「機能拡張」をタップ", detail: "一覧から「Y!News Filter Extension」を選びます。"),
                            SetupInstruction(icon: "switch.2", title: "「機能拡張を許可」をON", detail: "Webサイトへのアクセスを聞かれた場合は、Yahoo! JAPAN／Yahoo!ニュースを「許可」にします。")
                        ]
                    )

                    SetupSection(
                        number: 2,
                        title: "Safariで表示して使う",
                        caption: "Yahoo!ニュース上で行います",
                        color: .blue,
                        steps: [
                            SetupInstruction(icon: "safari.fill", title: "SafariでYahoo!ニュースを開く", detail: "Yahoo! JAPANトップでも使用できます。"),
                            SetupInstruction(icon: "puzzlepiece.extension", title: "画面左下のメニューボタンをタップ", detail: "パズルマークと2本線のようなアイコンです。アドレスバー左側に表示される場合もあります。"),
                            SetupInstruction(icon: "slider.horizontal.3", title: "「機能拡張を管理」をタップ", detail: "「Y!News Filter」をONにします。すでにONなら、この操作は不要です。"),
                            SetupInstruction(icon: "puzzlepiece.extension", title: "同じメニューボタンをもう一度タップ", detail: "表示された「Y!News Filter」をタップすると、除外ワードの確認・追加・削除ができます。"),
                            SetupInstruction(icon: "arrow.clockwise", title: "Yahoo!ニュースを更新する", detail: "登録したワードを含む記事が非表示になれば設定完了です。")
                        ]
                    )

                    Link(destination: URL(string: "https://www.yahoo.co.jp/")!) {
                        HStack {
                            Image(systemName: "safari.fill")
                            Text("SafariでYahoo! JAPANを開く")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 56)
                        .background(accent, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        AppAnalytics.log("open_yahoo_from_setup")
                    })

                    VStack(alignment: .leading, spacing: 9) {
                        Label("表示されない・消えないとき", systemImage: "questionmark.circle.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text("Safariを一度閉じて開き直し、Yahoo!ニュースを更新してください。それでも動かない場合は、「設定」→「Safari」→「機能拡張」で、機能拡張とWebサイトへのアクセスが許可されているか確認します。")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(22)
            }
            .navigationTitle("セットアップ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
            .onAppear { AppAnalytics.screen("setup_guide") }
        }
    }
}

private struct SetupInstruction {
    let icon: String
    let title: String
    let detail: String
}

private struct SetupSection: View {
    let number: Int
    let title: String
    let caption: String
    let color: Color
    let steps: [SetupInstruction]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text("\(number)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .frame(width: 36, height: 36)
                    .foregroundStyle(.white)
                    .background(color, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(caption)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 10)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 13) {
                    Image(systemName: step.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(width: 34, height: 34)
                        .background(color.opacity(0.10), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.system(size: 15, weight: .bold))
                        Text(step.detail)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
                    .padding(.top, 1)

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 11)

                if index < steps.count - 1 {
                    Divider().padding(.leading, 47)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        }
    }
}

#Preview { ContentView() }
