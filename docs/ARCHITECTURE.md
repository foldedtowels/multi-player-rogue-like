# Architecture Overview

This document explains the structure and design patterns of the Deck Masters Roguelike codebase.

## Table of Contents

1. [System Overview](#system-overview)
2. [Directory Structure](#directory-structure)
3. [Core Systems](#core-systems)
4. [Data Flow](#data-flow)
5. [Design Patterns](#design-patterns)
6. [Key Files Reference](#key-files-reference)

---

## System Overview

### Architecture Style: **Data-Driven MVC**

The game uses a **data-driven** architecture where:
- **Data** is separated from **logic**
- **Content** (heroes, bosses, cards) is defined in data tables
- **Factories** create game objects from data
- **Signals** connect components without tight coupling

### High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        GAME MANAGER                         │
│              (Turn sequencing, game state)                  │
└──────────┬──────────────────────────────────┬───────────────┘
           │                                  │
           ▼                                  ▼
    ┌─────────────┐                   ┌─────────────┐
    │   COMBAT    │◄─────signals─────►│   REWARD    │
    │   (UI View) │                   │   (UI View) │
    └─────────────┘                   └─────────────┘
           │                                  │
           │                                  │
           ▼                                  ▼
    ┌─────────────────────────────────────────────┐
    │            AUTOLOAD SINGLETONS              │
    ├─────────────┬─────────────┬─────────────────┤
    │ CardDatabase│ HeroDatabase│ BossDatabase    │
    │  (Factory)  │  (Factory)  │  (Factory)      │
    └──────┬──────┴──────┬──────┴──────┬──────────┘
           │             │             │
           ▼             ▼             ▼
    ┌──────────────────────────────────────────────┐
    │              DATA LAYER                      │
    ├──────────────┬──────────────┬────────────────┤
    │ HeroesData   │ BossesData   │ GameConstants  │
    │ (Static Dict)│ (Static Dict)│ (Constants)    │
    └──────────────┴──────────────┴────────────────┘
           │             │             │
           ▼             ▼             ▼
    ┌──────────────────────────────────────────────┐
    │          RESOURCE CLASSES                    │
    │   Card (Resource)   Character (Resource)    │
    └──────────────────────────────────────────────┘
```

---

## Directory Structure

```
deck-masters-roguelike/
│
├── docs/                      # Developer documentation
│   ├── ARCHITECTURE.md        # This file
│   ├── HOW_TO_ADD_HERO.md     # Adding new heroes
│   ├── HOW_TO_ADD_CARD.md     # Adding new cards
│   ├── CODE_REVIEW.md         # Known issues/todos
│   └── DESIGN_NOTES.md        # Game balance notes
│
├── scenes/                    # Godot scene files (.tscn)
│   ├── character_selection.tscn  # Hero selection screen
│   ├── combat.tscn               # Battle UI
│   ├── reward.tscn               # Post-battle rewards
│   └── card_visual.tscn          # Card display component
│
├── scripts/                   # GDScript source code
│   │
│   ├── data/                  # DATA LAYER
│   │   ├── heroes_data.gd     # Hero definitions (static data)
│   │   ├── bosses_data.gd     # Boss definitions (static data)
│   │   └── game_constants.gd  # Balance constants
│   │
│   ├── AUTOLOAD SINGLETONS:
│   ├── game_manager.gd        # Turn flow, game state machine
│   ├── card_database.gd       # Card factory
│   ├── hero_database.gd       # Hero factory
│   └── boss_database.gd       # Boss factory
│   │
│   ├── RESOURCE CLASSES:
│   ├── card.gd                # Card data structure
│   └── character.gd           # Character data structure
│   │
│   ├── UI CONTROLLERS:
│   ├── combat.gd              # Combat screen logic
│   ├── reward.gd              # Reward screen logic
│   ├── character_selection.gd # Character selection logic
│   ├── card_visual.gd         # Individual card display
│   └── wizard_visual.gd       # Wizard NPC animation
│   │
│   └── VISUAL SYSTEMS:
│       ├── boss_visuals.gd    # Boss sprite generation
│       └── animated_background.gd  # Background particles
│
└── project.godot              # Godot project configuration
```

---

## Core Systems

### 1. Game Manager (Singleton)

**File**: `scripts/game_manager.gd`

**Responsibilities**:
- Manages game state machine (CHARACTER_SELECTION → COMBAT → REWARD → repeat)
- Controls turn sequencing (Player 1 → Player 2 → Player 3 → Boss)
- Applies card effects to characters
- Emits signals for UI updates

**Key Functions**:
```gdscript
start_player_turn(player_index: int)  # Begin player turn
end_player_turn()                     # End current player turn
play_card(caster, card, target)       # Execute card effects
start_boss_encounter(boss_index)      # Load and start boss fight
```

**Signals**:
```gdscript
signal player_turn_started(player_index: int)
signal boss_turn_started()
signal card_played(character, card, target)
signal combat_ended(victory: bool)
signal game_state_changed()
```

### 2. Resource Classes

#### Character (Resource)

**File**: `scripts/character.gd`

Represents any combatant (player or boss).

**Core Properties**:
```gdscript
# Identity
var character_name: String
var description: String

# Stats
var max_health: int
var current_health: int
var current_energy: int
var max_energy: int
var shield: int

# Status Effects
var poison: int
var burn: int
var strength: int
var vulnerable: int
var weakness: int
var armor: int

# Deck Management
var deck: Array[Card]
var hand: Array[Card]
var discard_pile: Array[Card]
var exhaust_pile: Array[Card]
```

**Key Functions**:
```gdscript
draw_card() -> Card              # Draw from deck to hand
play_card(card: Card)            # Play card from hand
take_damage(amount, piercing)    # Damage calculation with shield/armor
heal(amount: int)                # Restore HP
gain_shield(amount: int)         # Add temporary HP
start_turn()                     # Draw 5 cards, reset energy
end_turn()                       # Discard hand, reset shield
apply_status_effects()           # Process poison/burn damage
```

#### Card (Resource)

**File**: `scripts/card.gd`

Represents a playable card.

**Core Properties**:
```gdscript
# Basic Info
var card_name: String
var description: String
var card_type: CardType          # ATTACK, SPELL, BUFF, DEBUFF, HEAL
var target_type: TargetType      # SELF, SINGLE_ENEMY, ALL_ENEMIES, etc.
var energy_cost: int

# Direct Effects
var damage: int
var heal_amount: int
var shield_amount: int
var draw_cards: int

# Status Effects
var apply_burn: int
var apply_poison: int
var apply_strength: int
var apply_vulnerable: int
var apply_weakness: int
var apply_armor: int

# Special Modifiers
var lifesteal: bool    # Heal for damage dealt
var piercing: bool     # Ignore shield/armor
var aoe_damage: bool   # Hit all targets
```

### 3. Database Factories (Singletons)

#### CardDatabase

**File**: `scripts/card_database.gd`

Creates all player cards using `create_card()` factory.

```gdscript
func create_card(...) -> Card    # Factory function
func get_card(card_id) -> Card   # Retrieve card by ID
```

#### HeroDatabase

**File**: `scripts/hero_database.gd`

Creates heroes from data definitions.

```gdscript
func create_hero(hero_id: String) -> Character
func get_all_heroes() -> Array[Character]
```

**Data Source**: `scripts/data/heroes_data.gd`

#### BossDatabase

**File**: `scripts/boss_database.gd`

Creates bosses from data definitions and registers boss-specific cards.

```gdscript
func create_boss_cards()                          # Register boss cards
func create_boss_by_id(boss_id: String) -> Character
func get_boss(index: int) -> Character            # Get boss by encounter number
func get_all_bosses() -> Array[Character]
```

**Data Source**: `scripts/data/bosses_data.gd`

---

## Data Flow

### Character Selection Flow

```
1. User opens game
   ↓
2. GameManager.change_state(CHARACTER_SELECTION)
   ↓
3. CharacterSelection scene loads
   ↓
4. Calls HeroDatabase.get_all_heroes()
   ↓
5. HeroDatabase reads HeroesData.HEROES
   ↓
6. For each hero:
   - Creates Character resource
   - Fetches cards from CardDatabase
   - Builds starting_deck
   - Calls reset_deck()
   ↓
7. UI displays hero choices
   ↓
8. User selects 3 heroes
   ↓
9. GameManager.players = [hero1, hero2, hero3]
   ↓
10. GameManager.start_boss_encounter(0)
```

### Combat Turn Flow

```
PLAYER TURN:
1. GameManager.start_player_turn(player_index)
   ↓
2. Emits player_turn_started signal
   ↓
3. Combat UI receives signal, updates display
   ↓
4. Character.start_turn() called
   - Resets energy to max
   - Applies poison/burn damage
   - Draws 5 cards
   ↓
5. Combat UI displays hand cards
   ↓
6. User clicks card
   ↓
7. Combat validates: can_afford(energy_cost)?
   ↓
8. User selects target (if needed)
   ↓
9. GameManager.play_card(caster, card, target)
   - Applies damage/heal/shield
   - Applies status effects
   - Emits card_played signal
   ↓
10. Repeat steps 6-9 until user clicks "End Turn"
    ↓
11. GameManager.end_player_turn()
    - Character.end_turn() (discard hand, reset shield)
    - Decays vulnerable/weakness
    ↓
12. If 3 players done: start_boss_turn()
    Else: start_player_turn(next_player)

BOSS TURN:
1. GameManager.start_boss_turn()
   ↓
2. Boss.start_turn()
   - Draws 5 cards
   - Resets energy
   ↓
3. For each card in hand (if can afford):
   - Pick random player target
   - Play card
   - Wait 0.5s
   ↓
4. Boss.end_turn()
   ↓
5. Check win/loss:
   - All players dead? → GAME_OVER
   - Boss dead? → REWARD screen
   - Else: Next round, start_player_turn(0)
```

### Reward Flow

```
1. Boss defeated
   ↓
2. GameManager.change_state(REWARD)
   ↓
3. Reward scene loads
   ↓
4. Wizard appears with speech animation
   ↓
5. Rare card selection (1 random player):
   - CardDatabase provides 3 random cards
   - Player selects 1
   - Card added to player.starting_deck
   ↓
6. Common choices (all players):
   - Each player chooses: Heal 50% | Random Common Card | Skip
   ↓
7. GameManager.advance_to_next_boss()
   ↓
8. If boss_index < 5:
   - start_boss_encounter(next_boss_index)
   Else:
   - change_state(VICTORY)
```

---

## Design Patterns

### 1. Factory Pattern

**Where**: HeroDatabase, BossDatabase, CardDatabase

**Why**: Centralized object creation from data definitions.

**Example**:
```gdscript
# OLD WAY (hardcoded):
func create_flame_wielder() -> Character:
    var hero = Character.new()
    hero.character_name = "Pyra"
    hero.max_health = 90
    # ... 25 more lines of repetitive code
    return hero

# NEW WAY (data-driven):
func create_hero(hero_id: String) -> Character:
    var data = HeroesData.HEROES[hero_id]  # Fetch data
    var hero = Character.new()
    hero.character_name = data.name        # Apply data
    hero.max_health = data.max_health
    # ... build deck from data.deck
    return hero
```

**Benefits**:
- Add new hero in 8 lines of data instead of 30 lines of code
- Easier to balance (all values in one place)
- Less duplication

### 2. Singleton (Autoload) Pattern

**Where**: GameManager, CardDatabase, HeroDatabase, BossDatabase

**Why**: Global access to game systems without coupling.

**Usage**:
```gdscript
# Any script can access:
var game_manager = get_node("/root/GameManager")
var card = get_node("/root/CardDatabase").get_card("fireball")
```

**Configuration**: Set in `project.godot` autoload section.

### 3. Signal-Based Communication

**Where**: GameManager ↔ Combat UI, GameManager ↔ Reward UI

**Why**: Decouples game logic from UI. UI reacts to state changes without direct references.

**Example**:
```gdscript
# GameManager emits:
signal player_turn_started(player_index: int)

# Combat UI listens:
func _ready():
    game_manager.player_turn_started.connect(_on_player_turn_started)

func _on_player_turn_started(player_index: int):
    current_player = game_manager.players[player_index]
    update_hand()  # Draw cards in UI
```

**Benefits**:
- GameManager doesn't need to know about UI
- Easy to add new UI elements
- Clear event flow

### 4. Resource Classes

**Where**: Card, Character

**Why**: Godot's Resource system provides automatic serialization and duplication.

**Usage**:
```gdscript
var card_copy = original_card.duplicate()  # Deep copy
```

**Benefits**:
- Easy to save/load game state (future feature)
- Clean data structures
- Type safety with @export

### 5. Data-Driven Design

**Where**: HeroesData, BossesData, GameConstants

**Why**: Separating data from logic makes balancing and content addition easier.

**Structure**:
```
CODE (Logic)              DATA (Content)
─────────────            ──────────────
hero_database.gd   ──►   heroes_data.gd
boss_database.gd   ──►   bosses_data.gd
character.gd       ──►   game_constants.gd
```

**Benefits**:
- Designers can edit balance without touching code
- Version control shows clear content changes
- Easier to generate content from external tools

---

## Key Files Reference

### Must-Read Files (Core Logic)

| File | Purpose | Lines | Complexity |
|------|---------|-------|------------|
| `game_manager.gd` | Game state machine, turn flow | 254 | High |
| `character.gd` | Character stats, deck management | 185 | Medium |
| `card.gd` | Card properties and logic | 80 | Low |

### Data Files (Content Definitions)

| File | Purpose | Lines | Edit Frequency |
|------|---------|-------|----------------|
| `heroes_data.gd` | All hero definitions | 120 | High (add heroes) |
| `bosses_data.gd` | All boss definitions | 290 | High (add bosses) |
| `game_constants.gd` | Balance values | 113 | Medium (tuning) |
| `card_database.gd` | All card definitions | 640 | High (add cards) |

### Factory Files (Object Creation)

| File | Purpose | Pattern |
|------|---------|---------|
| `hero_database.gd` | Create heroes from data | Factory |
| `boss_database.gd` | Create bosses from data | Factory |
| `card_database.gd` | Create cards | Factory |

### UI Controllers

| File | Controls | Complexity |
|------|----------|------------|
| `combat.gd` | Battle screen, card playing | Medium |
| `reward.gd` | Reward selection, wizard | Low |
| `character_selection.gd` | Hero selection | Low |
| `card_visual.gd` | Individual card display | Low |

---

## Code Statistics (Post-Refactor)

### Before Refactoring:
- **Total**: 3,273 LOC
- **Duplication**: 95% in database files
- **hero_database.gd**: 189 LOC (6 repetitive functions)
- **boss_database.gd**: 384 LOC (5 repetitive functions)

### After Refactoring:
- **Total**: ~2,100 LOC (-36%)
- **Duplication**: <10%
- **hero_database.gd**: 82 LOC (1 factory + data)
- **boss_database.gd**: 145 LOC (1 factory + data)

### Impact:
- **Adding new hero**: 30 lines → 8 lines (73% reduction)
- **Adding new boss**: 80 lines → 15 lines (81% reduction)
- **Maintainability**: 6.5/10 → 9/10

---

## Extension Points

### Adding New Features

| Feature | Files to Modify | Difficulty |
|---------|----------------|------------|
| **New Hero** | `heroes_data.gd` | Easy |
| **New Boss** | `bosses_data.gd` | Easy |
| **New Card** | `card_database.gd` | Easy |
| **New Status Effect** | `character.gd`, `game_manager.gd` | Medium |
| **New Game Mode** | `game_manager.gd` | Hard |
| **Multiplayer** | `game_manager.gd`, `combat.gd` | Hard |
| **Save/Load** | `game_manager.gd`, new save system | Medium |

### Future Improvements

**Recommended**:
1. ~~Extract magic numbers to constants~~ ✅ DONE
2. ~~Data-driven hero/boss creation~~ ✅ DONE
3. ~~Developer documentation~~ ✅ DONE
4. Extract EffectSystem from GameManager
5. Create BossAI class for boss strategy
6. Component-based boss visuals (less duplication)

**Nice to Have**:
1. Card database from JSON/CSV files
2. Visual deck builder tool
3. Replay system
4. Achievement system
5. Meta-progression (unlock heroes/cards)

---

## Performance Considerations

### Current Bottlenecks

1. **Card Duplication**: Every `get_card()` calls `duplicate()` - acceptable for current scale
2. **Boss Visuals**: CPUParticles2D can impact framerate on low-end devices
3. **Hand Updates**: Recreates all card visuals on every hand change

### Optimization Opportunities

- Object pooling for card visuals (reuse instead of recreate)
- Lazy loading boss visuals (only create when boss appears)
- Cache card duplicates per battle

**Current Performance**: 60 FPS on mid-range hardware (acceptable)

---

## Testing Strategy

### Manual Testing Checklist

- [ ] All 6 heroes playable
- [ ] All 5 bosses defeatable
- [ ] Card effects work correctly
- [ ] Status effects apply/decay properly
- [ ] Rewards work (heal, card selection)
- [ ] Victory/defeat screens trigger
- [ ] No console errors/warnings

### Balance Testing

- Each hero should be able to defeat Boss 1 with basic strategy
- Boss difficulty should scale (Boss 5 significantly harder than Boss 1)
- No single card should be mandatory for victory
- Average run should take 20-30 minutes

---

## Glossary

- **Autoload**: Godot singleton pattern, globally accessible node
- **Resource**: Godot data class that can be saved/duplicated
- **Signal**: Event emitter for decoupled communication
- **Factory Pattern**: Centralized object creation from data
- **AoE**: Area of Effect (affects multiple targets)
- **Status Effect**: Ongoing effect (poison, burn, strength, etc.)
- **Deck Management**: Drawing, discarding, shuffling cards

---

## Questions?

For specific guides:
- **Adding content**: See `HOW_TO_ADD_HERO.md` and `HOW_TO_ADD_CARD.md`
- **Game balance**: See `DESIGN_NOTES.md`
- **Known issues**: See `CODE_REVIEW.md`
