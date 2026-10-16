# Roblox UI Guide

A living guide for building and polishing this game's UI. **Read it before any UI work, and add to the Lessons log (section 9) whenever something is learned** — a fix that worked, a mistake to avoid, feedback from playtesting.

---

## 1. How this game's UI is built

- The UI is written with **React Luau** (`jsdotlua/react` + `react-roblox` 17.2.1, installed by Wally into `Packages/`). Nothing is hand-built in Studio's StarterGui.
- `src/client/Main.client.luau` starts the music and mounts `UI/App` into PlayerGui.
- `UI/App.luau` owns all UI state (current screen, quiz progress, latest result, collection) and is the only UI code that talks to the server. Screens draw what they're given and report button presses back up.
- Three ScreenGuis, back to front:
  - **Backdrop** (`ScreenInsets = None`): full-screen paper and the per-screen watermark kanji.
  - **Content** (`ScreenInsets = CoreUISafeInsets`): the current screen, clear of Roblox's top bar and notches.
  - **Overlay** (`ScreenInsets = None`): the settings popup.
- **Fixed design size, scaled to fit.** Every screen is laid out in pixels on a 1280×720 canvas (`Theme.DESIGN_SIZE`), matching the design mockup. `useFitScale` computes one `UIScale` that fits that canvas into the player's screen, so proportions and text sizes stay consistent on every device.
- Folder layout under `src/client/UI/`:
  - `Theme.luau` — every color, font, text size, spacing value and tween. Read from here; never repeat literals.
  - `Components/` — reusable pieces: `Label`, `InkButton`, `IconButton`, `AnswerButton`, `Seal`, `Chip`, `ProgressBar`, `OrnateCard`, `InkRing`, `TitleCard`, `Slider`, `Spacer`, `ScreenBackdrop`, `InkIcon` (drawn icons), `ScaledText` (text over 100 px).
  - `Screens/` — `WelcomeScreen`, `QuizScreen`, `TimerScreen`, `ResultsScreen`, `CollectionScreen`, `SettingsPanel`.
  - `Hooks/` — `useFitScale`, `useRemoteEvent`, `useSecondsLeft`, `useProductPrice`.
  - `Util/` — `Format` (clock, minutes, Robux), `Kanji` (numerals), `Input` (press/move checks).

### Look: Japanese traditional

Washi paper, sumi ink, one vermilion accent. The paper fills the whole screen; nothing frames the edges. Each title has a kanji shown on a red seal stamp (炎 智 狼 守 乱 静 絆 師 反 陽, defined in `shared/Data/Archetypes.luau`). Fonts: Merriweather (display) and Nunito (body), both built into Roblox; Roblox draws kanji with its own Japanese font.

### Palette contrast (measured; small text needs ≥ 4.5:1, large text ≥ 3:1)

| Token | Hex | Against | Ratio | Safe for |
|---|---|---|---|---|
| ink | #1E1A17 | paper #F3EAD7 | 14.5 | anything |
| inkSoft | #3A332D | paper | 10.4 | body text |
| textMuted | #5E554B | paper | 6.1 | secondary text |
| textLocked | #655A4E | paperDim #E9DFC9 | 5.1 | text on locked cards |
| vermilion | #B8372B | paper | 4.9 | text, buttons (paper text on vermilion is also 4.9) |
| lockedBorder | #9A8F80 | paperDim | 2.4 | **decoration only** |

---

## 2. Layout

- **Lay out in design pixels.** Inside a screen, use offsets on the 1280×720 canvas; the canvas `UIScale` handles real screen sizes. Put layout numbers in named constants at the top of the screen file.
- **Center with AnchorPoint.** `AnchorPoint = Vector2.new(0.5, 0.5)` + `Position = UDim2.fromScale(0.5, 0.5)`.
- **Use layout objects for rows and stacks.** `UIListLayout` for stacks and rows, `UIGridLayout` for card grids, `UIPadding` for inner spacing, `Spacer` for one-off vertical gaps. Adding or removing an item then needs no repositioning.
- **Respect safe areas.** Interactive UI lives in the Content ScreenGui (`CoreUISafeInsets`); only decoration goes under the top bar.
- **ZIndex:** use `ZIndexBehavior = Sibling` and small local values (shadow 1, face 2). Layering between big layers comes from the three ScreenGuis' `DisplayOrder`.

## 3. Text

- Use the `Label` component: theme font and color, wraps, grows to fit. Sizes come from `Theme.TextSize`.
- Avoid `TextScaled` for UI text (each label picks its own size).
- **Roblox caps `TextSize` (and `TextScaled`) at 100 px.** For anything bigger (seal kanji, the watermark) use `ScaledText`, which enlarges a 100 px label with a `UIScale`.
- **Don't use symbol characters for icons** (✕ ⚙ ←): the game fonts lack them and they render as empty boxes. Use `InkIcon`.
- Keep text readable on phones: nothing below `Theme.TextSize.small` (14) on the design canvas, and check the phone emulator, where the canvas scales down.

## 4. Input on every device

- **Buttons use `Activated`**, which fires for mouse, touch and gamepad. `InkButton`, `AnswerButton` and `IconButton` already do.
- Touch targets ≥ ~44 px on the design canvas.
- Every button gives press feedback (`UIScale` to `Theme.Motion.PRESS_SCALE`), since hover doesn't exist on touch.
- Gamepad: pass `selectOnMount = true` to a screen's main `InkButton` so controller players start on it.
- Use `Util/Input` (`isPress`, `isMove`) instead of re-checking `UserInputType` by hand.

## 5. Motion

- Animate with `TweenService` on refs inside `useEffect`, and cancel delayed threads in the effect's cleanup.
- Button feedback ≤ 0.2 s; entrances 0.2–0.4 s with `Quad`/`Back` + `Out`.
- **Never block on an asset loading** (`Sound.Loaded:Wait()` etc.) before scheduling what happens next. A failed load would freeze the flow.

## 6. Visual style

- **One main accent per screen.** The primary action is the only vermilion button; secondary buttons are ink outlines.
- **State is never color alone.** Locked titles show "?" and "???" plus a hint, not just a faded color.
- **lockedBorder is decoration only** (contrast too low for text).
- **Empty or blocked states say what to do next** (e.g. "You can take the quiz again in 12:30.").

## 7. Code hygiene

- **No repeated literals.** Colors, fonts, sizes, tweens → `Theme`; game numbers (timings, product IDs) → `shared/Config.luau`; remote names → `Remotes.Events` / `Remotes.Functions`. Layout numbers used once go in named constants at the top of the file.
- **One component per module**, props typed with `export type Props`.
- **Clean up in `useEffect`**: every `:Connect` returns a cleanup that disconnects; every `task.delay` is cancelled.
- **Latest-callback refs**: when a long-lived connection calls a prop, store the prop in a ref (`onDoneRef.current = props.onDone`) so it never calls a stale one.
- Run the type checker before committing (see `CLAUDE.md`).

## 8. Checklist for every UI change

- [ ] Uses `Theme` tokens; small text meets the contrast table (section 1)
- [ ] Text through `Label` with `Theme.TextSize` values
- [ ] Layout in design pixels with named constants; stacks use layout objects
- [ ] Buttons use `Activated`, are ≥ ~44 px, and give press feedback
- [ ] Only one vermilion (primary) button on the screen
- [ ] Connections and delayed threads cleaned up
- [ ] Type checker passes
- [ ] Tested in Studio's Device Emulator: phone, tablet, desktop, console

## CSS → Roblox cheat sheet (for translating web UI advice)

| Web / CSS | Roblox |
|---|---|
| `padding` | `UIPadding` |
| flexbox, `gap` | `UIListLayout` (`Padding`) |
| CSS grid | `UIGridLayout` |
| `border-radius` | `UICorner` |
| `border` | `UIStroke` (`ApplyStrokeMode = Border` on text objects) |
| `linear-gradient` | `UIGradient` |
| `max-width` / `min-width` | `UISizeConstraint` |
| `aspect-ratio` | `UIAspectRatioConstraint` |
| `transform: scale()` | `UIScale` |
| `z-index` | `ZIndex` (with `ZIndexBehavior = Sibling`) |
| CSS transitions | `TweenService` |
| `safe-area-inset` | `ScreenGui.ScreenInsets` |
| `:hover` | `MouseEnter` / `MouseLeave` |
| `onclick` | `Activated` |

## 9. Lessons log

Add newest entries at the top: date, what happened, what to do next time.

- **2026-10-15** — Playtest feedback round: the ink "scroll rod" bars at the top and bottom read as black strips, so they were removed and the paper fills the screen. The settings ✕ rendered as an empty box (missing glyph), so all icons are now drawn ink strokes (`InkIcon`). The watermark and the big result-seal kanji were capped at 100 px — fixed with `ScaledText`. Seals inside a `UIListLayout` lost their tilt; tilt an inner frame inside an untilted holder instead.
- **2026-10-15** — Meme interludes and their sounds were removed (didn't fit the theme), along with the sound-effects volume. Players can now retake the quiz right after seeing a result; the 15-minute wait applies only before a result is revealed.
- **2026-10-15** — First Studio playtest of the React UI: every screen, the interlude, timer skips, collection, the wait notice and the settings sliders worked with no script errors. Rojo's live sync missed a large batch of new files in new folders (the place ended up with empty Server/Client folders); restarting `rojo serve` and reconnecting fixed it. After big file moves, reconnect Rojo and check the script count in Studio.
- **2026-10-15** — Answer buttons now also guard with a ref (one answer per question number), because a React `enabled` prop only updates on the next render and two taps in one frame could both submit.
- **2026-10-15** — Rebuilt the whole UI in React Luau with the Japanese traditional look, from the design mockup. The fixed 1280×720 canvas + one `UIScale` made matching the mockup straightforward; keep using design pixels rather than mixing Scale and Offset per element.
- **2026-10-15** — `UIStroke` on a `TextButton`/`TextLabel` outlines the *text* unless `ApplyStrokeMode = Border` is set. Every bordered button and chip sets it.
- **2026-10-15** — The old meme interlude waited for its sound to load before scheduling its exit; a sound that never loaded would freeze the quiz behind a dark overlay. The React version plays the sound without waiting.
- **2026-10-15** — Answering two questions within 0.8 s made the server silently drop an answer while the client moved on, leaving the quiz stuck on "Calculating". Fixed with a client answer lock (0.4 s) below the server's average-pace limit (0.3 s/answer). Both live in `shared/Config.luau`; keep the client lock above the server limit.
- **2026-10-14** — Removing the hub, spin wheel and inventory buttons meant hand-repositioning every remaining button, because positions were hard-coded. Layout objects avoid that.
- **2026-10-14** — The UI Skills connector (ui-skills.com) has no Roblox-specific guides; everything is web-focused. Useful ones to translate with the cheat sheet: `ibelick/baseline-ui`, `ibelick/fixing-accessibility`, `jakubkrehel/better-typography`, `jakubkrehel/make-interfaces-feel-better`, `raphaelsalaja/12-principles-of-animation`.
