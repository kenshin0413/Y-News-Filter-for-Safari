(() => {
  "use strict";

  // Yahoo!ニュースのDOM変更時は、この2つの配列を中心に調整する。
  const ARTICLE_LINK_SELECTORS = [
    'a[href*="/articles/"]',
    'a[href*="/pickup/"]',
    'a[href*="/expert/articles/"]'
  ];
  const ARTICLE_CARD_SELECTORS = [
    "article",
    '[data-ual-view-type="list"]',
    "li",
    '[class*="ArticleItem"]',
    '[class*="articleItem"]',
    '[class*="NewsItem"]',
    '[class*="newsItem"]'
  ];
  const HIDDEN_CLASS = "ynf-hidden-article";
  const STYLE_ID = "ynf-filter-style";
  const POLL_INTERVAL_MS = 2000;

  let settings = { enabled: true, words: [] };
  let filterTimer;
  const countedElements = new WeakSet();

  function normalized(value) {
    return (value || "").normalize("NFKC").replace(/\s+/g, "").toLocaleLowerCase("ja-JP");
  }

  function ensureStyle() {
    if (document.getElementById(STYLE_ID)) return;
    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.textContent = `.${HIDDEN_CLASS} { display: none !important; }`;
    (document.head || document.documentElement).appendChild(style);
  }

  function articleLinks(root = document) {
    return [...root.querySelectorAll(ARTICLE_LINK_SELECTORS.join(","))];
  }

  function articleCards(root = document) {
    const cards = root.querySelectorAll([
      "article",
      '[data-ual-view-type="list"]',
      '[class*="ArticleBox"]',
      '[class*="articleBox"]'
    ].join(","));

    // Yahoo!トップの各ニュースタブではリンク先が外部メディアになることがある。
    // URLではなく、見出しとリンクを持つ記事カードを共通の検査対象にする。
    return [...cards].filter((card) =>
      card.querySelector("a[href]") &&
      card.querySelector('h1, h2, h3, [class*="ArticleTitle"], [class*="articleTitle"]')
    );
  }

  function articleTitle(card) {
    const titleElement = card.querySelector(
      'h1, h2, h3, [class*="ArticleTitle"], [class*="articleTitle"]'
    );
    return titleElement?.textContent || card.textContent || "";
  }

  function articleCard(link) {
    const selector = ARTICLE_CARD_SELECTORS.join(",");
    const semanticCard = link.closest(selector);
    if (semanticCard) return semanticCard;

    // クラス名が変わった場合の保守的なフォールバック。
    // 大きなセクション全体を消さないよう、最大3階層だけ遡る。
    let element = link;
    for (let depth = 0; depth < 3 && element.parentElement; depth += 1) {
      element = element.parentElement;
      const linkCount = element.querySelectorAll('a[href*="/articles/"]').length;
      if (linkCount === 1) return element;
    }
    return link;
  }

  function matchesExcludedWord(title) {
    const candidate = normalized(title);
    return settings.words.some((word) => candidate.includes(normalized(word)));
  }

  function applyFilter() {
    ensureStyle();
    document.querySelectorAll(`.${HIDDEN_CLASS}`).forEach((element) => {
      element.classList.remove(HIDDEN_CLASS);
      element.removeAttribute("data-ynf-word");
    });

    if (!settings.enabled || settings.words.length === 0) return;

    let newlyHiddenCount = 0;

    function hide(card, matchedWord) {
      card.classList.add(HIDDEN_CLASS);
      card.dataset.ynfWord = matchedWord;
      if (!countedElements.has(card)) {
        countedElements.add(card);
        newlyHiddenCount += 1;
      }
    }

    articleCards().forEach((card) => {
      const title = articleTitle(card);
      const matchedWord = settings.words.find((word) => normalized(title).includes(normalized(word)));
      if (!matchedWord) return;
      hide(card, matchedWord);
    });

    articleLinks().forEach((link) => {
      if (link.closest(`.${HIDDEN_CLASS}`)) return;
      const title = link.getAttribute("aria-label") || link.textContent || "";
      const matchedWord = settings.words.find((word) => normalized(title).includes(normalized(word)));
      if (!matchedWord) return;
      const card = articleCard(link);
      hide(card, matchedWord);
    });

    if (newlyHiddenCount > 0) {
      browser.runtime.sendMessage({
        channel: "ynf-settings",
        action: "recordHiddenArticles",
        count: newlyHiddenCount
      }).catch(() => {});
    }
  }

  function scheduleFilter() {
    clearTimeout(filterTimer);
    filterTimer = setTimeout(applyFilter, 100);
  }

  async function refreshSettings() {
    try {
      const response = await browser.runtime.sendMessage({
        channel: "ynf-settings",
        action: "getSettings"
      });
      if (!response) return;
      const next = {
        enabled: response.enabled !== false,
        words: Array.isArray(response.words) ? response.words : []
      };
      if (JSON.stringify(next) !== JSON.stringify(settings)) {
        settings = next;
        applyFilter();
      }
    } catch (error) {
      console.warn("Y!News Filter: 設定を取得できませんでした。", error);
    }
  }

  const observer = new MutationObserver(scheduleFilter);
  observer.observe(document.documentElement, { childList: true, subtree: true });
  window.addEventListener("focus", refreshSettings);
  document.addEventListener("visibilitychange", () => {
    if (!document.hidden) refreshSettings();
  });

  refreshSettings().then(applyFilter);
  setInterval(refreshSettings, POLL_INTERVAL_MS);
})();
