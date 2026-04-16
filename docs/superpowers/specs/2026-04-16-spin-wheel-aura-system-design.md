# Spin Wheel Aura System — Design Spec

## Overview

Replace the current archetype-based aura system with a gacha-style spin wheel. Players earn free spins by completing quizzes and can buy additional spins with Robux. Auras are separated into 6 rarity tiers with weighted drop rates. Duplicate auras award shards, which can be used to craft specific auras. A Secret rarity (0.5%) transforms the player's avatar with anime-style accessories and an extreme aura effect.

---

## What Changes

### Removed
- Auras are no longer auto-unlocked from quiz results
- `AuraSelectUI.luau` — replaced by `InventoryUI.luau`
- Ad skip button on the timer screen (removed entirely)

### Unchanged
- Quiz flow (questions, scoring, archetype results, overhead tags, collection)
- Timer screen (15-minute wait, 5 Robux skip, 49 Robux instant unlock GamePass)
- Results screen (archetype card with description) — gains a "SPIN WHEEL" button
- Music player, leaderboard, interlude memes
- `AuraDefinitions.luau` — particle configs per archetype stay as-is
- `AuraController.client.luau` — still renders auras, but validates against new `unlockedAuras` field

### New
- Spin Wheel UI with animated wheel
- Inventory UI for equipping owned auras
- Rarity system with weighted drops
- Shard economy for duplicate protection
- Spin purchase products (1 spin, 5 spins)
- Secret rarity avatar transformation

---

## Rarity System

### Drop Table

| Rarity | Color | Drop Rate | Auras | Shard Value (duplicate) | Craft Cost |
|---|---|---|---|---|---|
| Common | White | 40% | Gentle Protector, Loyal Companion, Cheerful Optimist | 1 shard | 5 shards |
| Uncommon | Green | 25% | Cool Strategist, Wise Mentor, Silent Powerhouse | 3 shards | 10 shards |
| Rare | Blue | 18% | Hot-Headed Hero, Rebel With a Cause | 5 shards | 20 shards |
| Epic | Purple | 12% | Lone Wolf | 10 shards | 40 shards |
| Legendary | Gold | 4.5% | Chaotic Wildcard | 25 shards | 100 shards |
| Secret | ??? | 0.5% | Anime Transformation | 50 shards | 200 shards |

Total: 100%

### Aura-to-Rarity Mapping

| Aura ID | Rarity |
|---|---|
| gentle_protector | common |
| loyal_companion | common |
| cheerful_optimist | common |
| cool_strategist | uncommon |
| wise_mentor | uncommon |
| silent_powerhouse | uncommon |
| hot_headed_hero | rare |
| rebel_with_a_cause | rare |
| lone_wolf | epic |
| chaotic_wildcard | legendary |
| anime_transformation | secret |

---

## Spin Economy

### Earning Spins
- 1 free spin awarded after each quiz completion (after the timer/results flow)
- Free spins accumulate — no cap

### Buying Spins
- **1 Spin**: 10 Robux (Developer Product, repeatable)
- **5 Spins**: 40 Robux (Developer Product, repeatable — 20% discount)

### Spin Mechanics
- Server-authoritative: client requests spin, server rolls result using weighted random, returns the result
- Client animates the wheel to land on the server-determined result
- No client-side manipulation possible

---

## Shard System

### Earning Shards
- Rolling a duplicate aura awards shards based on that aura's rarity (see table above)
- No other shard sources in V1

### Spending Shards
- Craft a specific aura from the Inventory screen by paying its rarity's craft cost
- Crafting instantly unlocks the aura — no spin required
- Can only craft auras you don't already own

---

## Secret Rarity — Anime Transformation

The Secret aura is not tied to any archetype. When equipped:
- Player keeps their avatar body
- Adds: anime-style spiky hair accessory (Hat accessory)
- Adds: glowing eyes overlay (face decal or BillboardGui on head)
- Adds: extreme full-body particle aura — all 5 emitter layers at 3x the normal intensity
- Adds: unique ground ring with rainbow/prismatic color cycling
- The overhead tag shows "[???]" in rainbow cycling text

This is rendered entirely in `AuraController.client.luau` with a special case for `anime_transformation`.

---

## Data Storage

### Updated PlayerData Type

```
PlayerData = {
    currentArchetype: string,       -- latest quiz result (unchanged)
    unlockedArchetypes: { string }, -- quiz collection (unchanged)
    selectedAura: string,           -- equipped aura id (unchanged field, new meaning)
    unlockedAuras: { string },      -- NEW: aura ids won from spins
    shards: number,                 -- NEW: shard currency balance
    freeSpinsAvailable: number,     -- NEW: earned from quizzes, consumed on spin
}
```

Migration: existing `selectedAura` values that reference old archetype-based auras will be cleared on load if not in `unlockedAuras`. Existing players start fresh with the spin system.

---

## UI Flow

### After Quiz Completion
1. Quiz → Timer screen (wait or pay to skip) → Results screen
2. Results screen shows archetype result + buttons: RETAKE QUIZ, COLLECTION, SPIN WHEEL, EXPLORE HUB
3. SPIN WHEEL → Spin Wheel screen

### Spin Wheel Screen
- Shows the wheel with 11 segments (one per aura), sized proportionally to drop rate
- Displays: "Free Spins: X" counter, "Buy 1 Spin (10 R$)" button, "Buy 5 Spins (40 R$)" button
- "SPIN" button (enabled when freeSpinsAvailable > 0 or player clicks buy)
- Wheel spins for ~4 seconds, slows down, lands on result
- Result reveal: rarity-colored flash, aura name, "NEW!" or "+X Shards" badge
- After reveal: "SPIN AGAIN" (if spins available), "INVENTORY" button, "BACK" button

### Inventory Screen (replaces AuraSelectUI)
- Grid of all 11 auras
- Owned: shows aura name, rarity badge (colored), "EQUIP" / "EQUIPPED" button
- Not owned: shows "???" with rarity color border, shard craft cost, "CRAFT (X shards)" button if player has enough
- Shard balance displayed at top
- BACK button returns to welcome screen

### Welcome Screen
- "CHANGE AURA" button renamed to "INVENTORY"
- Everything else unchanged

---

## New Remotes

| Name | Type | Direction | Purpose |
|---|---|---|---|
| RequestSpin | RemoteFunction | Client → Server | Consume a free spin, server rolls and returns result |
| BuyAndSpin | RemoteFunction | Client → Server | Purchase spin with Robux, returns result after purchase confirmed |
| CraftAura | RemoteFunction | Client → Server | Spend shards to craft a specific aura, returns success |
| LoadInventory | RemoteFunction | Client → Server | Get unlockedAuras, shards, freeSpinsAvailable, selectedAura |

`SelectAura` stays — still used to equip an aura from inventory.

---

## New Files

| File | Location | Purpose |
|---|---|---|
| `AuraRarities.luau` | `src/shared/` | Rarity definitions, drop table, shard values, craft costs, aura-to-rarity mapping |
| `SpinWheelUI.luau` | `src/client/` | Wheel animation, spin button, buy buttons, result reveal |
| `InventoryUI.luau` | `src/client/` | Aura grid with equip/craft, shard display |
| `SpinHandler.server.luau` | `src/server/` | Weighted random roll, free spin consumption, shard awarding, craft validation |

## Modified Files

| File | Change |
|---|---|
| `DataStoreManager.luau` | Add unlockedAuras, shards, freeSpinsAvailable fields + migration |
| `Remotes.luau` | Add RequestSpin, BuyAndSpin, CraftAura, LoadInventory |
| `MonetizationHandler.server.luau` | Add spin purchase product IDs, handle in ProcessReceipt |
| `UIController.client.luau` | Wire up SpinWheelUI + InventoryUI, rename CHANGE AURA to INVENTORY, add SPIN WHEEL to results |
| `ResultsUI.luau` | Add SPIN WHEEL button, remove ad reference if any |
| `TimerUI.luau` | Remove ad skip button |
| `AuraController.client.luau` | Validate against unlockedAuras, add anime_transformation special case |
| `AuraDefinitions.luau` | Add anime_transformation config (extreme particles + rainbow cycling) |

## Removed Files

| File | Reason |
|---|---|
| `AuraSelectUI.luau` | Replaced by InventoryUI.luau |

---

## Monetization Products Needed

Create on Roblox Creator Dashboard:
1. **Buy 1 Spin** — Developer Product, 10 Robux
2. **Buy 5 Spins** — Developer Product, 40 Robux

Existing products unchanged:
- Skip 5 Minutes (5 Robux) — stays
- Instant Unlock GamePass (49 Robux) — stays

---

## Server-Side Spin Logic

### Weighted Random Algorithm
1. Build cumulative weight array from drop rates: [0.40, 0.65, 0.83, 0.95, 0.995, 1.0]
2. Roll `math.random()` → float 0-1
3. Find first cumulative weight that exceeds the roll → that's the rarity
4. Within that rarity, pick a random aura from the pool
5. Check if player already owns it:
   - New: add to `unlockedAuras`
   - Duplicate: add shard value to `shards`
6. Return: `{ auraId: string, rarity: string, isNew: boolean, shardsAwarded: number }`

### Validation
- `RequestSpin`: check `freeSpinsAvailable > 0`, decrement, roll
- `BuyAndSpin`: triggered after ProcessReceipt confirms purchase, roll
- `CraftAura`: check `shards >= craftCost` and aura not already owned, deduct shards, add to unlockedAuras
- All mutations followed by `DataStoreManager.save(player)`
