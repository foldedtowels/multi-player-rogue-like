# Game Loop Reference

This document describes the complete game loop for Deck Masters roguelike.

## Overview

The game follows a repeating cycle of minion encounters and boss encounters until either all 5 bosses are defeated (victory) or all players die (defeat).

```
Character Selection
       ↓
┌─────────────────────────────┐
│  Minion Fight (Boss N)      │
│            ↓                │
│  Minion Reward (heal/card)  │
│            ↓                │
│  Boss Fight (Boss N)        │
│            ↓                │
│  Boss Reward (card + relic) │
│            ↓                │
│      boss_index++           │
└─────────────────────────────┘
       ↓ (repeat 5 times)
    Victory
```

---

## State Enums

### GameState (global game state)
| State | Description |
|-------|-------------|
| `CHARACTER_SELECTION` | Hero selection screen |
| `COMBAT` | Active battle |
| `REWARD` | Post-combat reward selection |
| `GAME_OVER` | All players dead |
| `VICTORY` | All 5 bosses defeated |

### CombatPhase (encounter type)
| Phase | Description |
|-------|-------------|
| `MINION_COMBAT` | Fighting minions before a boss |
| `BOSS_PHASE_1` | First phase of boss fight |
| `BOSS_PHASE_2` | Second phase (if applicable) |

### TurnPhase (who is acting)
| Phase | Description |
|-------|-------------|
| `PLAYER_TURN` | Players select and play cards simultaneously |
| `ENEMY_TURN` | Enemies execute pre-selected actions |

---

## Detailed Flow

### 1. Minion Fight

**Initialization:** `game_manager.initialize_combat_encounter(EncounterType.MINION, boss_idx)`

- Sets `current_state = GameState.COMBAT`
- Sets `combat_phase = CombatPhase.MINION_COMBAT`
- Loads minions from `minion_db.get_minions_for_boss(boss_idx)`
- Resets player HP, stamina, shields, and status effects
- Shuffles draw piles
- Applies `FIGHT_START` relic effects

**Combat Round Loop:**
1. **Round Start** - Process delayed effects, clear protection, enemies draw and select intents
2. **Player Turn** - All players simultaneously select and play cards
3. **Enemy Turn** - Enemies execute pre-selected actions, apply status effects
4. **Victory Check** - If all enemies dead → transition to rewards

### 2. Post-Minion Reward

**Scene:** `res://scenes/reward.tscn` with `encounter_type = MINION`

**Rewards offered to each alive player:**
- **HEAL** - Restore 30% of max HP
- **CARD** - Choose one card from reward deck

Players choose privately. When all players have chosen, host can click "Continue" to proceed.

**Next:** Initialize next encounter (boss fight for same boss_index)

### 3. Boss Fight

**Initialization:** `game_manager.initialize_combat_encounter(EncounterType.BOSS_PHASE_1, boss_idx)`

- Sets `current_state = GameState.COMBAT`
- Sets `combat_phase = CombatPhase.BOSS_PHASE_1`
- Loads boss from `boss_db.get_boss(boss_idx)`
- Applies boss-specific start events

**Combat:** Same round structure as minion fights.

**Victory:** When boss HP reaches 0 → `boss_defeated()` → transition to boss rewards

### 4. Post-Boss Reward

**Scene:** `res://scenes/reward.tscn` with `encounter_type = BOSS_PHASE_1`

**Phase 0 - Card/Revive Rewards:**
- If dead players exist: offer REVIVE option
- Offer CARD choices from reward deck

**Phase 1 - Relic Rewards:**
- Each alive player chooses one relic
- Options include character-specific and universal relics

**Next:** `boss_index++`, then:
- If `boss_index < 5`: Initialize minion fight for next boss
- If `boss_index >= 5`: Victory!

---

## Boss Progression

| boss_index | Boss Name | Notes |
|------------|-----------|-------|
| 0 | Giant Moose | First boss |
| 1 | Mr.67 | Second boss |
| 2 | The Doctor | Third boss |
| 3 | TBD | Fourth boss |
| 4 | TBD | Fifth boss (final) |

---

## Key Functions

### Game Manager (`scripts/game_manager.gd`)

| Function | Purpose |
|----------|---------|
| `initialize_combat_encounter(type, boss_idx)` | Set up any encounter type |
| `start_round()` | Begin a new combat round |
| `play_card(caster, card, target)` | Process card effects |
| `player_done()` | Mark player as finished for turn |
| `check_combat_victory()` | Check if enemies/players are dead |
| `transition_to_reward_phase()` | Move from combat to rewards |
| `boss_defeated()` | Handle boss death and transitions |

### Reward (`scripts/reward.gd`)

| Function | Purpose |
|----------|---------|
| `_on_all_rewards_complete()` | Called when all players have chosen |
| `start_relic_reward()` | Begin relic selection phase (boss only) |
| `_on_continue_pressed()` | Host proceeds to next encounter |

---

## Multiplayer Synchronization

- Server (host) controls all state transitions
- RPCs synchronize: player states, enemy states, game state changes
- Each client maintains a local copy of game state
- Scene changes use `NetworkManager.change_scene_synchronized.rpc()`

---

## Combat Victory/Defeat Conditions

**Victory (per encounter):**
- All enemies HP reduced to 0
- Triggers `check_combat_victory()` → reward scene

**Defeat:**
- All players HP reduced to 0
- Triggers `client_combat_defeat()` → defeat scene

**Game Victory:**
- Complete all 5 boss encounters
- `boss_index` reaches 5 after final boss reward

---

## Important Mechanics

1. **Simultaneous Turns** - All players select cards at the same time
2. **Enemy Intents** - Enemies show what they'll do before players act
3. **Shield Reset** - Shield resets at START of round (persists through player turn to block enemy attacks)
4. **Per-Fight Reset** - HP, stamina, shields, and status effects reset between encounters

---

## Related Files

- `scripts/game_manager.gd` - Main game state and flow control
- `scripts/combat.gd` - Combat UI and interactions
- `scripts/reward.gd` - Reward scene logic
- `scripts/rewards/reward_manager.gd` - Modular reward choice handling
- `scripts/data/bosses_data.gd` - Boss definitions
- `scripts/minion_database.gd` - Minion definitions per boss

---

*Last Updated: 2026-01-28*
