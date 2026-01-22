# Reward System Overhaul & Player Death Handling

## Summary
Implement differentiated reward screens for minion vs boss fights, add player death handling, and integrate relic rewards.

---

## Requirements Recap

### Minion Fight Rewards (Individual Choice)
- Each **living** player chooses ONE:
  - Heal 30% of max HP (self only)
  - Choose 1 of 3 cards from reward deck

### Boss Fight Rewards (Individual Choice)
- Each **living** player chooses ONE:
  - Revive all dead teammates at FULL HP
  - Choose 1 of 3 cards from reward deck
- THEN each player chooses 1 of 3 relics (character-specific + universal pool)

### Player Death Handling
- Dead players: don't draw cards (already done), don't use passives, don't play cards
- If player dies mid-turn, their queued cards FIZZLE
- Dead players spectate with grayed-out UI
- All 3 dead = defeat screen

---

## Implementation Plan

### Phase 1: Foundation Changes

**File: `scripts/game_constants.gd`**
- Add `MINION_REWARD_HEAL_PERCENTAGE = 0.30`
- Add `REWARD_RELIC_CHOICES = 3`

**File: `scripts/game_manager.gd`**
- Add `var last_completed_encounter: EncounterType` to track what just ended
- Set this in `check_combat_victory()` before transitioning to rewards

**File: `scripts/rewards/reward_choice.gd`**
- Add `var relic_id: String = ""` property
- Implement `ChoiceType.RELIC` case in `apply_to_player()`:
  - Call `player.add_relic(relic_id)` and `RelicRegistry.apply_on_pickup()`
- Add `buff_type == "revive_all"` handling in BUFF case:
  - Loop through all players, set dead players to `max_health`
- Update `serialize()` and `deserialize()` for relic_id

---

### Phase 2: Player Death Handling

**File: `scripts/game_manager.gd`**

1. **Prevent dead players from acting** - Update `player_done()`:
   ```gdscript
   if not players[my_index].is_alive():
       return
   ```

2. **Auto-mark dead players done** - In `start_round()`:
   ```gdscript
   if not player.is_alive():
       players_done_acting[i] = true
   ```

3. **Block card plays from dead players** - In `_server_play_card()`:
   ```gdscript
   if not caster.is_alive():
       print("[COMBAT] Blocked - caster is dead")
       return
   ```

4. **Fizzle queued cards on death** - Add `_fizzle_queued_cards(player_index)`:
   - Clear `queued_cards[player_index]`
   - RPC broadcast to clients
   - Call this after damage is applied if player dies

**File: `scripts/combat.gd`**

5. **Block passive abilities** - In `_on_passive_pressed()`:
   ```gdscript
   if not my_character.is_alive():
       return
   ```

6. **Gray out dead player UI** - In `update_button_states()`:
   ```gdscript
   if not my_character.is_alive():
       phase_label.text = "DEFEATED"
       ready_button.visible = false
       # etc...
       return
   ```

---

### Phase 3: Defeat Screen

**New File: `scenes/defeat.tscn`**
- Simple Control scene with defeat message and "Return to Menu" button

**New File: `scripts/defeat.gd`**
- Display "DEFEAT - Your party has fallen..."
- "Return to Main Menu" button calls `game_manager.start_new_game()` and changes scene

**File: `scripts/game_manager.gd`**
- Update `client_combat_defeat()` to transition to `defeat.tscn` after 2 second delay

---

### Phase 4: Reward Scene Overhaul

**File: `scripts/reward.gd`**

Replace current two-phase (rare/common) flow with encounter-aware flow:

```
_ready():
    Check game_manager.last_completed_encounter
    If MINION → start_minion_reward()
    If BOSS → start_boss_reward()

start_minion_reward():
    Generate choices: [Heal 30%] + [3 cards]
    Show private rewards to each living player
    On complete → show Continue button

start_boss_reward():
    Phase A: Generate choices: [Revive all (if any dead)] + [3 cards]
    Show private rewards
    On complete → start_relic_reward()

start_relic_reward():
    Phase B: Generate 3 relics per player (character + universal pool)
    Filter out already-owned relics
    Show private rewards
    On complete → show Continue button
```

**Key helper functions:**
- `_generate_minion_choices()` - Heal + 3 cards per living player
- `_generate_boss_card_choices()` - Revive (if applicable) + 3 cards per living player
- `_generate_relic_choices()` - 3 relics per living player from appropriate pools
- `_any_players_dead()` - Check if revive option should appear
- `_get_available_relics_for_player(player)` - Get character + universal relics, filter owned

**File: `scripts/rewards/reward_display_panel.gd`**
- Add `_create_relic_visual(choice, index)` for gold-bordered relic buttons

---

## Critical Files to Modify

| File | Changes |
|------|---------|
| `scripts/game_constants.gd` | Add 2 new constants |
| `scripts/game_manager.gd` | Encounter tracking, death guards, fizzle logic, defeat transition, route minions to reward.tscn |
| `scripts/combat.gd` | Dead player UI, passive blocking |
| `scripts/reward.gd` | Major rewrite for minion/boss differentiation + relic phase |
| `scripts/rewards/reward_choice.gd` | Add relic + revive support |
| `scripts/rewards/reward_display_panel.gd` | Add relic visual |

## New Files to Create

| File | Purpose |
|------|---------|
| `scenes/defeat.tscn` | Defeat screen scene |
| `scripts/defeat.gd` | Defeat screen logic |

## Scene Consolidation
- **One modular scene** (`reward.tscn`) will handle both minion and boss rewards
- `buff_selection.tscn` will no longer be used for post-minion rewards
- The existing reusable components (RewardManager, RewardChoice, RewardDisplayPanel) make this clean
- `game_manager.gd` will be updated to route minion victories to `reward.tscn` instead of `buff_selection.tscn`

---

## Testing Plan

1. **Minion rewards**: Win minion fight, verify heal/card choices (no rare phase)
2. **Minion heal**: Verify heal is exactly 30% of max HP
3. **Boss rewards**: Win boss fight, verify revive/card choices
4. **Revive option**: Only appears if at least one teammate is dead
5. **Relic phase**: Appears after card/revive choice, shows 3 relics
6. **Relic filtering**: Character gets their relics + universal, no duplicates
7. **Dead player blocking**: Dead player cannot play cards, use passive, or click End Turn
8. **Card fizzle**: Play cards, die before resolution, verify cards cancelled
9. **Dead UI**: Dead player sees "DEFEATED" and grayed controls
10. **TPK**: Kill all 3 players, verify defeat screen appears
11. **Multiplayer**: Test all above with 3 players connected

---

## Edge Cases

- **Multiple revive choices**: If two players both choose revive, it's idempotent (full HP = full HP)
- **No dead teammates**: Revive option simply doesn't appear in boss rewards
- **All relics owned**: Unlikely, but handle empty relic pool gracefully
- **Death during rewards**: Guard in `_ready()` to check for TPK and skip to defeat
- **Host vs client timing**: All transitions use `NetworkManager.change_scene_synchronized.rpc()`
