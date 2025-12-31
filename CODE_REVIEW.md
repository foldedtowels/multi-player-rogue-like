# Code Review - Deck Masters Roguelike

## Executive Summary

This code review analyzes the Deck Masters Roguelike project, a multiplayer deck-building card game built in Godot 4.5. The project demonstrates solid architecture with clean separation of concerns, but has several critical bugs and areas for improvement.

**Overall Assessment**: 7/10
- Strong game architecture and design patterns
- Good use of Godot 4 features (autoloads, signals, resources)
- Several critical bugs that would prevent the game from running
- Some type safety improvements needed
- UI interaction patterns need refinement

---

## Critical Issues (Must Fix)

### 1. Invalid Method Call in Character Class
**File**: `scripts/character.gd`
**Line**: 112
**Severity**: CRITICAL - Game Breaking

```gdscript
# WRONG - Line 112
func can_afford(current_energy: int) -> bool:
	return current_energy >= energy_cost
```

**Problem**: The `Character` class doesn't have an `energy_cost` property. This method exists in the `Card` class (line 87-88) but is incorrectly called on characters in `game_manager.gd` line 112.

**Fix**:
```gdscript
# In game_manager.gd, line 112
# WRONG:
if not current_boss.can_afford(card.energy_cost):

# CORRECT:
if not card.can_afford(current_boss.current_energy):
```

**Impact**: Boss AI will crash when trying to play cards.

---

### 2. Multi-Hit Loop Error in Game Manager
**File**: `scripts/game_manager.gd`
**Line**: 194
**Severity**: CRITICAL - Logic Error

```gdscript
# WRONG - Line 194
for hit in card.multi_hit:
    var damage_dealt = t.take_damage(card.damage, card.piercing)
```

**Problem**: `for hit in card.multi_hit` treats the integer as an iterable. If `multi_hit = 2`, this tries to iterate over the number 2, not execute twice.

**Fix**:
```gdscript
# CORRECT:
for i in card.multi_hit:
    var damage_dealt = t.take_damage(card.damage, card.piercing)

    # Lifesteal
    if card.lifesteal:
        caster.heal(damage_dealt)
```

**Impact**: Multi-hit cards (Shadow Step, Chain Lightning) will crash or not work correctly.

---

### 3. Duplicate Signal Connections in Combat UI
**File**: `scripts/combat.gd`
**Line**: 128-129
**Severity**: MEDIUM - Memory Leak

```gdscript
# Line 128-129
if display.get_signal_connection_list("gui_input").is_empty():
    display.gui_input.connect(_on_character_clicked.bind(character))
```

**Problem**: This check runs every time `update_character_display()` is called (which happens frequently). The connection persists even if the check passes, leading to:
1. Multiple connections to the same signal
2. Memory leaks
3. Event handlers firing multiple times

**Fix**:
```gdscript
# Option 1: Connect once in creation
func create_character_displays():
    for display in player_displays:
        display.gui_input.connect(_on_character_clicked)

# Option 2: Disconnect then reconnect
func update_character_display(display: Control, character: Character, is_active: bool):
    # ... update display code ...

    # Clear old connection
    if display.gui_input.is_connected(_on_character_clicked):
        display.gui_input.disconnect(_on_character_clicked)

    # Add new connection
    display.gui_input.connect(_on_character_clicked.bind(character))
```

**Impact**: After several turns, clicking a character might trigger the effect multiple times, or cause UI lag.

---

### 4. Resource Duplication Missing in Hero Database
**File**: `scripts/hero_database.gd`
**Lines**: 16-174
**Severity**: HIGH - Game State Corruption

```gdscript
# In hero_database.gd
func get_all_heroes() -> Array[Character]:
    var heroes: Array[Character] = []
    heroes.append(create_flame_wielder())
    heroes.append(create_life_weaver())
    # ...
    return heroes
```

**Problem**:
1. Each call to `create_flame_wielder()` creates a NEW Character with NEW Card instances
2. When the same hero is selected by `game_manager.select_heroes()`, the character's state is shared
3. If a character is damaged/modified in combat, it affects the "template"

**Current Flow**:
```gdscript
# In game_manager.gd, line 38-43
func select_heroes(hero_indices: Array):
	players.clear()
	var all_heroes = hero_db.get_all_heroes()  # Creates fresh heroes

	for idx in hero_indices:
		if idx >= 0 and idx < all_heroes.size():
			players.append(all_heroes[idx])  # Direct append - shares reference!
```

**Fix**:
```gdscript
# Option 1: Create hero templates once in _ready()
var hero_templates: Array[Character] = []

func _ready():
	card_db = get_node("/root/CardDatabase")
	hero_templates.append(create_flame_wielder())
	hero_templates.append(create_life_weaver())
	# ... etc

func get_hero(index: int) -> Character:
	if index >= 0 and index < hero_templates.size():
		return duplicate_hero(hero_templates[index])
	return null

func duplicate_hero(hero: Character) -> Character:
	var new_hero = Character.new()
	new_hero.character_name = hero.character_name
	new_hero.description = hero.description
	new_hero.max_health = hero.max_health
	new_hero.starting_energy = hero.starting_energy

	# Deep copy deck
	for card in hero.starting_deck:
		new_hero.starting_deck.append(card.duplicate())

	return new_hero
```

**Impact**: Characters might start combat with wrong stats, or card modifications persist between games.

---

## High Priority Issues

### 5. Boss Card Creation Called Repeatedly
**File**: `scripts/boss_database.gd`
**Lines**: 342-344, 352-353
**Severity**: MEDIUM - Performance Issue

```gdscript
func get_boss(index: int) -> Character:
	create_boss_cards()  # Called every time!
	match index:
		0: return create_corrupted_treant()
		# ...

func get_all_bosses() -> Array[Character]:
	create_boss_cards()  # Called every time!
	# ...
```

**Problem**: `create_boss_cards()` adds cards to the CardDatabase dictionary every time it's called. This means:
1. Boss cards are recreated multiple times
2. Previous boss card instances are orphaned (minor memory leak)
3. Unnecessary performance overhead

**Fix**:
```gdscript
var boss_cards_created: bool = false

func _ready():
    card_db = get_node("/root/CardDatabase")
    create_boss_cards()
    boss_cards_created = true

func create_boss_cards():
    if boss_cards_created:
        return

    # Create all boss cards...
```

---

### 6. Missing Validation in Card Database
**File**: `scripts/card_database.gd`
**Line**: 441-444
**Severity**: MEDIUM - Null Safety

```gdscript
func get_card(card_id: String) -> Card:
    if all_cards.has(card_id):
        return all_cards[card_id].duplicate()
    return null
```

**Problem**: If a typo or invalid card_id is used, the function silently returns `null`. This could cause crashes later when the card is used.

**Fix**:
```gdscript
func get_card(card_id: String) -> Card:
    if all_cards.has(card_id):
        return all_cards[card_id].duplicate()

    push_error("Card not found: " + card_id)
    return null

# Or create a default "error" card
func get_card(card_id: String) -> Card:
    if all_cards.has(card_id):
        return all_cards[card_id].duplicate()

    push_error("Card not found: %s, returning error card" % card_id)
    var error_card = Card.new()
    error_card.card_name = "ERROR: " + card_id
    error_card.description = "Card not found in database"
    return error_card
```

---

### 7. Character Initialization Called Multiple Times
**File**: `scripts/game_manager.gd`
**Lines**: 61-66
**Severity**: MEDIUM - Logic Issue

```gdscript
func start_boss_encounter():
    # ...
    # Initialize all characters
    for player in players:
        player._init()  # Calling _init() manually is unusual
        player.start_turn()

    current_boss._init()
    current_boss.start_turn()
```

**Problem**:
1. Calling `_init()` manually is non-standard in Godot
2. `_init()` is the constructor, should only be called when creating the object
3. Should use a `reset()` or `initialize()` method instead

**Fix**:
```gdscript
# In character.gd, add a reset method
func reset():
    current_health = max_health
    max_energy = starting_energy
    current_energy = max_energy
    reset_deck()

# In game_manager.gd
func start_boss_encounter():
    # ...
    for player in players:
        player.reset()
        player.start_turn()

    current_boss.reset()
    current_boss.start_turn()
```

---

## Medium Priority Issues

### 8. Inefficient Hand Updates
**File**: `scripts/combat.gd`
**Lines**: 131-147
**Severity**: LOW - Performance

```gdscript
func update_hand():
    clear_hand()  # Destroys all card visuals

    if not current_player:
        return

    for card in current_player.hand:
        var card_visual = card_scene.instantiate()  # Recreates every visual
        # ...
```

**Problem**: Every time the hand updates (after playing a card, drawing, etc.), ALL card visuals are destroyed and recreated. This is inefficient and causes visual flicker.

**Better Approach**:
```gdscript
# Track which cards are displayed
var displayed_cards: Array[Card] = []

func update_hand():
    if not current_player:
        clear_hand()
        return

    var current_cards = current_player.hand

    # Check if hand has actually changed
    if cards_match(displayed_cards, current_cards):
        # Just update playability
        for i in hand_container.get_child_count():
            var card_visual = hand_container.get_child(i)
            var card = current_cards[i]
            card_visual.set_playable(card.can_afford(current_player.current_energy))
        return

    # Hand changed, rebuild
    clear_hand()
    displayed_cards.clear()

    for card in current_cards:
        var card_visual = card_scene.instantiate()
        hand_container.add_child(card_visual)
        card_visual.set_card(card)
        card_visual.set_playable(card.can_afford(current_player.current_energy))
        card_visual.card_clicked.connect(_on_card_clicked)
        displayed_cards.append(card)

func cards_match(a: Array[Card], b: Array[Card]) -> bool:
    if a.size() != b.size():
        return false
    for i in a.size():
        if a[i] != b[i]:
            return false
    return true
```

---

### 9. No Validation for Card Effects
**File**: `scripts/game_manager.gd`
**Lines**: 165-225
**Severity**: MEDIUM - Edge Cases

```gdscript
func apply_card_effects(caster: Character, card: Card, target: Character):
    # Determine targets...

    # Apply effects to all targets
    for t in targets:
        if not t.is_alive():
            continue  # Good! Checks if alive

        # But no check for heal on full health, shield on max, etc.
```

**Improvements**:
```gdscript
func apply_card_effects(caster: Character, card: Card, target: Character):
    # ...

    for t in targets:
        if not t.is_alive():
            continue

        # Damage
        if card.damage > 0:
			for i in card.multi_hit:  # Fixed from 'hit in'
                var damage_dealt = t.take_damage(card.damage, card.piercing)

                # Lifesteal - only if damage was actually dealt
                if card.lifesteal and damage_dealt > 0:
                    caster.heal(damage_dealt)

        # Healing - no need to heal if at full health
        if card.heal_amount > 0 and t.current_health < t.max_health:
            t.heal(card.heal_amount)

        # Shield - always apply (shields can stack)
        if card.shield_amount > 0:
            t.gain_shield(card.shield_amount)

        # Status effects - avoid applying 0 values
        if card.apply_poison > 0:
            t.poison += card.apply_poison
        # ... etc
```

---

### 10. Missing Card Draw Limit
**File**: `scripts/character.gd`
**Lines**: 55-57
**Severity**: LOW - Edge Case

```gdscript
func draw_cards(amount: int):
    for i in amount:
        draw_card()
```

**Problem**: No check if deck AND discard pile are empty. Could draw infinite nulls.

**Fix**:
```gdscript
func draw_cards(amount: int):
    for i in amount:
        var card = draw_card()
        if card == null:
            # No more cards to draw
            break
```

---

### 11. No Check for Dead Players in Turn System
**File**: `scripts/game_manager.gd`
**Lines**: 76-85
**Severity**: LOW - UX Issue

```gdscript
func start_player_turn(player_index: int):
    if player_index >= players.size():
        start_boss_turn()
        return

    current_player_index = player_index
    var player = players[player_index]

    if not player.is_alive():
        end_player_turn()  # Good! Skips dead players
        return

    player.start_turn()
    player_turn_started.emit(player_index)
```

**Improvement**: Add visual feedback when skipping dead players
```gdscript
if not player.is_alive():
    print("Skipping turn for %s (defeated)" % player.character_name)
    # Or emit a signal for UI to show
    player_skipped.emit(player_index)
    end_player_turn()
    return
```

---

## Things Done Well

### 1. Clean Architecture ✅
The project uses a well-organized MVC-like pattern:
- **Models**: `Card`, `Character` resources
- **Controllers**: `GameManager` for logic, databases for data
- **Views**: Scene scripts (`combat.gd`, `character_selection.gd`)

### 2. Proper Use of Autoloads ✅
Autoloads are correctly configured and used:
```gdscript
# project.godot
CardDatabase="*res://scripts/card_database.gd"
GameManager="*res://scripts/game_manager.gd"

# Usage in scripts
var card_db = get_node("/root/CardDatabase")
```

### 3. Strong Signal Architecture ✅
Signals are well-designed and properly emitted:
```gdscript
signal player_turn_started(player_index: int)
signal card_played(character: Character, card: Card, target: Character)
signal combat_ended(victory: bool)
```

### 4. Good Resource Design ✅
Resources use `class_name` and `@export` correctly:
```gdscript
extends Resource
class_name Card

@export var card_name: String
@export var damage: int = 0
```

### 5. Enum Usage for Type Safety ✅
Enums are properly defined and used:
```gdscript
enum CardType {
    ATTACK,
    SPELL,
    BUFF,
    DEBUFF,
    HEAL
}

var card_type: CardType = CardType.ATTACK
```

### 6. Proper Scene Instancing ✅
```gdscript
var card_scene = preload("res://scenes/card_visual.tscn")
var card_visual = card_scene.instantiate()
```

### 7. Good Turn-Based Game Loop ✅
The turn structure is logical and well-implemented:
1. Player turns in sequence
2. Boss turn after all players
3. Status effects applied at start of turn
4. Card draw and energy refresh

### 8. Card Game Mechanics are Solid ✅
- Deck shuffling and recycling
- Discard pile management
- Energy system
- Status effects with decay
- Shield vs permanent HP

---

## Recommendations for Future Development

### 1. Add Input Validation Layer
Create a validation class for all game actions:
```gdscript
class_name GameValidator

static func can_play_card(player: Character, card: Card) -> bool:
    if not player.is_alive():
        return false
    if not card.can_afford(player.current_energy):
        return false
    if player.hand.has(card) == false:
        return false
    return true

static func is_valid_target(card: Card, target: Character) -> bool:
    match card.target_type:
        Card.TargetType.SINGLE_ENEMY:
            return target != null and target.is_alive()
        Card.TargetType.SINGLE_ALLY:
            return target != null and target.is_alive()
    return true
```

### 2. Implement Undo/Replay System
For a card game, being able to review actions is valuable:
```gdscript
class_name GameAction

var action_type: String  # "play_card", "end_turn", etc.
var actor: Character
var card: Card
var target: Character
var timestamp: float

class_name GameHistory

var actions: Array[GameAction] = []

func record_action(action: GameAction):
    actions.append(action)

func get_last_n_actions(n: int) -> Array[GameAction]:
    var start = max(0, actions.size() - n)
    return actions.slice(start)
```

### 3. Add Animation System
Card games benefit greatly from animations:
```gdscript
func play_card_animated(card: Card, target: Character):
    # Animate card moving to target
    var tween = create_tween()
    tween.tween_property(card_visual, "position", target_position, 0.3)
    await tween.finished

    # Apply effects
    apply_card_effects(caster, card, target)

    # Animate damage numbers
    show_damage_popup(target, damage)
```

### 4. Create Card Effect System
Instead of hardcoding effects in `apply_card_effects()`, use a strategy pattern:
```gdscript
class_name CardEffect

func apply(caster: Character, target: Character):
    pass

class_name DamageEffect extends CardEffect

var damage: int
var piercing: bool

func apply(caster: Character, target: Character):
    target.take_damage(damage, piercing)

# Then in Card
var effects: Array[CardEffect] = []
```

### 5. Add Save/Load System
```gdscript
func save_game() -> Dictionary:
    return {
        "players": serialize_characters(players),
        "boss_index": boss_index,
        "round": round_number
    }

func load_game(data: Dictionary):
    players = deserialize_characters(data["players"])
    boss_index = data["boss_index"]
    round_number = data["round"]
```

### 6. Improve AI with Priorities
```gdscript
func select_best_card(boss: Character) -> Card:
    var playable_cards = boss.hand.filter(
        func(c): return c.can_afford(boss.current_energy)
    )

    # Prioritize healing if low HP
    if boss.current_health < boss.max_health * 0.3:
        for card in playable_cards:
            if card.card_type == Card.CardType.HEAL:
                return card

    # Prioritize high damage
    playable_cards.sort_custom(func(a, b): return a.damage > b.damage)
    return playable_cards[0] if playable_cards.size() > 0 else null
```

### 7. Add Unit Tests
```gdscript
# test_character.gd
func test_take_damage():
    var char = Character.new()
    char.current_health = 100
    char.take_damage(30, false)
    assert(char.current_health == 70, "Damage should reduce health")

func test_shield_blocks_damage():
    var char = Character.new()
    char.current_health = 100
    char.shield = 20
    char.take_damage(30, false)
    assert(char.current_health == 90, "Shield should block 20 damage")
    assert(char.shield == 0, "Shield should be depleted")
```

### 8. Add Debug UI
```gdscript
# debug_panel.gd
func _ready():
    if OS.is_debug_build():
        visible = true
    else:
        visible = false

func _on_kill_boss_pressed():
    GameManager.current_boss.current_health = 0

func _on_heal_all_pressed():
    for player in GameManager.players:
        player.current_health = player.max_health

func _on_infinite_energy_toggled(enabled: bool):
    GameManager.infinite_energy = enabled
```

---

## Code Quality Metrics

### Strengths
- **Modularity**: 8/10 - Good separation of concerns
- **Readability**: 8/10 - Clear variable names, logical structure
- **Type Safety**: 6/10 - Some typed arrays, but missing in places
- **Error Handling**: 4/10 - Minimal null checks and validation
- **Performance**: 7/10 - Generally good, some inefficiencies
- **Maintainability**: 7/10 - Easy to understand and modify

### Areas for Improvement
- Add comprehensive null checking
- Implement error handling for edge cases
- Add validation layer for all game actions
- Improve performance in UI update loops
- Add unit tests for core game logic
- Document complex algorithms (like turn sequencing)

---

## Testing Recommendations

### Critical Tests to Perform
1. **Multi-hit cards**: Verify Shadow Step, Chain Lightning work correctly
2. **Boss AI**: Ensure boss can play cards without crashing
3. **Character selection**: Verify heroes maintain independent state
4. **Dead player turns**: Confirm skipping works correctly
5. **Empty deck**: Test drawing when deck and discard are both empty
6. **Signal connections**: Verify no duplicate connections after multiple turns
7. **Resource duplication**: Ensure modifying one card doesn't affect others

### Manual Test Script
```
1. Start game
2. Select 3 heroes
3. Play until one character dies
4. Verify dead character's turn is skipped
5. Play a multi-hit card (Shadow Step)
6. Verify it hits multiple times
7. Play cards until hand is empty
8. End turn and verify new cards are drawn
9. Defeat boss
10. Verify progression to next boss
```

---

## Priority Action Items

### Immediate (Fix Before Release)
1. Fix `can_afford()` call in game_manager.gd line 112
2. Fix multi-hit loop in apply_card_effects()
3. Implement proper hero duplication in hero_database.gd
4. Fix signal connection leak in combat.gd

### Short Term (Next Sprint)
5. Add input validation throughout
6. Improve error messaging for invalid cards
7. Optimize hand update logic
8. Add unit tests for core mechanics

### Long Term (Future Features)
9. Implement animation system
10. Add save/load functionality
11. Create advanced AI with priorities
12. Build card effect plugin system

---

## Conclusion

The Deck Masters Roguelike project demonstrates strong game design and solid architecture. The core concepts are well-implemented, and the code is generally clean and readable. However, there are several critical bugs that must be fixed before the game can run properly.

**Key Takeaways**:
- ✅ Excellent use of Godot 4 features (autoloads, signals, resources)
- ✅ Clean separation of concerns and modular design
- ⚠️ Critical bugs in core game loop (multi-hit, can_afford)
- ⚠️ Resource duplication issues could cause state corruption
- ⚠️ Missing error handling and validation
- 💡 Great foundation for future expansion

**Recommended Next Steps**:
1. Fix the 4 critical issues listed above
2. Run comprehensive testing with all card types
3. Add input validation layer
4. Implement animation system for polish
5. Add save/load for longer play sessions

With these fixes and improvements, this project has the potential to be an excellent deck-building roguelike game!

---

*Review Date: 2025-12-30*
*Reviewer: Code Analysis System*
*Project Version: Initial Release Candidate*
