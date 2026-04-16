# Anime Personality Quiz Game — Design Spec

## Overview

A UI-driven Roblox quiz game where players answer 20+ questions (mix of scenario-based and preference-based) that determine which of 10 anime personality archetypes best matches their personality. Results are revealed behind a timer with multiple monetization options. Players collect archetypes across sessions, see each other's results in-server, and enjoy random funny interludes between questions.

**Approach:** Start as a pure UI game (V1), layer on a 3D anime-themed hub world in V2.

---

## Archetypes (10 Total)

| # | Archetype | Example Characters |
|---|-----------|-------------------|
| 1 | The Hot-Headed Hero | Naruto, Goku, Asta |
| 2 | The Cool Strategist | Lelouch, Shikamaru, Light |
| 3 | The Lone Wolf | Sasuke, Levi, Guts |
| 4 | The Gentle Protector | Tanjiro, Deku, Tohru |
| 5 | The Chaotic Wildcard | Gojo, Hisoka, Denji |
| 6 | The Silent Powerhouse | Saitama, Jotaro, Mob |
| 7 | The Loyal Companion | Killua, Zenitsu, Chopper |
| 8 | The Wise Mentor | Kakashi, Urahara, Shanks |
| 9 | The Rebel With a Cause | Eren, Lelouch, Vegeta |
| 10 | The Cheerful Optimist | Luffy, Anya, Hinata Shoyo |

Each archetype has a name, description, and 3-4 example anime characters.

---

## Quiz Engine & Data Model

### Questions
- 20+ questions total
- Mix of ~10-12 scenario-based ("You see a friend being bullied. Do you...") and ~10-12 preference-based ("Pick your favorite element: Fire / Water / Lightning / Shadow")
- Each question has 4 answer options
- Each answer maps to weighted scores across the 10 archetypes (e.g., picking "fight back immediately" gives +3 Hot-Headed Hero, +1 Rebel With a Cause)
- Questions are shuffled each playthrough for replayability

### Scoring
- Scores accumulate across all 10 archetypes as the player answers
- Final result is the highest-scoring archetype
- Ties broken by secondary archetype scores
- Scoring happens server-side to prevent exploit manipulation

### Data Storage
- Questions and archetype definitions stored in ModuleScripts (Lua tables)
- Easy to edit and extend without external databases

---

## UI Flow & Screens

### Screen Progression
1. **Welcome Screen** — game title, "Start Quiz" button, "My Collection" button
2. **Quiz Screen** — question number (e.g., "3/24"), question text, 4 answer buttons, progress bar at top, no back button (answers are final)
3. **Timer Screen** — 15-minute countdown with skip options (see Monetization)
4. **Results Screen** — shareable card with archetype name, description, example characters, stylized visual. Buttons: "Retake Quiz", "View Collection"
5. **Collection Screen** — grid of all 10 archetypes. Unlocked ones show full color with description. Locked ones are greyed out / silhouetted. Accessible from Welcome Screen or Results Screen.
6. **Server Leaderboard** — toggleable side panel showing each player's archetype and the most common archetype in the server

### Random Interludes
- Between questions, ~1 in 4-5 chance of a brief interlude
- A funny/meme-style image pops up (center overlay) with a sound effect (anime dramatic stings, goofy boings, vine boom, etc.)
- Lasts 2-3 seconds, then auto-dismisses
- Pool of ~10-15 image/sound combos to avoid repetition
- Assets stored as Decals (images) and Sound objects, picked at random

---

## Monetization (V1)

Three monetization channels on the timer screen:

### 1. Timer Skip (Developer Product)
- 5 Robux per 5-minute skip
- Repeatable (up to 3 times to skip the full 15 minutes)
- Uses MarketplaceService Developer Product (repeatable purchase)

### 2. Instant Unlock GamePass
- One-time purchase: 49 Robux
- Permanently removes the timer for all future quizzes on that account
- GamePass owners skip straight to results after quiz completion

### 3. Video Ad Skip
- "Watch an ad to skip 5 minutes" button alongside the Robux skip
- Uses Roblox AdService
- Free for the player, earns ad revenue
- Available alongside the Robux skip option

### Timer Screen Priority
- GamePass owners: skip timer entirely, go straight to results
- Everyone else: sees 15-minute timer with both Robux skip and ad skip options

---

## Social Features & Persistence

### Archetype Display
- After completing the quiz, most recent archetype shows as a text tag above player's character head (e.g., "[Lone Wolf]")
- Visible to all players in the server

### Server Leaderboard
- Toggleable side panel
- Shows each player's name and their archetype
- Highlights the most common archetype at the top (e.g., "Server's Top Archetype: Chaotic Wildcard — 4 players")

### Collection / Profile
- Saved using Roblox DataStoreService — persists across sessions
- Tracks which of the 10 archetypes the player has unlocked
- Collection screen shows all 10 as cards
- Encourages retakes to "collect them all"

### Data Saved Per Player
- Current archetype (for overhead display)
- Set of unlocked archetypes
- GamePass ownership (for instant unlock check)

---

## Technical Architecture

### Client (StarterGui / StarterPlayerScripts)
- **UI Controller** — manages screen transitions (Welcome > Quiz > Timer > Results > Collection)
- **Quiz Controller** — handles question display, answer input, interlude triggers
- **Sound/Image Controller** — plays random interludes (picks from asset pool)

### Server (ServerScriptService)
- **Quiz Scoring** — receives player answers, calculates archetype results server-side
- **DataStore Manager** — saves/loads player collections and current archetype
- **Monetization Handler** — processes Developer Product purchases, GamePass checks, ad reward verification
- **Leaderboard Manager** — tracks archetypes of all players in the server, broadcasts updates

### Shared (ReplicatedStorage)
- **Question Bank ModuleScript** — all 20+ questions with answer-to-archetype weight mappings
- **Archetype Definitions ModuleScript** — names, descriptions, example characters, display info
- **Interlude Assets** — pool of images (Decals) and sounds
- **RemoteEvents/RemoteFunctions** — client-server communication for submitting answers, receiving results, syncing leaderboard

### Key Principle
Player answers are sent to the server, scoring happens server-side, and results are returned to the client. This prevents players from manipulating their results through exploits.

---

## V2 Roadmap (Future)

- Anime-themed 3D hub world (cherry blossoms, neon signs, etc.)
- Premium quiz packs ("Shonen Edition", "Villain Arc Edition", "Romance Anime Edition") — 25-50 Robux each
- Cosmetic archetype skins/auras (fire particles, shadow trails, etc.) — 50-100 Robux each
- Paid archetype badges (social flex titles) — 10-25 Robux each
- Share-to-feed (post result card to Roblox activity feed) — 5 Robux
