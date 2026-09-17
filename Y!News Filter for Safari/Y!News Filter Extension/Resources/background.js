browser.runtime.onMessage.addListener((message) => {
  if (message?.channel !== "ynf-settings") return undefined;

  return browser.runtime.sendNativeMessage({
    action: message.action,
    word: message.word,
    enabled: message.enabled,
    count: message.count
  }).catch((error) => ({
    ok: false,
    words: [],
    enabled: true,
    maxWordCount: 5,
    error: error?.message || "本体アプリとの通信に失敗しました。"
  }));
});
