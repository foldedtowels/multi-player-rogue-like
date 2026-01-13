# Deck Masters - Godot Roguelike Deck Builder

## Project Overview
A multiplayer roguelike deck-building game built in Godot 4, inspired by Slay the Spire. Players take simultaneous turns, selecting cards to play against opponents in real-time combat.

### Core Systems
- **Combat System** (`scripts/combat.gd`) - Turn-based combat with card effects
- **Card System** (`scripts/card.gd`, `scripts/card_visual.gd`) - Card mechanics and rendering
- **Character System** (`scripts/character.gd`) - Player stats, HP, deck management
- **Game Manager** (`scripts/game_manager.gd`) - Multiplayer state, turn synchronization
- **Rewards** (`scripts/reward.gd`, `scripts/rewards/`) - Post-combat rewards and progression

---

## Documentation Philosophy

**Prefer TODOs over documentation files.** When something needs to be done:
1. Add a `# TODO:` comment directly in the relevant code
2. Use the TodoWrite tool to track tasks during sessions
3. Only create `.md` files for permanent reference material (like this file)

**Why**: TODOs in code are visible when working on that code. Separate doc files get stale and forgotten.

---

## Critical Patterns (Learned the Hard Way)

### 1. Always use `queue_free()`, never `free()`
Objects are "locked" during signal emission or animation. `free()` crashes, `queue_free()` defers safely.

### 2. Never call RPCs from dynamically created nodes
Nodes created with `.new()` don't have stable paths across network. Use signal relay pattern:
```gdscript
# Dynamic node emits signal → Scene node catches → Scene node calls RPC
signal choice_made(data)
choice_made.emit(data)  # In dynamic node
# Scene node connects and calls rpc_id() from there
```

### 3. Use `initialize_combat_encounter()` for all encounters
```gdscript
game_manager.initialize_combat_encounter(GameManager.EncounterType.MINION, boss_index)
game_manager.initialize_combat_encounter(GameManager.EncounterType.BOSS_PHASE_1, boss_index)
```
Old functions (`start_boss_encounter()`, `reset_players_between_encounters()`) are deprecated.

### 4. Shield resets at turn START, not END
Matches Slay the Spire mechanics - shield persists through enemy turn so players can use it.

### 5. Don't emit `game_state_changed` for minor UI updates
Card previews triggered full hand rebuilds, destroying cards mid-drag. Only emit for actual state changes.

### 6. Host timing differs from clients
Host executes RPCs instantly; clients have network delay. Bugs that only affect host often involve destroy/recreate patterns.

---

## Multiplayer Debugging Tips

- State transitions are the safest place to reset per-turn data (not in RPCs)
- Add `[SYNC]` prefix to debug prints for multiplayer issues
- Use turn separator banners for console readability:
```gdscript
print("\n##################### ROUND ", round, " - FRIENDLY TURN #####################")
```
- If "RPC sent but never received", check if calling node is dynamically created

---

## Code Style

- Type hints: `var cards: Array[Card] = []`
- Match statements over if/elif for state handling
- Functions under 50 lines when possible
- Debug prints: Use `# DEBUG:` comment for temporary, remove before commit
- Prefixes: `[COMBAT]`, `[CARD]`, `[SYNC]`, `[STATE]`

---

## Known Issues (Low Priority)

- Round number display may jump randomly (cosmetic)
- HeroDatabase builds decks repeatedly during char selection
- Passive ability UI modal incomplete
- Card v2 choice modal incomplete

---

## Resources

- [Godot Multiplayer Docs](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)
- `docs/SLAY_THE_SPIRE_RESEARCH.md` - Card balance inspiration
- `docs/REWRITE_ASSESSMENT.md` - Why we're NOT rewriting (Jan 2026 analysis)

---

**Last Updated**: 2026-01-12
