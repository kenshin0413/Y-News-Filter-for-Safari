# Design QA — Y!News Filter home screen

- Source visual truth: `/Users/kenshin/.codex/generated_images/01a0ad94-c48b-7ae1-a841-34874f9be8c6/exec-b87494d5-ba2b-455f-85c9-c746a4bfdd3d.png`
- Implementation screenshot: `/tmp/ynfilter-polish-bottom.png`
- Comparison image: `/tmp/ynfilter-design-comparison-3.png`
- Intended viewport: iPhone mobile app, approximately 390 × 844 pt
- Captured viewport: iPhone 16 Pro simulator, 402 × 874 pt at 3×
- Source pixels: 853 × 1844
- Implementation pixels: 1206 × 2622
- Normalization: both images scaled proportionally to 1844 px high and placed side by side. The implementation retains iOS-owned status-bar content; the source intentionally omits system chrome.
- State: filter enabled, 1 of 5 keywords registered, add field empty; reduced list state used to expose and inspect the complete lower action area

## Full-view comparison evidence

The implementation preserves the source hierarchy: purple protection/status hero, centered shield-filter symbol, active state and capacity metrics, a white management surface, primary keyword composer, three keyword rows, reward unlock, and Safari setup. The main purple/white split, type hierarchy, input shape, separators, icon treatment, and spacing rhythm are visibly aligned in the side-by-side comparison.

## Focused-region comparison evidence

The full-resolution side-by-side image keeps the hero typography, composer, and keyword rows readable, so separate crops were not necessary. The shield was refined after the first comparison from a half-filled generic shield to a shield plus filter glyph, and destructive buttons were changed from red to the source's neutral violet-gray treatment.

## Required fidelity surfaces

- Fonts and typography: native SF typography matches the visual target's rounded display hierarchy and readable Japanese UI text. Weight and line wrapping are consistent at the captured size.
- Spacing and layout rhythm: hero proportions, 22 pt content margins, capsule composer, list separators, and row rhythm align with the reference. The status bar reduces the initially visible lower content versus the chrome-free source, which is expected native-app infrastructure rather than app-content drift.
- Colors and visual tokens: deep blue-to-violet hero, white foreground hierarchy, pale lavender icon surfaces, neutral separators, and orange reward accent match the selected direction with accessible contrast.
- Image quality and asset fidelity: the source contains no photographic or branded raster asset required by the app. All symbols use native SF Symbols; the abstract hero treatment is native scalable UI material and remains sharp at device density.
- Copy and content: active status, partial-match behavior, capacity, keyword examples, permanent reward slot, and Safari setup copy all reflect the real product behavior.

## Comparison history

### Pass 1

- [P2] The central hero used a split shield rather than the reference's filter shield, weakening the product-specific identity.
- [P2] Delete affordances inherited destructive red, while the reference uses quiet neutral controls.

Fixes made:

- Composed the central mark from native `shield.fill` and `line.3.horizontal.decrease` SF Symbols.
- Removed the destructive button role and adopted a neutral secondary foreground.
- Hid the scroll indicator to preserve the clean edge treatment.

### Pass 2

Post-fix visual evidence: `/tmp/ynfilter-design-comparison-2.png` shows the corrected filter-shield mark and neutral delete controls. No actionable P0/P1/P2 visual mismatches remain.

### Pass 3 — user-directed polish

- Applied a clear Yahoo-style red to the `Y!News` portion of the wordmark while retaining white for `Filter`.
- Replaced the misleading search glyph with a visible `plus.circle.fill` add affordance.
- Reworked the lower actions as distinct, lightly tinted orange and blue utility cards with improved grouping, padding, borders, and hierarchy.

Post-fix visual evidence: `/tmp/ynfilter-design-comparison-3.png` shows the complete lower action area in the 1-of-5 state. The annotated changes are legible, semantically clearer, and visually consistent with the selected direction. No actionable P0/P1/P2 issues remain.

## Follow-up polish

- [P3] The source uses a gear icon while the implementation uses a question mark because the action opens the setup/help flow; this is an intentional semantic improvement.
- [P3] Safari setup sits just below the initial fold on the captured device because real iOS status chrome consumes vertical space. It remains immediately reachable by a short scroll.

## Verification

- Simulator build: passed.
- Main-screen render at iPhone 16 Pro size: passed.
- Keyword add/delete, filter toggle, reward action, and setup actions remain wired to the existing functional implementations.

final result: passed

---

## Pass 4 — Safari extension popup centering and delete affordance

- Source visual truth: `/Users/kenshin/Downloads/IMG_8427.PNG`
- Implementation capture: Codex in-app browser capture of `http://localhost:8765/ynfilter-popup-preview.html` (inline browser evidence; temporary preview)
- Viewport: 390 × 844 CSS px, device scale factor 1
- Source pixels: 1206 × 2622 (displayed source was proportionally resized for inspection)
- Implementation pixels: 390 × 844 browser capture
- State: filter enabled, capacity 5 / 5, five registered words, add field empty
- Full-view evidence: the 360 px popup content column measures 15 px from both viewport edges at 390 px width, with no horizontal overflow. All five rows render within the shared centered column.
- Focused-region evidence: each row exposes the full Japanese `削除` label inside a consistent red-tinted button; the focused row treatment is clearly readable in the full-view capture, so an additional crop was unnecessary.

Required fidelity surfaces:

- Fonts and typography: existing native system type and hierarchy are preserved; `削除` uses a compact 13 px bold label.
- Spacing and layout rhythm: outer layout is responsive and centered; measured left and right margins are both 15 px, with the existing 360 px maximum content width preserved.
- Colors and visual tokens: existing violet accent remains unchanged; deletion uses the existing semantic danger token with a low-opacity surface and border.
- Image quality and asset fidelity: no new image assets were introduced; the existing app mark remains unchanged.
- Copy and content: the ambiguous `×` glyph is replaced by the explicit Japanese action label `削除`; its existing per-word accessibility label remains intact.

Verification:

- Responsive geometry at 390 px: passed (15 px / 15 px equal margins, no overflow).
- Five deletion controls visibly labeled `削除`: passed.
- Existing add, toggle, and delete event wiring preserved: passed.

No actionable P0/P1/P2 findings remain.

final result: passed
