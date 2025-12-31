# Godot 4 Errors Guide for Card Game Development

This guide documents common Godot 4 errors encountered in deck-building roguelike projects, with a focus on type safety, UI best practices, and resource management. It incorporates lessons from this project and provides actionable solutions.

## Table of Contents
1. [Type Safety Issues](#type-safety-issues)
2. [StyleBoxFlat Properties](#styleboxflat-properties)
3. [Signal Connection Patterns](#signal-connection-patterns)
4. [Node Initialization](#node-initialization)
5. [Resource Management](#resource-management)
6. [Array and Collection Management](#array-and-collection-management)
7. [UI Best Practices](#ui-best-practices)
8. [Card Game Specific Patterns](#card-game-specific-patterns)
9. [Common Pitfalls](#common-pitfalls)
10. [Quick Reference Checklist](#quick-reference-checklist)

---

## Type Safety Issues

### Problem: Typed Arrays vs Untyped Arrays

Godot 4 requires explicit type declarations for typed arrays. The syntax differs from Godot 3.

#### WRONG: Missing Type Specification
```gdscript
# This creates an untyped Array, not Array[Card]
var deck: Array[Card] = []
deck.append(Card.new())  # Might work
deck.append("string")    # ERROR: Type mismatch at runtime!
```

#### WRONG: Incorrect Syntax
```gdscript
# Godot 3 syntax - doesn't work in Godot 4
var cards = Array[Card]()  # SYNTAX ERROR
```

#### CORRECT: Proper Typed Array Declaration
```gdscript
# Godot 4 typed array syntax
var deck: Array[Card] = []
var hand: Array[Card] = []
var discard_pile: Array[Card] = []

# For function returns
func get_all_cards() -> Array[Card]:
    var cards: Array[Card] = []
    cards.append(card1)
    cards.append(card2)
    return cards

# For function parameters
func add_cards_to_deck(cards: Array[Card]):
    for card in cards:
        deck.append(card)
```

#### CORRECT: Array Operations with Typed Arrays
```gdscript
# Duplicating typed arrays
var original: Array[Card] = [card1, card2, card3]
var copy: Array[Card] = original.duplicate()  # Works!

# Filtering typed arrays
var alive_players: Array[Character] = []
for player in all_players:
    if player.is_alive():
        alive_players.append(player)

# Or using filter (returns Array, not Array[Character])
var alive = all_players.filter(func(p): return p.is_alive())
# Need to cast or re-type if you want Array[Character]
```

### Problem: Generic Dictionaries

Godot 4 doesn't support typed Dictionaries like `Dictionary[String, Card]`.

#### WRONG: Attempting Typed Dictionary
```gdscript
var cards: Dictionary[String, Card] = {}  # ERROR: Not supported
```

#### CORRECT: Use Untyped Dictionary with Comments
```gdscript
# Dictionary mapping String -> Card
var all_cards: Dictionary = {}

func get_card(card_id: String) -> Card:
    if all_cards.has(card_id):
        return all_cards[card_id] as Card  # Cast for type safety
    return null
```

### Best Practices for Type Safety

1. **Always use typed arrays for game objects**: `Array[Card]`, `Array[Character]`, `Array[Button]`
2. **Use type hints on function parameters and returns**: Helps catch errors at edit time
3. **Use `as` for type casting when retrieving from dictionaries**: Ensures type safety
4. **Avoid mixing types in arrays**: Use separate arrays for different types

---

## StyleBoxFlat Properties

### Problem: `border_width_all` is Deprecated

In Godot 4, `StyleBoxFlat.border_width_all` has been removed. You must set individual border widths.

#### WRONG: Using Deprecated Property
```gdscript
var style = StyleBoxFlat.new()
style.border_width_all = 2  # ERROR: Property doesn't exist in Godot 4
style.border_color = Color.WHITE
```

#### CORRECT: Set Individual Border Widths
```gdscript
var style = StyleBoxFlat.new()
style.border_width_left = 2
style.border_width_right = 2
style.border_width_top = 2
style.border_width_bottom = 2
style.border_color = Color.WHITE
```

#### BEST PRACTICE: Create Helper Function
```gdscript
func create_bordered_style(bg_color: Color, border_color: Color, border_width: int = 2) -> StyleBoxFlat:
    var style = StyleBoxFlat.new()
    style.bg_color = bg_color
    style.border_color = border_color
    style.border_width_left = border_width
    style.border_width_right = border_width
    style.border_width_top = border_width
    style.border_width_bottom = border_width
    return style

# Usage
var card_style = create_bordered_style(Color.RED, Color.WHITE, 3)
card_bg.add_theme_stylebox_override("panel", card_style)
```

### StyleBoxFlat Common Properties

```gdscript
var style = StyleBoxFlat.new()

# Background
style.bg_color = Color(0.2, 0.2, 0.2)

# Borders
style.border_color = Color.WHITE
style.border_width_left = 2
style.border_width_right = 2
style.border_width_top = 2
style.border_width_bottom = 2

# Corner radius (rounded corners)
style.corner_radius_top_left = 5
style.corner_radius_top_right = 5
style.corner_radius_bottom_left = 5
style.corner_radius_bottom_right = 5

# Padding/margins
style.content_margin_left = 10
style.content_margin_right = 10
style.content_margin_top = 5
style.content_margin_bottom = 5

# Shadow (draw_center must be true for shadows)
style.shadow_color = Color(0, 0, 0, 0.5)
style.shadow_size = 4
style.shadow_offset = Vector2(2, 2)
```

---

## Signal Connection Patterns

### Problem: Signal Connection Best Practices

Godot 4 uses `connect()` method with lambda functions or method references.

#### WRONG: Godot 3 Style (No Longer Supported)
```gdscript
# Old Godot 3 syntax
button.connect("pressed", self, "_on_button_pressed")  # ERROR in Godot 4
```

#### CORRECT: Godot 4 Signal Connection
```gdscript
# Method 1: Direct method reference
func _ready():
    button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
    print("Button pressed!")

# Method 2: Lambda function
func _ready():
    button.pressed.connect(func(): print("Button pressed!"))

# Method 3: With parameters via bind()
func _ready():
    button.pressed.connect(_on_hero_selected.bind(0))

func _on_hero_selected(index: int):
    print("Selected hero: ", index)
```

#### CORRECT: Connecting Custom Signals
```gdscript
# In card_visual.gd
signal card_clicked(card: Card)
signal card_hovered(card: Card)

func _ready():
    gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent):
    if event is InputEventMouseButton and event.pressed:
        card_clicked.emit(card_data)  # Emit with parameter

# In parent script
func create_card_visual(card: Card):
    var card_visual = card_scene.instantiate()
    card_visual.card_clicked.connect(_on_card_clicked)
    return card_visual

func _on_card_clicked(card: Card):
    print("Card clicked: ", card.card_name)
```

#### BEST PRACTICE: Check for Existing Connections
```gdscript
# Avoid connecting the same signal multiple times
func setup_button(button: Button):
    if button.pressed.get_connections().is_empty():
        button.pressed.connect(_on_button_pressed)

    # Or disconnect first
    if button.pressed.is_connected(_on_button_pressed):
        button.pressed.disconnect(_on_button_pressed)
    button.pressed.connect(_on_button_pressed)
```

### Signal Connection Memory Management

```gdscript
# Signals are automatically disconnected when nodes are freed
# But for manual cleanup:

func _exit_tree():
    if button and button.pressed.is_connected(_on_button_pressed):
        button.pressed.disconnect(_on_button_pressed)
```

---

## Node Initialization

### Problem: Accessing Nodes Before They're Ready

#### WRONG: Using @onready for Dynamically Created Nodes
```gdscript
# This only works for nodes in the scene tree at load time
@onready var my_button: Button = $VBoxContainer/MyButton

func create_new_button():
    var button = Button.new()
    # Can't use @onready for this!
```

#### CORRECT: Store References as Member Variables
```gdscript
# For scene nodes
@onready var hero_container: HBoxContainer = $VBoxContainer/HeroContainer

# For dynamically created nodes
var hero_buttons: Array[Button] = []
var card_visuals: Array[Control] = []

func create_hero_buttons():
    for i in 6:
        var button = Button.new()
        button.text = "Hero %d" % i
        button.pressed.connect(_on_hero_selected.bind(i))
        hero_container.add_child(button)
        hero_buttons.append(button)  # Store reference
```

### Initialization Order

#### CRITICAL: Call Functions in Correct Order

```gdscript
func _ready():
    # 1. Get autoload references
    game_manager = get_node("/root/GameManager")
    card_db = get_node("/root/CardDatabase")

    # 2. Initialize data structures
    players.clear()
    deck.shuffle()

    # 3. Create UI elements (containers, panels)
    _create_ui_containers()

    # 4. Populate UI with data
    _create_hero_buttons()

    # 5. Connect signals
    _connect_signals()

    # 6. Initial update/refresh
    _update_display()
```

#### WRONG: Using Data Before It's Ready
```gdscript
func _ready():
    update_hero_buttons()  # ERROR: buttons don't exist yet!
    create_hero_buttons()  # Creates buttons - TOO LATE
```

#### CORRECT: Create Then Update
```gdscript
func _ready():
    create_hero_buttons()  # Create first
    update_hero_buttons()  # Then update
```

---

## Resource Management

### Problem: Resource Duplication and References

#### Understanding Resource Behavior

Resources (like `Card`, `Character`) are **reference types**. Multiple variables can point to the same resource.

#### WRONG: Shared Resource Problem
```gdscript
# In CardDatabase
var lightning_bolt = Card.new()
lightning_bolt.card_name = "Lightning Bolt"
lightning_bolt.damage = 12

func get_card(id: String) -> Card:
    return all_cards[id]  # Returns reference to same object!

# In game
var card1 = card_db.get_card("lightning_bolt")
var card2 = card_db.get_card("lightning_bolt")
card1.damage = 99  # BUG: Also changes card2.damage!
```

#### CORRECT: Duplicate Resources When Needed
```gdscript
# In CardDatabase
func get_card(card_id: String) -> Card:
    if all_cards.has(card_id):
        return all_cards[card_id].duplicate()  # Create copy
    return null

# Now each card is independent
var card1 = card_db.get_card("lightning_bolt")
var card2 = card_db.get_card("lightning_bolt")
card1.damage = 99  # Only affects card1
```

### Custom Resource Classes

```gdscript
# card.gd
extends Resource
class_name Card

@export var card_name: String
@export var damage: int = 0

# character.gd
extends Resource
class_name Character

@export var character_name: String
@export var max_health: int = 100
@export var starting_deck: Array[Card] = []

# IMPORTANT: When duplicating, arrays need deep copy
func duplicate_character() -> Character:
    var new_char = Character.new()
    new_char.character_name = character_name
    new_char.max_health = max_health

    # Deep copy the deck
    for card in starting_deck:
        new_char.starting_deck.append(card.duplicate())

    return new_char
```

### Memory Management for Dynamic Nodes

```gdscript
# Creating cards in hand
var card_visuals: Array[Control] = []

func update_hand():
    # Clear old cards
    for card_visual in card_visuals:
        card_visual.queue_free()  # Properly free memory
    card_visuals.clear()

    # Create new cards
    for card in player.hand:
        var card_visual = card_scene.instantiate()
        card_visual.set_card(card.duplicate())  # Duplicate if needed
        hand_container.add_child(card_visual)
        card_visuals.append(card_visual)
```

---

## Array and Collection Management

### Problem: Array Operations with Game State

#### Removing Items During Iteration (DANGEROUS)

```gdscript
# WRONG: Modifying array during iteration
for card in hand:
    if card.energy_cost > current_energy:
        hand.erase(card)  # BUG: Skips elements!

# CORRECT: Iterate backwards or use new array
for i in range(hand.size() - 1, -1, -1):
    if hand[i].energy_cost > current_energy:
        hand.remove_at(i)

# OR: Create new array
var playable_cards: Array[Card] = []
for card in hand:
    if card.energy_cost <= current_energy:
        playable_cards.append(card)
hand = playable_cards
```

#### Array Methods for Card Games

```gdscript
# Shuffling deck
deck.shuffle()  # Randomizes order

# Drawing cards
var card = deck.pop_front()  # Remove and return first element
hand.append(card)

# Discarding cards
hand.erase(card)  # Remove specific card (first occurrence)
discard_pile.append(card)

# Checking if card exists
if hand.has(card):
    print("Card in hand")

# Finding card by property
var found_card = hand.filter(func(c): return c.card_name == "Fireball")

# Getting card count
var hand_size = hand.size()

# Clearing array
hand.clear()
```

#### Deck Shuffling and Recycling Pattern

```gdscript
func draw_card() -> Card:
    # If deck is empty, shuffle discard pile back in
    if deck.is_empty():
        if discard_pile.is_empty():
            return null  # No cards left

        # Recycle discard pile into deck
        deck = discard_pile.duplicate()
        discard_pile.clear()
        deck.shuffle()

    var card = deck.pop_front()
    hand.append(card)
    return card
```

---

## UI Best Practices

### Container Layouts for Card Games

#### Hand Display with HBoxContainer

```gdscript
# Scene structure
# HandPanel (Panel)
#   └─ HandContainer (HBoxContainer)
#       ├─ CardVisual1
#       ├─ CardVisual2
#       └─ CardVisual3

# HBoxContainer automatically arranges children horizontally
@onready var hand_container: HBoxContainer = $HandPanel/HandContainer

func display_hand():
    # Clear existing cards
    for child in hand_container.get_children():
        child.queue_free()

    # Add cards
    for card in player.hand:
        var card_visual = card_scene.instantiate()
        card_visual.set_card(card)
        hand_container.add_child(card_visual)
        # HBoxContainer handles positioning automatically!
```

#### Character Display Grid with GridContainer

```gdscript
# For 3 players in a row
@onready var player_grid: GridContainer = $PlayerGrid

func _ready():
    player_grid.columns = 3  # 3 players per row

    for player in players:
        var display = player_display_scene.instantiate()
        display.set_character(player)
        player_grid.add_child(display)
```

### Custom Minimum Sizes

```gdscript
# For card visuals
func _ready():
    custom_minimum_size = Vector2(200, 300)  # Card dimensions

# For buttons
button.custom_minimum_size = Vector2(250, 120)  # Wide button
```

### Theme Overrides for Dynamic Styling

```gdscript
# Override panel style
var style = StyleBoxFlat.new()
style.bg_color = Color.RED
panel.add_theme_stylebox_override("panel", style)

# Override label color
label.add_theme_color_override("font_color", Color.YELLOW)

# Override button style
button.add_theme_stylebox_override("normal", normal_style)
button.add_theme_stylebox_override("hover", hover_style)
button.add_theme_stylebox_override("pressed", pressed_style)
```

### Visibility and Modulation

```gdscript
# Show/hide elements
info_panel.visible = false
info_panel.visible = true

# Change opacity
card_visual.modulate = Color(1, 1, 1, 0.5)  # 50% transparent

# Change color tint
selected_card.modulate = Color(0.5, 1.0, 0.5)  # Green tint

# Disable without hiding
button.disabled = true  # Grayed out but still visible
```

---

## Card Game Specific Patterns

### Turn-Based State Management

```gdscript
enum GameState {
    CHARACTER_SELECTION,
    COMBAT,
    REWARD,
    GAME_OVER,
    VICTORY
}

var current_state: GameState = GameState.CHARACTER_SELECTION

signal game_state_changed()

func change_state(new_state: GameState):
    current_state = new_state
    game_state_changed.emit()

    match current_state:
        GameState.COMBAT:
            start_combat()
        GameState.REWARD:
            show_rewards()
        GameState.GAME_OVER:
            show_game_over()
```

### Card Targeting System

```gdscript
var selected_card: Card = null
var awaiting_target: bool = false

func _on_card_clicked(card: Card):
    selected_card = card

    match card.target_type:
        Card.TargetType.SELF:
            # Play immediately
            play_card(player, card, player)

        Card.TargetType.ALL_ENEMIES:
            # Play immediately, no targeting
            play_card(player, card, boss)

        Card.TargetType.SINGLE_ENEMY:
            # Wait for target selection
            awaiting_target = true
            show_target_prompt()

func _on_enemy_clicked(enemy: Character):
    if awaiting_target and selected_card:
        play_card(player, selected_card, enemy)
        awaiting_target = false
        selected_card = null
```

### Status Effect Application Pattern

```gdscript
func apply_card_effects(caster: Character, card: Card, target: Character):
    # Damage
    if card.damage > 0:
        for i in card.multi_hit:
            var damage_dealt = target.take_damage(card.damage, card.piercing)

            # Lifesteal
            if card.lifesteal:
                caster.heal(damage_dealt)

    # Healing
    if card.heal_amount > 0:
        target.heal(card.heal_amount)

    # Shield
    if card.shield_amount > 0:
        target.gain_shield(card.shield_amount)

    # Status effects
    if card.apply_poison > 0:
        target.poison += card.apply_poison

    if card.apply_burn > 0:
        target.burn += card.apply_burn

    # Card draw
    if card.draw_cards > 0:
        caster.draw_cards(card.draw_cards)
```

### Character Turn Structure

```gdscript
func start_turn():
    # 1. Refresh energy
    current_energy = max_energy

    # 2. Apply status effects (poison, burn)
    apply_status_effects()

    # 3. Draw cards
    draw_cards(5)

    # 4. Emit signal for UI update
    turn_started.emit()

func end_turn():
    # 1. Discard hand
    while hand.size() > 0:
        discard_card(hand[0])

    # 2. Reset shield (temporary defense)
    shield = 0

    # 3. Decay status effects
    if vulnerable > 0:
        vulnerable -= 1
    if weakness > 0:
        weakness -= 1

    # 4. Emit signal
    turn_ended.emit()
```

### AI Turn Pattern

```gdscript
func play_boss_turn():
    # Simple AI: Play cards until out of energy
    var boss_hand = current_boss.hand.duplicate()

    for card in boss_hand:
        if not current_boss.can_afford(card.energy_cost):
            continue

        var target = select_boss_target(card)
        if target:
            play_card(current_boss, card, target)
            await get_tree().create_timer(0.5).timeout  # Visual delay

    end_boss_turn()

func select_boss_target(card: Card) -> Character:
    match card.target_type:
        Card.TargetType.SELF:
            return current_boss

        Card.TargetType.SINGLE_ENEMY:
            # Target random alive player
            var alive_players = players.filter(func(p): return p.is_alive())
            if alive_players.size() > 0:
                return alive_players[randi() % alive_players.size()]

        Card.TargetType.ALL_ENEMIES:
            return players[0]  # Dummy target, will affect all

    return null
```

---

## Common Pitfalls

### 1. Forgetting to Call `_init()` on Resources

```gdscript
# WRONG: Reusing character without reset
var hero = hero_db.get_hero(0)
# If hero was previously used, health/energy/deck might be wrong

# CORRECT: Reset character state
var hero = hero_db.get_hero(0)
hero._init()  # Reset to starting state
hero.start_turn()  # Initialize for combat
```

### 2. Not Checking for Null References

```gdscript
# WRONG: Assuming node exists
var player = get_node("Player")
player.take_damage(10)  # CRASH if Player doesn't exist!

# CORRECT: Check first
var player = get_node_or_null("Player")
if player:
    player.take_damage(10)
else:
    push_error("Player node not found!")
```

### 3. String Comparison Errors

```gdscript
# WRONG: Case-sensitive comparison
if card_id == "Lightning bolt":  # Won't match "lightning_bolt"
    return card

# CORRECT: Use exact strings or normalize
var normalized_id = card_id.to_lower().replace(" ", "_")
if all_cards.has(normalized_id):
    return all_cards[normalized_id]
```

### 4. Signal Connection Memory Leaks

```gdscript
# WRONG: Connecting multiple times
func create_buttons():
    for i in 10:
        var button = Button.new()
        # Each time this runs, adds ANOTHER connection!
        button.pressed.connect(_on_button_pressed)

# CORRECT: Check or disconnect first
func create_buttons():
    for i in 10:
        var button = Button.new()
        if not button.pressed.is_connected(_on_button_pressed):
            button.pressed.connect(_on_button_pressed)
```

### 5. Modifying Enums Incorrectly

```gdscript
# WRONG: Trying to change enum value
card.card_type = "ATTACK"  # ERROR: Expects enum, not string

# CORRECT: Use enum value
card.card_type = Card.CardType.ATTACK

# CORRECT: Convert from string if needed
var type_name = "ATTACK"
card.card_type = Card.CardType[type_name]  # Converts string to enum
```

### 6. Not Awaiting Async Operations

```gdscript
# WRONG: Continuing immediately after timer
func boss_turn():
    play_card(boss, card1, target)
    get_tree().create_timer(1.0).timeout  # Doesn't wait!
    play_card(boss, card2, target)  # Plays immediately

# CORRECT: Await the timer
func boss_turn():
    play_card(boss, card1, target)
    await get_tree().create_timer(1.0).timeout  # Waits 1 second
    play_card(boss, card2, target)  # Plays after delay
```

### 7. Scene Change Timing

```gdscript
# WRONG: Changing scene while processing
func _on_button_pressed():
    get_tree().change_scene_to_file("res://scenes/combat.tscn")
    update_ui()  # Never executes!

# CORRECT: Change scene deferred or at end
func _on_button_pressed():
    prepare_for_scene_change()
    get_tree().change_scene_to_file.call_deferred("res://scenes/combat.tscn")
```

---

## Quick Reference Checklist

Before pushing code, check:

### Type Safety
- [ ] All game object arrays are typed: `Array[Card]`, `Array[Character]`
- [ ] Function parameters have type hints: `func play_card(card: Card)`
- [ ] Function returns have type hints: `func get_card() -> Card`
- [ ] Dictionary casts use `as`: `return dict["key"] as Card`

### UI and Styling
- [ ] StyleBoxFlat uses individual border widths (not `border_width_all`)
- [ ] Theme overrides use correct property names
- [ ] Custom minimum sizes are set for card visuals
- [ ] Containers (HBoxContainer, VBoxContainer) are used for layout

### Signals
- [ ] Signals use Godot 4 syntax: `button.pressed.connect(_on_pressed)`
- [ ] Custom signals use `emit()`: `card_clicked.emit(card)`
- [ ] Signal connections check for duplicates or disconnect first
- [ ] Signals are disconnected in `_exit_tree()` if needed

### Resources
- [ ] Resources are duplicated when needed: `card.duplicate()`
- [ ] Arrays of resources use deep copy if needed
- [ ] Resource properties use `@export` for editor visibility

### Initialization
- [ ] Node creation happens before usage
- [ ] `_ready()` calls functions in correct order
- [ ] Autoload nodes are accessed via `/root/NodeName`
- [ ] `@onready` variables are only used for scene tree nodes

### Card Game Logic
- [ ] Deck shuffling uses `deck.shuffle()`
- [ ] Array modifications during iteration are safe
- [ ] Turn structure follows: refresh → status effects → draw → play
- [ ] AI uses `await` for visual delays
- [ ] Null checks before accessing characters/cards

### Memory Management
- [ ] Dynamic nodes use `queue_free()` when removed
- [ ] References are cleared when no longer needed
- [ ] Scene changes happen after cleanup

---

## When In Doubt

1. **Check existing working code** - Look at similar patterns in the project
2. **Use type hints everywhere** - Catches errors early
3. **Test edge cases** - What if array is empty? What if character is dead?
4. **Print debug info** - `print("Card: ", card.card_name, " Cost: ", card.energy_cost)`
5. **Read Godot docs** - https://docs.godotengine.org/en/stable/

---

## Resources

- **Godot 4 Documentation**: https://docs.godotengine.org/en/stable/
- **GDScript Reference**: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/
- **Godot 3 to 4 Migration**: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.html

---

*Last updated: 2025-12-30*
*Based on: Godot 4.5 with GDScript*
*Project: Deck Masters Roguelike*
