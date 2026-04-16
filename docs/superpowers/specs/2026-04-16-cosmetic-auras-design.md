# Cosmetic Auras — Design Spec

## Overview

Archetype-themed particle auras that automatically appear on a player's character after completing the quiz. Each of the 10 archetypes has a unique visual identity: torso particles (body aura) + ground ring (under feet). Auras are free — no purchase required.

---

## Behavior

- After completing the quiz, the player's character gets a particle aura matching their result archetype.
- Aura is visible to all players in the server.
- Aura persists across respawns within the same session.
- When a player retakes the quiz and gets a new archetype, the old aura is removed and replaced with the new one.
- On join, players with a saved archetype from a previous session get their aura applied immediately.
- Auras are purely cosmetic — no gameplay effect.

---

## Architecture

**Server-driven, client-rendered.**

The server already broadcasts archetype assignments via `LeaderboardManager` → `LeaderboardUpdate` RemoteEvent. A new client-side `AuraController` module listens for these updates and attaches `ParticleEmitter` instances to characters.

### New Files

| File | Location | Purpose |
|---|---|---|
| `AuraDefinitions.luau` | `src/shared/` | Maps each archetype ID to particle config (colors, speed, size, lifetime, light) |
| `AuraController.client.luau` | `src/client/` | Listens for archetype assignments, attaches/removes particle emitters on characters, handles respawns |

### Modified Files

| File | Change |
|---|---|
| `LeaderboardManager.server.luau` | No changes needed — already broadcasts archetype data per player |
| `default.project.json` | No changes needed — `src/shared/` and `src/client/` already mapped |

---

## Aura Definitions

Each archetype maps to a particle configuration with these properties:

- `torsoColor`: ColorSequence for body particles
- `torsoSpeed`: NumberRange for particle speed
- `torsoRate`: number of particles per second
- `torsoLifetime`: NumberRange for particle lifetime
- `torsoSize`: NumberSequence for particle size over lifetime
- `torsoSpread`: Vector2 spread angle
- `groundColor`: ColorSequence for ground ring particles
- `groundRate`: number of particles per second
- `lightColor`: Color3 for the PointLight attached to torso
- `lightBrightness`: number for PointLight brightness

### Per-Archetype Visual Design

| Archetype | Torso Effect | Ground Effect | Light |
|---|---|---|---|
| hot_headed_hero | Orange-red flames, fast upward | Red-orange ring | Warm red, brightness 0.6 |
| cool_strategist | Blue-white frost sparkles, slow drift | Ice blue ring | Cool blue, brightness 0.4 |
| lone_wolf | Dark purple mist, slow spread | Purple haze ring | Dim purple, brightness 0.3 |
| gentle_protector | Green leaf/heal particles, gentle float | Soft green ring | Green, brightness 0.4 |
| chaotic_wildcard | Electric purple-white sparks, erratic | Magenta flash ring | Purple-pink, brightness 0.5 |
| silent_powerhouse | White energy wisps, pulsing | White glow ring | Bright white, brightness 0.5 |
| loyal_companion | Warm orange embers, gentle rise | Orange glow ring | Warm orange, brightness 0.4 |
| wise_mentor | Gold light motes, slow orbit | Gold ring | Gold, brightness 0.5 |
| rebel_with_a_cause | Crimson embers, aggressive upward | Dark red ring | Deep red, brightness 0.5 |
| cheerful_optimist | Yellow sparkles, bouncy/playful | Yellow ring | Bright yellow, brightness 0.5 |

---

## AuraController Logic

### Initialization
1. On client start, listen for `LeaderboardUpdate` events (already fired by server).
2. For each player in the update data, check if their archetype has changed.
3. If changed (or new), remove old aura and apply new one.

### Applying an Aura
1. Get the player's `Character` (wait for it if not loaded).
2. Find `HumanoidRootPart` (torso particles) and `HumanoidRootPart` base position (ground ring).
3. Create two `ParticleEmitter` instances:
   - **Torso emitter**: parented to `HumanoidRootPart`, emits upward/outward
   - **Ground emitter**: parented to a small `Part` anchored at the character's feet, emits outward in a ring
4. Create a `PointLight` on `HumanoidRootPart` with the archetype's light color.
5. Tag all created instances with a `AuraEffect` attribute for easy cleanup.

### Removing an Aura
1. Find all children of the character tagged with `AuraEffect`.
2. Destroy them.
3. Remove the ground part if it exists.

### Respawn Handling
- Listen to `player.CharacterAdded` for the local player.
- Listen to `Players.PlayerAdded` → `CharacterAdded` for other players.
- Re-apply the aura from cached archetype data on each respawn.

### Cleanup
- When a player leaves the server, their character is destroyed automatically (Roblox handles this).
- Ground parts are anchored and welded, so they clean up with the character.

---

## Performance

- **Torso particles**: Rate capped at 15-20/sec, lifetime 0.5-1.5s
- **Ground particles**: Rate capped at 8-12/sec, lifetime 0.8-1.2s
- **PointLight**: Range 8-12 studs, no shadows
- Total particle count per player stays low enough for 20+ player servers
- No custom rendering — all standard Roblox `ParticleEmitter` instances

---

## Data Flow

```
Server (LeaderboardManager)
  → fires LeaderboardUpdate RemoteEvent with [{name, archetypeId, archetypeName}]
  
Client (AuraController)
  → receives update
  → for each player, compares archetypeId to cached value
  → if changed: removeAura(character), applyAura(character, archetypeId)
  → caches new archetypeId per player
  → on CharacterAdded: re-applies cached aura
```

No new RemoteEvents needed. The existing `LeaderboardUpdate` event carries all required data.
