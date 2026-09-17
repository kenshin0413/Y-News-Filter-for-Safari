const elements = {
  enabled: document.querySelector("#enabled"),
  form: document.querySelector("#add-form"),
  input: document.querySelector("#word"),
  list: document.querySelector("#word-list"),
  empty: document.querySelector("#empty"),
  usage: document.querySelector("#usage"),
  message: document.querySelector("#message"),
  limitGuide: document.querySelector("#limit-guide")
};

let settings = { words: [], enabled: true, maxWordCount: 5 };

async function request(action, data = {}) {
  const response = await browser.runtime.sendMessage({ channel: "ynf-settings", action, ...data });
  if (!response) throw new Error("本体アプリとの通信に失敗しました。");
  settings = {
    words: Array.isArray(response.words) ? response.words : [],
    enabled: response.enabled !== false,
    maxWordCount: Math.max(5, Number(response.maxWordCount) || 5)
  };
  render();
  if (!response.ok) throw new Error(response.error || "操作に失敗しました。");
  return response;
}

function render() {
  elements.enabled.checked = settings.enabled;
  elements.usage.textContent = `${settings.words.length} / ${settings.maxWordCount} ワード`;
  elements.list.replaceChildren();
  settings.words.forEach((word) => {
    const item = document.createElement("li");
    const label = document.createElement("span");
    label.textContent = word;
    const remove = document.createElement("button");
    remove.type = "button";
    remove.className = "delete-button";
    remove.textContent = "削除";
    remove.setAttribute("aria-label", `${word}を削除`);
    remove.addEventListener("click", async () => {
      elements.message.textContent = "";
      try { await request("removeWord", { word }); }
      catch (error) { elements.message.textContent = error.message; }
    });
    item.append(label, remove);
    elements.list.append(item);
  });
  elements.empty.hidden = settings.words.length > 0;
  elements.limitGuide.hidden = settings.words.length < settings.maxWordCount;
}

elements.form.addEventListener("submit", async (event) => {
  event.preventDefault();
  elements.message.textContent = "";
  try {
    await request("addWord", { word: elements.input.value });
    elements.input.value = "";
  } catch (error) {
    elements.message.textContent = error.message;
  }
});

elements.enabled.addEventListener("change", async () => {
  elements.message.textContent = "";
  try { await request("setEnabled", { enabled: elements.enabled.checked }); }
  catch (error) { elements.message.textContent = error.message; }
});

request("getSettings").catch((error) => {
  elements.message.textContent = error.message;
  render();
});
