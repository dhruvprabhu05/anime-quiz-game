# Roblox UI Guide

A living guide for building and polishing this game's UI. **Read it before any UI work, and add to the Lessons log (section 9) whenever something is learned** — a fix that worked, a mistake to avoid, feedback from playtesting.

---

## 1. How this game's UI is built

- All UI is created in code (Luau) under `src/client/`. Nothing is hand-built in Studio's StarterGui.
- One `ScreenGui` named `QuizGameUI` (`ResetOnSpawn = false`, `IgnoreGuiInset = true`, `ZIndexBehavior = Sibling`).
- Each screen is a full-screen `Frame` built by its own module (`QuizUI`, `TimerUI`, `ResultsUI`, `CollectionUI`, `SettingsUI`) via a `build(screenGui, ...)` function. `UIController.client.luau` switches screens with `showScreen(name)`.
- Shared styling lives in `UIEffects.luau`:
  - `UIEffects.COLORS` — the palette. Use these tokens; don't introduce one-off colors.
  - Helpers: `addNeonButton`, `addNeonPulse`, `addGlow`, `addGradient`, `addDigitalParticles`, `addPulse`, `addDivider`, `addGlitchText`, `applyDarkGlass`, `slideIn`.
- Fonts in use: `GothamBlack` (titles), `GothamBold` / `Gotham` (buttons, labels), `RobotoMono` / `Code` ("system" text). Stick to these three roles.

### Palette contrast (measured against `bg` 5,3,15 and `bgPanel` 20,16,40)

| Token | on bg | on panel | Safe for |
|---|---|---|---|
| textPrimary | 18.1 | 16.4 | anything |
| textSecondary | 6.8 | 6.2 | body text |
| textMuted | 3.4 | 3.1 | **large text / decoration only** — too faint for small text |
| neonCyan | 14.5 | 13.1 | anything |
| neonGold | 13.2 | 12.0 | anything |
| neonMagenta | 5.9 | 5.4 | body text |
| neonPurple | 4.5 | 4.0 | large text, borders |
| neonBlue | 4.3 | 3.9 | large text, borders |

Rule of thumb: small text needs ≥ 4.5:1, large/bold text ≥ 3:1.

---

## 2. Layout

- **Scale for size, constraints for shape.** Pure Scale sizing stretches on ultra-wide monitors and tall phones. Add `UIAspectRatioConstraint` to cards, buttons, and panels that should keep their shape, and `UISizeConstraint` to cap panels on big screens.
- **Center with AnchorPoint.** `AnchorPoint = Vector2.new(0.5, 0.5)` + `Position = UDim2.fromScale(0.5, 0.5)` instead of hand-computed values like `0.31`.
- **Use layout objects for rows and stacks.** `UIListLayout` (with `Padding`) for button stacks, `UIGridLayout` for card grids, `UIPadding` for inner spacing. Then adding or removing a button needs no repositioning.
- **Respect safe areas.** `IgnoreGuiInset = true` lets UI draw under Roblox's top bar. Keep interactive elements out of the top bar area and away from phone notches; `ScreenGui.ScreenInsets` can handle this automatically.
- **Use a fixed ZIndex scale:** background 1–3, content 4–6, floating buttons ~20–25, modals/overlays 30+. Don't invent random values.

## 3. Text

- `TextScaled = true` lets every label pick its own size, so neighbouring buttons end up with different text sizes. Always pair it with a `UITextSizeConstraint` (`MaxTextSize`, `MinTextSize`), or use a fixed `TextSize` for body text.
- Keep text readable on phones — avoid going below roughly 14 px.
- `TextWrapped = true` for questions and descriptions; `TextTruncate` for player names.
- Use `RichText` for emphasis inside one label instead of stacking several labels.

## 4. Input on every device

- A large share of Roblox players are on phones and tablets: design for touch first, then check mouse and gamepad.
- **Use `Activated` instead of `MouseButton1Click`** for buttons — `Activated` fires for mouse, touch, and gamepad.
- Touch targets should be at least ~44×44 px.
- Hover effects don't exist on touch — every button also needs press feedback (scale or color change on press).
- Gamepad/console: buttons must be `Selectable`; when a screen opens, set `GuiService.SelectedObject` to its main button so controller players can navigate.

## 5. Motion

- Animate with `TweenService` (`Position`, `Size`, `Rotation`, transparency properties).
- Button feedback: ~0.1–0.2 s. Screen entrances: ~0.2–0.4 s with `Quad`/`Quint` + `Out` easing.
- Looping effects (`task.spawn` + `while ... do` tweens, like `addNeonPulse`) must stop when their element is destroyed, and ideally pause while hidden.
- Keep particle counts low; cheap phones struggle with many animated UI elements.
- Fewer, purposeful animations beat everything moving at once.

## 6. Visual style: game vs. web advice

Web design guides (including the UI Skills catalog) say "no glows, no purple gradients". This game's neon anime look is deliberate, so keep it, but:

- **One main accent per screen.** The primary action (e.g. START QUIZ) should be the brightest, most saturated thing; secondary buttons are quieter.
- **Glow is decoration, never the only signal.** States like selected / locked / disabled also change the text or icon, not just the glow.
- **Locked collection cards:** silhouette + "???" + a short hint on how to unlock.
- **Empty states always offer one clear next action** (e.g. an empty collection → "Take the quiz").

## 7. Code hygiene

- One module per screen, each with `build(...)` that destroys any previous copy of its frame first (existing pattern — keep it).
- **Disconnect event connections** when a screen closes. Known issue: `SettingsUI` connects `UserInputService.InputChanged` / `InputEnded` every time the panel opens and never disconnects them.
- Give instances a `Name` so `FindFirstChild` works and debugging in the Explorer is easy.
- Put shared values (colors, fonts, sizes, tween times) in `UIEffects` rather than repeating literals.

## 8. Checklist for every UI change

- [ ] Uses palette tokens from `UIEffects.COLORS`; small text meets contrast (section 1)
- [ ] Text sizes are consistent (`UITextSizeConstraint` or fixed `TextSize`)
- [ ] Shapes hold with `UIAspectRatioConstraint`; nothing stretches on wide or tall screens
- [ ] Buttons use `Activated`, are ≥ ~44 px, and give press feedback
- [ ] Main action is visually dominant; only one main accent on the screen
- [ ] Nothing interactive under the Roblox top bar or a phone notch
- [ ] Loops and connections are cleaned up
- [ ] Tested in Studio's Device Emulator: phone, tablet, desktop, console

## CSS → Roblox cheat sheet (for translating web UI advice)

| Web / CSS | Roblox |
|---|---|
| `padding` | `UIPadding` |
| flexbox, `gap` | `UIListLayout` (`Padding`) |
| CSS grid | `UIGridLayout` |
| `border-radius` | `UICorner` |
| `border` | `UIStroke` (`ApplyStrokeMode = Border`) |
| `linear-gradient` | `UIGradient` |
| `max-width` / `min-width` | `UISizeConstraint` |
| `aspect-ratio` | `UIAspectRatioConstraint` |
| `clamp()` font size | `UITextSizeConstraint` |
| `z-index` | `ZIndex` (with `ZIndexBehavior = Sibling`) |
| CSS transitions | `TweenService` |
| `safe-area-inset` | `ScreenGui.ScreenInsets` |
| `:hover` | `MouseEnter` / `MouseLeave` |
| `onclick` | `Activated` |

## 9. Lessons log

Add newest entries at the top: date, what happened, what to do next time.

- **2026-10-14** — Removing the hub, spin wheel and inventory buttons meant hand-repositioning every remaining button on the welcome and results screens, because positions are hard-coded Scale values. Next time: put button stacks/rows in a `UIListLayout` so removing one needs no layout edits.
- **2026-10-14** — The UI Skills connector (ui-skills.com) has no Roblox-specific guides; everything is web-focused. Useful ones to translate with the cheat sheet above: `ibelick/baseline-ui`, `ibelick/fixing-accessibility`, `jakubkrehel/better-typography`, `jakubkrehel/make-interfaces-feel-better`, `raphaelsalaja/12-principles-of-animation`.
- **2026-10-14** — Audit of current code: no `UITextSizeConstraint`, `UIAspectRatioConstraint`, `UIListLayout`, or `AnchorPoint` centering in the main screens; ~35 labels use `TextScaled` alone; buttons use `MouseButton1Click`. These are the first things to fix in a polish pass.
