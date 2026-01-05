# Deck Masters - Godot Roguelike Deck Builder

## Project Overview
A multiplayer roguelike deck-building game built in Godot 4, inspired by Slay the Spire. Players take simultaneous turns, selecting cards to play against opponents in real-time combat.

### Core Systems
- **Combat System** (`scripts/combat.gd`) - Turn-based combat with card effects
- **Card System** (`scripts/card.gd`, `scripts/card_visual.gd`) - Card mechanics and rendering
- **Character System** (`scripts/character.gd`) - Player stats, HP, deck management
- **Game Manager** (`scripts/game_manager.gd`) - Multiplayer state, turn synchronization
- **Rewards** (`scripts/reward.gd`, `scripts/rewards/`) - Post-combat rewards and progression

### Current Focus
- **Branch**: `feature/multiplayer-simultaneous-turns`
- **Active Work**: Fixing card selection and turn synchronization bugs
- **Known Issues**: Cards not selectable in round 2, queued_cards timing issues

---

## 🔧 WORKFLOW IMPROVEMENT REMINDERS

### Periodic Skills & Hooks Check
**Claude**: At the start of each session, suggest relevant skills or hooks based on recent bugs or patterns:

- If we're debugging multiplayer sync → Suggest a `/multiplayer-debug` skill
- If we're adding new cards → Suggest a `/card-balance` skill
- If we're refactoring signals → Suggest a hook to validate signal connections
- If we're fixing UI issues → Suggest a `/ui-test` skill

**Action Items for Next Review** (update every 2-3 sessions):
- [ ] Create `/multiplayer-debug` skill for common sync issues
- [ ] Create `/card-balance` skill to validate new card stats
- [ ] Add hook to prevent committing with `print()` statements containing "DEBUG" or "FIXME"
- [ ] Create test suite structure in `tests/` directory

---

## 🐛 HARD PROBLEMS LOG

> **Purpose**: Document difficult bugs, root causes, and solutions to prevent regression and speed up future debugging.

### Problem: Cards Not Selectable in Round 2+
**Date**: January 2026
**Symptoms**: After the first round, cards become unselectable. Mouse clicks don't register on cards.

**Root Cause**:
- `queued_cards` array wasn't being cleared at the right time in the turn cycle
- Initial fix cleared it too early (before server could process selections)
- Final fix: Clear `queued_cards` in `_on_game_state_changed()` when transitioning to `SELECTION` state

**Solution**:
```gdscript
# In combat.gd
func _on_game_state_changed(new_state):
    match new_state:
        GameManager.GameState.SELECTION:
            queued_cards.clear()  # Clear here, not in end_turn()
```

**Files Modified**:
- `scripts/combat.gd:712`
- Related commits: `3c329a3`, `6fddcd5`

**Lessons Learned**:
- Don't clear state arrays until you're certain all RPC calls have processed
- State transitions are the safest place to reset per-turn data
- Add debug logging for state transitions when debugging multiplayer sync

---

### Problem: Double Cards for Host
**Date**: January 2026
**Symptoms**: Host player receives duplicate cards during reward selection

**Root Cause**: TBD - still investigating

**Solution**: TBD

**Files Modified**: TBD

**Lessons Learned**: TBD

---

### Problem: Multiplayer Sync Chaos - Multiple Critical Issues
**Date**: January 2026
**Symptoms**:
- Pyra (host/player 0) receives 10 cards instead of 5 at turn start
- Round numbers jump randomly: 1 → 3 → 1 → 3 → 5 (not incrementing properly)
- `apply_hand_dict()` called 20+ times per round for each character (massive sync spam)
- Round separator banners print 4x (once per server + 3 clients)
- Other players (Nyx, Selene) correctly receive 5 cards

**Root Cause**:
- **Double cards**: After Pyra draws 5 cards at `start_turn()`, `apply_hand_dict()` is called with **10 cards** worth of data (incoming data size: 10)
- This happens during or after the enemy turn, suggesting cards are being sent/synced at the wrong time
- **Round number**: `round_number` variable not incrementing at end of `start_enemy_turn_phase()` - investigate line 676-688 in game_manager.gd
- **Sync spam**: `apply_hand_dict()` being called excessively from multiple sources (RPC broadcasts happening too frequently)
- **Banner spam**: Round separator print statements in both server (`start_round()`) and client RPC handlers (`client_selection_phase_started()`)

**Evidence from Logs**:
```
[Character] Pyra start_turn - hand size BEFORE drawing: 0
[Character] Pyra draw_cards done - hand after: 5
[GameManager] send_hand_to_owner - hand size BEFORE get_hand_dict: 5  ✓ Correct
[Character] Pyra apply_hand_dict - incoming data size: 10  ❌ WRONG - doubled!
[Character] Pyra apply_hand_dict - hand size AFTER: 10

[During enemy turn]
[Character] Pyra apply_hand_dict - hand size BEFORE clear: 0 incoming data size: 5  ❌ Getting cards during enemy turn!
```

**Solution**: TBD - Need to investigate:
1. Where is the extra `apply_hand_dict` call coming from during enemy turn?
2. Why is `round_number` not incrementing?
3. Where is `apply_hand_dict` being called excessively?
4. Remove duplicate round banner prints from client-side RPC handlers

**Files to Investigate**:
- `scripts/game_manager.gd:676-688` (round_number incrementing)
- `scripts/game_manager.gd:235-240` (apply_hand_dict calls in send_hand_to_owner)
- `scripts/game_manager.gd:442` (client_selection_phase_started - duplicate banner)
- `scripts/game_manager.gd:700` (client_enemy_turn_phase_started - duplicate banner)
- `scripts/game_manager.gd:819` (send_hand_to_owner in play_card - might be syncing at wrong time)

**Lessons Learned**:
- Multiplayer sync issues cascade - one bad RPC call can trigger dozens of state updates
- Round separator debugging helped identify the turn flow chaos (good use of debug banners!)
- Host player (server + client) has different sync behavior than pure clients
- Need to carefully audit when `send_hand_to_owner` is called - it should ONLY be at turn start and turn end

**Status**: INVESTIGATING

---

### Problem: Card Display Crash - Locked Object Can't Be Freed
**Date**: January 2026
**Symptoms**: Game crashes during ACTION phase with error: "Object is locked and can't be freed"

**Root Cause**:
- Error occurs in `card_hand_display.gd:114` in `_show_queued_cards()` function
- Attempting to free/delete a UI object while it's "locked" (during signal emission or active function call)
- This is a Godot-specific threading/lifecycle issue - objects can't be freed while they're in use

**Error Message**:
```
card_hand_display.gd:114 @ _show_queued_cards(): Object is locked and can't be freed.
CardHandDisplay._show_queued_cards: Attempted to free a locked object (calling or emitting).
```

**Solution**:
```gdscript
# In card_hand_display.gd:114
# WRONG - causes crash when object is locked
child.free()

# CORRECT - defers deletion until safe
child.queue_free()
```

Changed line 114 from `child.free()` to `child.queue_free()`. The `free()` method tries to immediately delete the object, but if it's currently involved in signal emission or animation, Godot locks it and the delete fails. `queue_free()` defers the deletion until the next frame when it's safe.

**Files Modified**:
- `scripts/ui/card_hand_display.gd:114`

**Lessons Learned**:
- **CRITICAL PATTERN**: In Godot, ALWAYS use `queue_free()` instead of `free()` when deleting nodes
- Objects are "locked" during signal emission, animation, or active function calls
- This is especially common during phase transitions when animations are running
- Search for `\.free\(\)` in codebase periodically to catch this pattern
- The comment "use free() for immediate removal" was misleading - immediate removal is exactly what causes the crash

**Status**: FIXED - Changed free() to queue_free()

---

### Template for New Problems
```markdown
### Problem: [Brief Description]
**Date**: [Month Year]
**Symptoms**: [What the user observes]

**Root Cause**:
[Technical explanation of why this happened]

**Solution**:
[Code snippet or approach that fixed it]

**Files Modified**:
[List of files with line numbers]

**Lessons Learned**:
[Patterns to watch for, preventive measures]
```

---

## ✅ TESTING GUIDELINES

### When to Add Tests
**ALWAYS** add tests when:
- Adding a new card effect or mechanic
- Modifying combat state machine logic
- Changing multiplayer synchronization code
- Fixing a bug (write the test that would have caught it)

**FREQUENTLY** add tests when:
- Adding new character abilities
- Modifying reward logic
- Changing UI state management

### Test Structure
```
tests/
├── run_tests.gd          # Test runner (to be created)
├── unit/
│   ├── test_card.gd      # Card mechanics
│   ├── test_combat.gd    # Combat logic
│   └── test_character.gd # Character stats
└── integration/
    ├── test_multiplayer_sync.gd
    └── test_combat_flow.gd
```

### Test Checklist for New Features
Before marking a feature complete:
- [ ] Unit tests for core logic
- [ ] Integration test for multiplayer sync (if applicable)
- [ ] Manual playtest with 2+ players (if multiplayer)
- [ ] Edge case testing (empty deck, 0 HP, etc.)

### Running Tests
```bash
# Once test suite is set up:
godot --headless --script tests/run_tests.gd

# Tests will also run automatically after edits via hooks
```

---

## 🪲 DEBUG PRINT GUIDELINES

### Keeping Debug Output Clean

**PROBLEM**: Too many debug prints make it impossible to find relevant information during testing.

**RULES**:
1. **Remove debug prints after fixing the bug** - Don't leave them "just in case"
2. **Use consistent prefixes** for easy filtering:
   - `[COMBAT]` for combat.gd
   - `[CARD]` for card.gd
   - `[SYNC]` for multiplayer sync
   - `[STATE]` for state changes
3. **Temporary debugging** - Use `# DEBUG:` comment for prints you plan to remove
4. **Permanent logging** - Only keep prints for critical errors or state transitions
5. **Visual separators for turns** - Use banner lines to mark turn boundaries

### Turn Separator Format
**REQUIRED**: When logging turn starts, use visual separators to make console output scannable:

```gdscript
# At the start of each round
print("\n##################### ROUND ", current_round, " - FRIENDLY TURN #####################")

# When switching to enemy turn
print("\n##################### ROUND ", current_round, " - ENEMY (", enemy_name, ") TURN #####################")

# For multiple enemies
print("\n##################### ROUND ", current_round, " - ENEMY (", enemy1, ", ", enemy2, ") TURN #####################")
```

**Examples**:
```
##################### ROUND 1 - FRIENDLY TURN #####################
[COMBAT] Drawing 5 cards for player
[CARD] Card selected: Strike
[COMBAT] queued_cards: [Strike]

##################### ROUND 1 - ENEMY (Goblin) TURN #####################
[COMBAT] Enemy playing: Attack for 6 damage
[STATE] Player HP: 94/100

##################### ROUND 2 - FRIENDLY TURN #####################
[COMBAT] Drawing 5 cards for player
```

This makes it **instantly clear** when looking at console output:
- What round we're in
- Whose turn it is
- Where to look for specific events

**GOOD DEBUG PRINT**:
```gdscript
# DEBUG: Remove after fixing card selection
print("[COMBAT] queued_cards state: ", queued_cards, " | can_select: ", can_select_cards)
```

**BAD DEBUG PRINT**:
```gdscript
print("here")
print("test123")
print(some_variable)
```

### Debug Print Cleanup Checklist
Before committing or ending a session:
- [ ] Search for `# DEBUG:` comments and remove related prints
- [ ] Search for generic `print("` without prefixes and remove/improve them
- [ ] Verify only essential prints remain (errors, warnings, state changes, turn separators)
- [ ] Verify turn separators are in place for round/turn transitions
- [ ] Test that the remaining prints don't spam the console

**Claude**:
- When you add debug prints during bug investigation, mark them with `# DEBUG:` and remove them before marking the task complete
- **ALWAYS** add turn separator banners when debugging combat flow or multiplayer sync issues
- When the user provides console output, the turn separators will help you identify timing issues quickly

---

## 📋 SESSION WORKFLOW

### Start of Session
1. Review git status and recent commits
2. Check "Hard Problems Log" for context on recent bugs
3. Ask about current priorities or blockers
4. Suggest relevant skills/hooks based on the task

### During Development
1. **Add tests first** when implementing new features
2. **Use debug prints sparingly** with proper prefixes
3. **Add turn separators** when debugging combat/multiplayer
4. **Update Hard Problems Log** when solving difficult bugs
5. **Respect hooks** - if a file edit is blocked, confirm it's necessary

### End of Session
1. Clean up debug prints (check for `# DEBUG:` comments)
2. **Keep turn separator prints** - these are permanent for easier debugging
3. Ensure tests pass (if test suite exists)
4. Update Hard Problems Log with any new insights
5. Suggest workflow improvements for next session

---

## 🎯 CURRENT PRIORITIES

### Critical Bugs (Game-Breaking)
1. 🔴 **Pyra Double Cards** - Host receives 10 cards instead of 5, game unbalanced (INVESTIGATING)
2. 🟡 **Round Number Broken** - Jumps randomly 1→3→1→3→5, confusing but not breaking (TODO)

### Performance Issues
3. 🟡 **apply_hand_dict Spam** - Called 20+ times per round, floods logs (TODO)
4. 🟢 **HeroDatabase Spam** - Builds all decks repeatedly during char selection (TODO)

### Completed This Session
- ✅ **Round Banner Spam** - Fixed duplicate prints (was printing 4x, now prints once)
- ✅ **Card Display Crash** - Fixed `card_hand_display.gd:114` by changing `free()` to `queue_free()`

### Other Known Issues
- ❌ **Wizard/Buff Scene** - Needs debugging info
- ❌ **Test Suite** - No automated tests yet

### Upcoming Features
- Buff selection system (files created: `scenes/buff_selection.tscn`, `scripts/buff_selection.gd`)
- More card effects and synergies
- Character progression system

---

## 🤖 CLAUDE-SPECIFIC NOTES

### Critical Files (Protected by Hooks)
The following files are protected by pre-edit hooks due to previous bugs:
- `scripts/game_manager.gd` - Core multiplayer state
- `scripts/combat.gd` - Combat state machine
- `scripts/character.gd` - Player stats
- `scripts/card.gd` - Card mechanics
- `project.godot` - Project configuration

If you need to edit these files, you'll be prompted to confirm. Make sure the change is well-tested.

### Multiplayer Debugging Tips
- Always consider timing - RPC calls aren't instant
- State transitions happen on all clients - use them for synchronization points
- `queued_cards` and similar client-side state should reset during state changes, not during RPCs
- Add `[SYNC]` debug prints when investigating multiplayer issues
- **Use turn separator banners** to make console output readable when debugging multiplayer timing

### Code Style Preferences
- Use explicit type hints where possible: `var cards: Array[Card] = []`
- Signal connections should use string names for clarity: `connect("signal_name", callable)`
- Prefer match statements over if/elif chains for state handling
- Keep functions under 50 lines when possible
- **CRITICAL**: Always use `queue_free()` instead of `free()` for node deletion (see Card Display Crash in Hard Problems Log)

### State Management Between Encounters
**CRITICAL**: Use the correct reset function to avoid losing earned cards!

Two different reset functions:
1. **`reset_players_between_encounters()`** - Use when transitioning minions→boss or boss→next boss
   - Clears: hands, discard, exhaust, queued_cards, shield, energy, debuffs
   - **KEEPS**: `deck` (includes earned cards from rewards!), permanent buffs (strength, armor)
   - **Shuffles**: existing deck

2. **`reset_players_for_new_run()`** - Use ONLY when starting a brand new run
   - Clears: everything
   - **RESETS**: `deck = starting_deck.duplicate()` (loses all earned cards!)

**Common mistake**: Using `reset_players_for_new_run()` between encounters → players lose all earned cards!

---

## 📚 HELPFUL RESOURCES

### Godot Multiplayer
- [Godot High-Level Multiplayer Docs](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)
- Key concept: `@rpc()` calls execute on remote peers, not locally (unless configured otherwise)

### Slay the Spire Research
- See `docs/SLAY_THE_SPIRE_RESEARCH.md` for card balance and mechanics inspiration

---

**Last Updated**: 2026-01-05
**Next Review**: After 2-3 more sessions or when a new major bug is solved
