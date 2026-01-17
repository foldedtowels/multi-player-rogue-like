# Deck Masters - Godot Roguelike Deck Builder

## Project Overview
A multiplayer roguelike deck-building game built in Godot 4, inspired by Slay the Spire. Players take simultaneous turns, selecting cards to play against opponents in real-time combat.

### Core Systems
- **Combat System** (`scripts/combat.gd`) - Turn-based combat with card effects
- **Card System** (`scripts/card.gd`, `scripts/card_visual.gd`) - Card mechanics and rendering
- **Card Database** (`scripts/card_database.gd`) - Loads and manages all cards from GDScript data files
- **Character System** (`scripts/character.gd`) - Player stats, HP, deck management
- **Game Manager** (`scripts/game_manager.gd`) - Multiplayer state, turn synchronization
- **Rewards** (`scripts/reward.gd`, `scripts/rewards/`) - Post-combat rewards and progression

---

## Card System Architecture

Cards are defined in GDScript data files under `scripts/data/cards/`:

```
scripts/data/cards/
    shared_cards.gd     - Tokens and utility cards (Energy, Ember)
    fabio_cards.gd      - Fabio (Warrior) cards
    kevin_cards.gd      - Kevin (Alchemist) cards
    enrique_cards.gd    - Enrique (Cleric) cards
    reward_cards.gd     - Generic rare/common rewards
    minion_cards.gd     - Enemy minion cards

scripts/data/bosses_data.gd  - Boss cards (Giant Moose, Mr.67)
```

### Card Data Format

Cards are dictionaries with properties matching `Card` class:

```gdscript
const CARDS = {
    "spell_fire_smash": {
        "card_name": "Fire Smash",
        "description": "Deal 5 damage. [Fire Spell].",
        "card_type": "ATTACK",
        "target_type": "SINGLE_ENEMY",
        "stamina_cost": 2,
        "damage": 5,
        "element": "FIRE"
    }
}
```

### Adding New Cards

1. Add the card dictionary to the appropriate `*_cards.gd` file
2. Add the card ID to the relevant category list (BASE_DECK, REWARD_CARDS, etc.)
3. Run the game in debug mode - documentation auto-generates to `docs/CARDS_REFERENCE.md`

### CSV Override (Legacy)

CSV loading is disabled by default but can be re-enabled:
```gdscript
# In card_database.gd
var csv_loading_enabled: bool = true  # Enable CSV override
```
When enabled, CSV cards override GDScript definitions (useful for quick balance testing).

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

### 7. Cards are defined in GDScript, not CSV
Card definitions live in `scripts/data/cards/*.gd`. CSV loading is disabled by default but can be enabled for override/testing. See "Card System Architecture" section above.

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

## Running Card Tests

The project has a comprehensive test suite for card mechanics.

### From Command Line

```bash
# Find your Godot executable (example path - yours may differ)
# On this machine: C:\Users\benja\Desktop\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe

# Run all tests headless
cd C:\Users\benja\code\deck-masters-roguelike
"path/to/Godot_console.exe" --headless --script scripts/tests/run_tests.gd
```

### From In-Game Code

```gdscript
var runner = CardTestRunner.new()
add_child(runner)
runner.run_all_tests()        # All tests
runner.run_suite("fabio")     # Single suite: fabio, kevin, enrique, shared, minion, reward, boss
runner.run_quick_tests()      # Fast validation (Fabio + Shared only)
```

### Test File Structure

```
scripts/tests/
├── test_helpers.gd          # Utility functions for test setup
├── card_test_runner.gd      # Main orchestrator (preloads all suites)
├── run_tests.gd             # CLI runner script (extends SceneTree)
└── test_suites/
    ├── fabio_card_tests.gd  # Fabio (Warrior) cards
    ├── kevin_card_tests.gd  # Kevin (Alchemist) cards
    ├── enrique_card_tests.gd# Enrique (Cleric) cards
    ├── shared_card_tests.gd # Shared/token cards
    ├── minion_card_tests.gd # Minion encounter cards
    ├── reward_card_tests.gd # Generic reward cards
    └── boss_card_tests.gd   # Giant Moose & Mr.67 cards
```

### Key Implementation Details

1. **Test suites must be preloaded** in `card_test_runner.gd`:
   ```gdscript
   const FabioTests = preload("res://scripts/tests/test_suites/fabio_card_tests.gd")
   ```
   Godot doesn't auto-discover classes in subdirectories.

2. **Fresh fixtures per test** - each test creates its own characters:
   ```gdscript
   func _test_slash():
       var player = TestHelpers.create_test_player("Fabio", 100, 10)
       var enemy = TestHelpers.create_test_enemy("Target", 100)
       TestHelpers.setup_combat(game_manager, [player], [enemy])
       # ... test code
   ```

3. **CLI runner extends SceneTree**, not Node:
   ```gdscript
   extends SceneTree
   func _init():
       await process_frame  # Wait for autoloads
       # ... run tests
       quit(exit_code)
   ```

4. **apply_card_effects() doesn't deduct resources** - stamina/aura deduction happens in combat system, not in the effect application. Tests should verify card properties, not resource changes.

5. **remove_target_debuffs removes entire debuff type**, not just 1 stack.

### Adding New Card Tests

1. Add test to appropriate suite file in `scripts/tests/test_suites/`
2. Follow the pattern:
   ```gdscript
   func _test_new_card():
       var player = TestHelpers.create_test_player("Test", 100, 10)
       var enemy = TestHelpers.create_test_enemy("Target", 100)
       TestHelpers.setup_combat(game_manager, [player], [enemy])

       var card = card_db.get_card("new_card_id")
       TestHelpers.give_card(player, card)

       game_manager.apply_card_effects(player, player.hand[0], enemy)

       assert_eq(enemy.current_health, expected, "Card does X damage")
   ```
3. Call the test from the suite's `run_all()` function

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

**Last Updated**: 2026-01-16
