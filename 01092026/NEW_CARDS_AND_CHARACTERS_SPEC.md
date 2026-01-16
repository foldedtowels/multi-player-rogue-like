# New Cards and Characters Implementation Specification

**Date**: January 9, 2026
**Status**: Planning Phase
**Implementation Approach**: Per-character phases (Fabio → Enrique → Kevin)

---

## Executive Summary

This document specifies the implementation of **89 new cards** and **3 new characters** (Fabio, Kevin, Enrique) to eventually replace the existing 6 heroes. The implementation introduces major new systems including:

- **Aura Resource System** (Enrique)
- **Alchemy/Satchel Deck System** (Kevin)
- **Passive Abilities System** (All characters)
- **v2 Card Choice System** (Modal popup during play)
- **15 New Status Effects** (Wet, Venom, Scared, etc.)
- **Spell Elements** (Water, Fire, Earth, Wind, Light, Dark)
- **Conditional Damage** (UI display + auto-calculation)
- **Turn 2 Damage** (Delayed damage tracking)
- **Stamina Terminology** (Renaming Energy → Stamina)

**Old heroes will remain available during development for testing.**

---

## Characters Overview

### Character Stats Comparison

| Character | Class | Max HP | Stamina/Turn | Special Resource | Archetype |
|-----------|-------|--------|--------------|------------------|-----------|
| **Fabio** | Warrior | 50 | 2 | Passive Ability | Tank/Protector |
| **Kevin** | Mage | 40 | 2 | Alchemy Satchel | Spell Combo |
| **Enrique** | Cleric | 30 | 2 | Aura (gains 1/turn) | Healer/Support |

### Fabio - The Warrior

**HP**: 50 (highest)
**Stamina**: 2
**Passive Ability**: "Warrior's Choice"
- **Trigger**: Can activate once per turn, anytime during action phase, free (no stamina cost)
- **Effect**: Choose one:
  - Deal 2 damage to boss
  - Draw 1 card
  - Give 3 shield to target player

**Playstyle**: Tank/protector with attack-focused cards and ally protection abilities.

**Card Count**: 26 cards
- Base deck: Slash, Big Smack, Duel Purpose, Rest, Bulk Up, "Dig a Hole", Protector, Protective Footwear, Hunter's Instinct
- Special mechanics: Dual Wield, Circular Strike (multi-target), Jumping Strike
- Reward cards: Medkit, Fighter's Spirit (v2), Sacrifice, Leader (v2)

### Kevin - The Alchemist

**HP**: 40 (medium)
**Stamina**: 2
**Special System**: Alchemy/Satchel Deck

**Alchemy System** (3 possible designs - TBD during implementation):

**Option 1: Discard-to-Play** (Most likely)
- Kevin has a separate "Satchel Deck" with powerful Alc' cards
- To play an Alc' card from Satchel, must discard specific spell element cards from hand as "ingredients"
- Example: "Lightning Storm (Alc' Wind)" requires discarding 1 Wind spell card
- Example: "Accumulation (Alc' Dark)" requires discarding 1 Dark spell card

**Option 2: Resource System**
- Kevin collects Water/Earth/Fire/Wind/Light/Dark resources by playing spell element cards
- Spends resources to play Alc' cards from Satchel
- Resources persist between turns (or reset each turn - TBD)

**Option 3: Combo System**
- Playing specific spell combinations unlocks Alc' cards from Satchel
- Example: Play 2 Fire spells → unlock Fire-based Alc' card
- Unlocked cards are added to hand or playable that turn

**Playstyle**: Complex spell combo mage requiring careful resource/hand management.

**Card Count**: 24 cards
- Base deck: Poke, Meditate, Rest, Fetal Position
- Spell elements: Fire Smash, Water Ball, Earth Quake, Fiery Flash!, Tsunami
- Alchemy Satchel: Lightning Storm (Wind), Accumulation (Dark), Giant Shield (Light), Future Vision (Earth), Mortar and Pestle (Earth), Enflame (Fire), Restore (Water), Ring Of Fire (Fire)
- Support: Reformulate, Accretion

### Enrique - The Cleric

**HP**: 30 (lowest)
**Stamina**: 2
**Special Resource**: Aura
- **Generation**: Gains 1 Aura at the start of every turn (automatic, passive)
- **Persistence**: Resets to 0 after each fight
- **Usage**: Spent to play powerful Aura-cost cards (costs 1-3 Aura)
- **Display**: Shown alongside HP and Stamina in UI

**Playstyle**: Healing/support cleric with powerful Aura-based abilities.

**Card Count**: 20 cards
- Base deck: Focused Purge, Holy Plight, Humble Request, Divine Reflection, Healing Aura, Magical Purge, Story Of Jacob, Protection
- Reward cards: Divine Force (v2), Purging Water, Divine Barrier, Refuge, Gift, Divine Gift, Guy with Beard
- Many cards have Decay mechanic (time-limited effects)

---

## New Systems & Mechanics

### 1. Stamina (Renaming from Energy)

**Change**: Rename all instances of "Energy" → "Stamina" in code and UI.

**Files Affected**:
- `scripts/character.gd` - `current_energy` → `current_stamina`, `max_energy` → `max_stamina`, `starting_energy` → `starting_stamina`
- `scripts/card.gd` - `energy_cost` → `stamina_cost`
- `scripts/combat.gd` - Energy checks → Stamina checks
- `scripts/ui/player_panel.gd` - UI labels
- All other references throughout codebase

**Backward Compatibility**: Old heroes still work, just use renamed property.

---

### 2. Passive Abilities System

**Description**: Per-character abilities that trigger automatically or on-demand.

**Implementation**:
- Add `passive_ability_id: String` to Character class
- Create `PassiveAbility` resource class with `trigger_type`, `effect_type`, `parameters`
- Create `PassiveAbilityManager` autoload to handle ability logic
- Add UI for passive ability triggers (e.g., Fabio's choice modal)

**Example - Fabio's Passive**:
```gdscript
# In character.gd
var passive_ability_id: String = "fabio_warrior_choice"
var passive_ability_used_this_turn: bool = false

# In PassiveAbilityManager
func trigger_passive(character: Character, choice: int):
    match character.passive_ability_id:
        "fabio_warrior_choice":
            match choice:
                0: # Deal 2 damage to boss
                1: # Draw 1 card
                2: # Give 3 shield to target player
```

**UI**:
- Fabio: Modal with 3 buttons during action phase
- Future characters: Varies by passive type

---

### 3. v2 Card Choice System

**Description**: Cards with "v2" variants where player chooses which effect to apply during play.

**Examples from CSV**:
- **Divine Force** (v1): Heal target ally with Decay debuff
- **Divine Force v2**: Deal 6 damage to enemy
- **Fighter's Spirit** (v1): Discard 1 card for benefit
- **Fighter's Spirit v2**: Gain 5 shield

**Implementation**:
- Add `has_v2: bool` and `v2_card: Card` properties to Card class
- When player plays a v2 card, show modal popup with 2 options
- Each option displays the full effect description
- Player clicks one option to proceed with card play using chosen effect

**UI Modal**:
```
┌─────────────────────────────────┐
│       Choose Card Effect        │
├─────────────────────────────────┤
│  [Divine Force]                 │
│  Heal target ally for 8 HP      │
│  Apply Decay to target          │
│         [ Choose v1 ]           │
├─────────────────────────────────┤
│  [Divine Force v2]              │
│  Deal 6 damage to enemy         │
│                                 │
│         [ Choose v2 ]           │
└─────────────────────────────────┘
```

**Technical Flow**:
1. Player clicks v2 card to play
2. Modal appears with both options
3. Player selects v1 or v2
4. Card plays with chosen effect
5. Card goes to discard pile (not exhaust)

---

### 4. Aura Resource System (Enrique)

**Description**: Secondary resource that generates passively each turn.

**Properties**:
- **Generation**: +1 Aura at start of each turn (before card draw)
- **Persistence**: Resets to 0 after each fight
- **Maximum**: No cap (can accumulate indefinitely during a fight)
- **Display**: Shown in player panel alongside HP and Stamina

**Implementation**:
- Add `current_aura: int`, `max_aura: int` (optional cap) to Character class
- Add `aura_cost: int` to Card class
- Modify `start_turn()` to grant Aura to Enrique
- Update affordability checks to include Aura cost
- Update player panel UI to show Aura (only for Enrique)

**Card Cost Display**:
```
┌─────────────────┐
│  Divine Force   │  Cost: 1 Stamina, 2 Aura
│                 │
│  Heal all       │
│  allies for 12  │
└─────────────────┘
```

---

### 5. Alchemy/Satchel System (Kevin)

**Description**: Kevin has a separate "Satchel Deck" with powerful Alc' cards requiring specific spell element ingredients.

**Three Design Options** (choose during Kevin implementation):

#### Option A: Discard-to-Play (Recommended)
- Kevin has 2 decks: Main deck + Satchel deck
- Satchel deck is visible/accessible during combat (new UI panel)
- To play an Alc' card, must discard specific element spell cards from hand
- Example: "Lightning Storm (Alc' Wind)" requires discarding 1 Wind spell
- CSV columns: `Alc Water Discard`, `Alc Earth Discard`, `Alc Fire Discard`

**Implementation**:
```gdscript
# In character.gd
var satchel_deck: Array[Card] = []  # Kevin's Alc' cards

# In card.gd
var alchemy_ingredients: Dictionary = {
    "water": 0,  # Requires X Water spells
    "earth": 0,
    "fire": 0,
    "wind": 0,
    "light": 0,
    "dark": 0
}

# In combat/card play logic
func can_play_alchemy_card(card: Card, hand: Array[Card]) -> bool:
    for element in card.alchemy_ingredients:
        var required_count = card.alchemy_ingredients[element]
        var available = count_element_cards_in_hand(hand, element)
        if available < required_count:
            return false
    return true
```

#### Option B: Resource System
- Kevin gains element resources (Water/Fire/Earth/Wind/Light/Dark) by playing spell cards
- Resources persist between turns (or reset each turn - TBD)
- Spends resources to play Alc' cards
- Similar to mana pool system in Magic: The Gathering

#### Option C: Combo System
- Playing specific spell combinations unlocks Alc' cards
- Example: Play 2 Fire spells in one turn → Unlock Fire Alc' card
- Unlocked cards are added to hand or become playable

**UI for Satchel Deck**:
- New panel below/beside main hand
- Shows Kevin's Satchel cards
- Grayed out when ingredients not available
- Highlights available Alc' cards when player has correct ingredients

---

### 6. Spell Elements

**Description**: Additional property for cards to specify elemental type.

**Elements**: Water, Fire, Earth, Wind, Light, Dark

**Implementation**:
- Add `SpellElement` enum to Card class
- Add `spell_element: SpellElement` property (default: NONE)
- Elements are ADDITIONAL to card type (ATTACK/SPELL/etc.)
- Example: "Fire Smash" is CardType.SPELL with SpellElement.FIRE

**Enum**:
```gdscript
enum SpellElement {
    NONE,
    WATER,
    FIRE,
    EARTH,
    WIND,
    LIGHT,
    DARK
}
```

**UI Display**:
- Show element icon/color on card
- Fire = Red, Water = Blue, Earth = Brown, Wind = White, Light = Yellow, Dark = Purple

**Purpose**:
- Kevin's Alchemy system (discard X Fire spells to play Alc' Fire card)
- Card interactions (e.g., "Deal +5 damage if target is Wet" - Water element synergy)

---

### 7. New Status Effects

**Source**: `csvs/buffs-and-debuffs.csv`

#### Debuffs

| Name | Stackable | Description | Duration | Implementation Notes |
|------|-----------|-------------|----------|---------------------|
| **Wet** | Yes (1) | Does nothing itself, but cards interact with it | Until removed | Stack counter, check in card effects |
| **Famished Beast** | No | Discard 2 cards at start of turn | Removes at end of turn | Force discard at turn start |
| **Venom** | Yes (1) | When you reach 3 stacks, HP → 0 (instant kill) | Until removed | Critical: Check after each stack added |
| **Scared** | No | Cannot use ATTACK cards next turn | Removed after 1 turn | Filter playable cards, counter |
| **Hinder** | Yes (1) | Weakness for one turn | 1 turn | Uses existing weakness system + counter |
| **Exhausted** | No | Cannot play ANY cards this turn | Removed at end of turn | Disable hand, show UI warning |
| **Fatigued** | No | Start with -1 Stamina next turn | 2 turns (apply next turn, remove after) | Modify start_turn() stamina |
| **Decay** | No | Cannot heal or be healed for rest of turn | 1 turn | Block heal effects |
| **Acquisition** | No | Top card of deck is exhausted until end of fight | Until end of fight | Move top card to exhaust pile |

#### Buffs

| Name | Stackable | Description | Duration | Implementation Notes |
|------|-----------|-------------|----------|---------------------|
| **Rested** | Yes (1) | Gain +1 Stamina at start of turn | Removed after applied | Grant stamina at turn start, remove |
| **Invigorated** | Yes (1) | Gain 2 DamagePlus | Removed at end of turn | Apply DamagePlus stacks |
| **Ring of Fire** | Yes (1) | When you take damage, deal 3 damage to attacker | Removed at end of turn | Trigger in damage calculation |
| **Invincible** | No | Take no damage this turn | Removed at end of turn | Block all incoming damage |
| **DamagePlus** | Yes (1) | Strength that lasts for only one turn | 1 turn | Like strength but with counter |

**Implementation**:
- Add properties to Character class for each status effect
- Add status effect counters (for stackable effects)
- Add status effect duration tracking
- Modify combat logic to check/apply status effects at appropriate times
- Update UI to display status effects on player panels

**Turn Processing Order**:
1. Start of turn: Apply Rested (stamina), Famished Beast (discard), Fatigued (reduce stamina)
2. During turn: Check Scared (filter attacks), Exhausted (disable hand), Decay (block heals)
3. On damage: Check Invincible (block), Ring of Fire (counter-attack), Wet interactions
4. End of turn: Remove temporary buffs/debuffs, decrement counters

---

### 8. Conditional Damage

**Description**: Cards deal additional damage based on game state conditions.

**Examples from CSV**:
- "Add 10 damage if boss is below half HP"
- "Add 5 damage if you took no damage last turn"
- "Add 3 damage per Wet stack on target"

**Implementation**:
- Add `conditional_damage: Dictionary` to Card class
- Store condition type and bonus amount
- **UI Display**: Show conditional damage on card (e.g., "12 damage (+10 if boss below 50% HP)")
- **Auto-Calculate**: When card is played, check conditions and apply bonus automatically

**Dictionary Format**:
```gdscript
conditional_damage = {
    "type": "target_hp_below_percent",
    "threshold": 50,
    "bonus_damage": 10
}

# Or for multiple conditions:
conditional_damage = [
    {"type": "target_hp_below_percent", "threshold": 50, "bonus_damage": 10},
    {"type": "self_took_no_damage_last_turn", "bonus_damage": 5}
]
```

**Condition Types**:
- `target_hp_below_percent` - Target HP below X%
- `target_hp_above_percent` - Target HP above X%
- `self_took_no_damage_last_turn` - Player took 0 damage last turn
- `target_has_status` - Target has specific status effect (e.g., Wet)
- `self_has_status` - Player has specific status effect
- `cards_played_this_turn` - Number of cards played this turn exceeds X
- `discard_pile_size` - Discard pile has X or more cards

**UI Example**:
```
┌─────────────────┐
│  Execution      │  Cost: 2 Stamina
│                 │
│  Deal 12 damage │
│  (+10 if target │
│   below 50% HP) │
└─────────────────┘
```

---

### 9. Turn 2 Damage (Delayed Damage)

**Description**: Cards deal damage this turn AND on the target's next turn.

**Examples from CSV**:
- Card deals 8 damage immediately, then 5 damage at start of target's next turn

**Implementation**:
- Add `turn_2_damage: int` property to Card class
- Create `delayed_damage_effects: Array[Dictionary]` on Character class
- When card is played, apply immediate damage + store delayed damage effect
- At start of target's turn, check and apply all delayed damage effects

**Delayed Effect Format**:
```gdscript
# Stored on target character
delayed_damage_effects = [
    {
        "damage": 5,
        "source": "Jumping Strike",
        "trigger_turn": 3  # Turn number when to apply
    }
]
```

**UI Display**:
```
┌─────────────────┐
│  Jumping Strike │  Cost: 2 Stamina
│                 │
│  Deal 8 damage  │
│  Deal 5 damage  │
│  next turn      │
└─────────────────┘
```

**Combat Log**:
```
[Round 2] Fabio plays Jumping Strike → Boss takes 8 damage
[Round 3 - Boss Turn Start] Boss takes 5 delayed damage from Jumping Strike
```

---

### 10. Card Dictionary Properties (CSV Columns)

**Reference**: `csvs/card-dictionary.csv` defines 62 possible card properties.

**Key Properties to Implement**:

| CSV Column | Code Property | Type | Description |
|------------|---------------|------|-------------|
| `Name` | `card_name` | String | Display name |
| `Card Type` | `card_type` | Enum | ATTACK, SPELL, BUFF, DEBUFF, HEAL |
| `Stamina Cost` | `stamina_cost` | int | Cost to play |
| `Aura Cost` | `aura_cost` | int | Aura cost (Enrique only) |
| `Stamina Gain` | `stamina_gain` | int | Grant stamina when played |
| `Aura Gain` | `aura_gain` | int | Grant aura when played |
| `Player's Target` | `player_target_type` | Enum | SELF, ALLY, ALL_ALLIES, ANY |
| `Boss's Target` | `boss_target_type` | Enum | SINGLE, ALL, RANDOM |
| `Base Damage` | `damage` | int | Immediate damage dealt |
| `Total Attacks` | `multi_hit` | int | Number of times to apply damage |
| `Turn 1 Damage` | `damage` | int | Same as Base Damage |
| `Turn 2 Damage` | `turn_2_damage` | int | Delayed damage next turn |
| `Additional Damage` | `conditional_damage` | Dictionary | Conditional bonus damage |
| `Piercing` | `piercing` | bool | Ignores armor/shield |
| `Heal` | `heal_amount` | int | HP restored |
| `Shield Gain` | `shield_amount` | int | Temporary HP |
| `Draw Cards` | `draw_cards` | int | Number of cards drawn |
| `Discard Cards` | `discard_cards` | int | Force discard X cards |
| `Retain` | `retain` | bool | Don't discard at end of turn |
| `Played Twice` | `played_twice` | bool | Execute effect twice |
| `Exhaust` | `exhaust` | bool | Remove from combat after use |
| `Spell Element` | `spell_element` | Enum | WATER, FIRE, EARTH, WIND, LIGHT, DARK |
| `Alc Water Discard` | `alchemy_ingredients["water"]` | int | Water spells to discard |
| `Alc Earth Discard` | `alchemy_ingredients["earth"]` | int | Earth spells to discard |
| `Alc Fire Discard` | `alchemy_ingredients["fire"]` | int | Fire spells to discard |
| Status effects (15 columns) | Individual properties | int | Stacks to apply |

---

## Implementation Phases

### Phase 0: Preparation (Foundation Systems)

**Goal**: Rename Energy → Stamina and implement v2 card choice system (used by all characters).

**Tasks**:
1. Rename all `energy` → `stamina` in codebase
   - `scripts/character.gd`: `current_energy` → `current_stamina`, etc.
   - `scripts/card.gd`: `energy_cost` → `stamina_cost`
   - `scripts/combat.gd`: All energy checks
   - `scripts/ui/player_panel.gd`: UI labels
   - Search entire codebase for "energy" and update
2. Implement v2 card choice modal UI
   - Create `res://scenes/ui/card_v2_choice_modal.tscn`
   - Create `scripts/ui/card_v2_choice_modal.gd`
   - Add `has_v2: bool`, `v2_card: Card` to Card class
   - Wire up modal to card play logic in `combat.gd`
3. Add new status effect properties to Character class (empty for now)
4. Extend Card class with new properties (set to defaults for old cards)

**Testing**: Old 6 heroes should still work with renamed Stamina.

---

### Phase 1: Fabio - The Warrior

**New Systems**: Passive Abilities

**Tasks**:
1. **Passive Ability System**
   - Create `PassiveAbility` resource class
   - Create `PassiveAbilityManager` autoload
   - Add `passive_ability_id: String`, `passive_ability_used_this_turn: bool` to Character class
   - Implement Fabio's passive: "Warrior's Choice"
     - UI: Modal with 3 buttons (Deal 2 damage / Draw 1 card / Give 3 shield)
     - Trigger: Available during action phase, once per turn, free
     - Logic: Apply chosen effect immediately
   - Reset passive usage at start of each turn

2. **Add Fabio Character**
   - Add to `scripts/data/heroes_data.gd`:
     ```gdscript
     "fabio": {
         "name": "Fabio, The Warrior",
         "description": "Protective tank with versatile combat choices",
         "max_health": 50,
         "starting_stamina": 2,
         "passive_ability_id": "fabio_warrior_choice",
         "deck": [/* 26 card IDs */]
     }
     ```

3. **Add Fabio's 26 Cards**
   - Add to `scripts/card_database.gd`
   - Implement base deck: Slash, Big Smack, Duel Purpose, Rest, Bulk Up, "Dig a Hole", Protector, Protective Footwear, Hunter's Instinct
   - Implement reward cards: Medkit, Dual Wield, Circular Strike, Cursed Dagger, Jumping Strike, Execution, Frenzy!, Weak Point!, Fighter's Spirit (v2), Sacrifice, Leader (v2)
   - **v2 Cards**:
     - Fighter's Spirit (v1): Discard 1 card for benefit
     - Fighter's Spirit (v2): Gain 5 shield
     - Leader (v1): Give 2 cards to other players
     - Leader (v2): Give 1 card to other players

4. **Implement Fabio-Specific Status Effects**
   - Rested (buff): +1 Stamina at start of turn
   - Invigorated (buff): +2 DamagePlus
   - DamagePlus (buff): Strength for one turn
   - Fatigued (debuff): -1 Stamina next turn

5. **Testing**
   - Full game loop with Fabio vs minions/boss
   - Test passive ability UI and effects
   - Test v2 card choice modal
   - Test all 26 Fabio cards
   - Multiplayer: 3 Fabio players

**Files Modified**:
- NEW: `scripts/passive_ability.gd`
- NEW: `scripts/passive_ability_manager.gd`
- NEW: `scenes/ui/passive_ability_modal.tscn` (Fabio's choice UI)
- MODIFY: `scripts/character.gd` - Add passive properties
- MODIFY: `scripts/data/heroes_data.gd` - Add Fabio
- MODIFY: `scripts/card_database.gd` - Add 26 cards
- MODIFY: `scripts/combat.gd` - Wire up passive triggers
- MODIFY: `scripts/ui/player_panel.gd` - Show "Passive Ready" indicator

---

### Phase 2: Enrique - The Cleric

**New Systems**: Aura Resource, Decay Mechanic

**Tasks**:
1. **Aura Resource System**
   - Add to Character class:
     ```gdscript
     var current_aura: int = 0
     var max_aura: int = -1  # -1 = no cap
     ```
   - Add to Card class:
     ```gdscript
     var aura_cost: int = 0
     ```
   - Modify `start_turn()` in `game_manager.gd`:
     ```gdscript
     if character.passive_ability_id == "enrique_aura_generation":
         character.current_aura += 1
     ```
   - Update affordability checks to include Aura cost
   - Update player panel UI to show Aura (only for Enrique)
   - Reset Aura to 0 after each fight (in `initialize_combat_encounter()`)

2. **Add Enrique Character**
   - Add to `scripts/data/heroes_data.gd`:
     ```gdscript
     "enrique": {
         "name": "Enrique, The Cleric",
         "description": "Support healer with Aura-based miracles",
         "max_health": 30,
         "starting_stamina": 2,
         "passive_ability_id": "enrique_aura_generation",
         "deck": [/* 20 card IDs */]
     }
     ```

3. **Add Enrique's 20 Cards**
   - Add to `scripts/card_database.gd`
   - Base deck: Focused Purge, Holy Plight, Humble Request, Divine Reflection, Healing Aura, Magical Purge, Story Of Jacob, Protection
   - Reward cards: Divine Force (v2), Purging Water, Divine Barrier, Refuge, Gift, Divine Gift, Guy with Beard
   - **v2 Card**:
     - Divine Force (v1): Heal target ally + Decay
     - Divine Force (v2): Deal 6 damage to enemy
   - Many cards use Aura cost instead of Stamina cost

4. **Implement Decay Mechanic**
   - Add `decay: int` to Character class (turns remaining)
   - At turn start: Decrement decay counter
   - During heal effects: Check for decay, block healing if active
   - UI: Show Decay icon on player panel

5. **Implement Enrique-Specific Status Effects**
   - Decay (debuff): Cannot heal or be healed
   - Invincible (buff): Take no damage this turn
   - (Leverage Rested, Invigorated from Fabio phase)

6. **Testing**
   - Full game loop with Enrique vs minions/boss
   - Test Aura generation and spending
   - Test Decay blocking heals
   - Test all 20 Enrique cards
   - Multiplayer: Fabio + 2 Enriques, or 1 Fabio + 1 Enrique + 1 old hero

**Files Modified**:
- MODIFY: `scripts/character.gd` - Add Aura properties, Decay
- MODIFY: `scripts/card.gd` - Add aura_cost
- MODIFY: `scripts/data/heroes_data.gd` - Add Enrique
- MODIFY: `scripts/card_database.gd` - Add 20 cards
- MODIFY: `scripts/game_manager.gd` - Aura generation at turn start
- MODIFY: `scripts/combat.gd` - Check Aura cost, block heals if Decay
- MODIFY: `scripts/ui/player_panel.gd` - Display Aura, Decay icon
- MODIFY: `scripts/ui/card_visual.gd` - Show Aura cost on cards

---

### Phase 3: Kevin - The Alchemist

**New Systems**: Alchemy/Satchel Deck, Spell Elements

**Tasks**:
1. **Spell Elements System**
   - Add enum to Card class:
     ```gdscript
     enum SpellElement { NONE, WATER, FIRE, EARTH, WIND, LIGHT, DARK }
     var spell_element: SpellElement = SpellElement.NONE
     ```
   - Update card visual UI to show element icon/color
   - Add helper functions to count element cards in hand/deck

2. **Alchemy/Satchel System** (Choose implementation during this phase)
   - Add to Character class:
     ```gdscript
     var satchel_deck: Array[Card] = []
     ```
   - Add to Card class:
     ```gdscript
     var is_alchemy_card: bool = false
     var alchemy_ingredients: Dictionary = {
         "water": 0, "earth": 0, "fire": 0,
         "wind": 0, "light": 0, "dark": 0
     }
     ```
   - Create Satchel UI panel (displays Kevin's Alc' cards)
   - Implement ingredient checking logic
   - Implement card play flow:
     1. Player clicks Alc' card from Satchel
     2. System checks if player has required element cards in hand
     3. If yes: Prompt player to select cards to discard
     4. Discard ingredients → Play Alc' card
     5. If no: Card is grayed out/unplayable

3. **Add Kevin Character**
   - Add to `scripts/data/heroes_data.gd`:
     ```gdscript
     "kevin": {
         "name": "Kevin, The Alchemist",
         "description": "Spell combo mage with alchemical transmutations",
         "max_health": 40,
         "starting_stamina": 2,
         "passive_ability_id": "kevin_alchemy",
         "deck": [/* 16 main deck card IDs */],
         "satchel_deck": [/* 8 Alc' card IDs */]
     }
     ```
   - Modify `hero_database.gd` to load satchel_deck

4. **Add Kevin's 24 Cards**
   - Add to `scripts/card_database.gd`
   - **Main Deck (16 cards)**: Poke, Meditate, Rest, Fetal Position, Fire Smash, Water Ball, Earth Quake, Fiery Flash!, Tsunami, Reformulate, Accretion
   - **Satchel Deck (8 Alc' cards)**: Lightning Storm (Wind), Accumulation (Dark), Giant Shield (Light), Future Vision (Earth), Mortar and Pestle (Earth), Enflame (Fire), Restore (Water), Ring Of Fire (Fire)
   - Set spell_element for all element-based cards
   - Set alchemy_ingredients for all Alc' cards

5. **Implement Kevin-Specific Status Effects**
   - Ring of Fire (buff): Counter-attack when damaged
   - (Leverage other status effects from previous phases)

6. **Testing**
   - Full game loop with Kevin vs minions/boss
   - Test Alchemy card play flow
   - Test ingredient discarding
   - Test Satchel UI
   - Test all 24 Kevin cards
   - Multiplayer: Fabio + Enrique + Kevin

**Files Modified**:
- NEW: `scripts/alchemy_system.gd` (Alchemy logic)
- NEW: `scenes/ui/satchel_panel.tscn` (Kevin's Satchel UI)
- NEW: `scripts/ui/satchel_panel.gd`
- MODIFY: `scripts/character.gd` - Add satchel_deck
- MODIFY: `scripts/card.gd` - Add spell_element, alchemy properties
- MODIFY: `scripts/data/heroes_data.gd` - Add Kevin + satchel_deck
- MODIFY: `scripts/hero_database.gd` - Load satchel_deck
- MODIFY: `scripts/card_database.gd` - Add 24 cards
- MODIFY: `scripts/combat.gd` - Alchemy card play logic
- MODIFY: `scripts/ui/card_visual.gd` - Show element icons
- MODIFY: `scripts/ui/card_hand_display.gd` - Integrate Satchel panel

---

### Phase 4: Remaining Status Effects & Polish

**Tasks**:
1. **Implement Remaining Status Effects**
   - Wet (debuff): Stack counter, card interactions
   - Famished Beast (debuff): Force discard 2 cards at turn start
   - Venom (debuff): Stack counter, instant kill at 3 stacks
   - Scared (debuff): Cannot play ATTACK cards
   - Hinder (debuff): One-turn weakness
   - Exhausted (debuff): Cannot play ANY cards
   - Acquisition (debuff): Exhaust top card of deck

2. **Conditional Damage System**
   - Add `conditional_damage` property to Card class
   - Implement condition checking logic
   - Update card UI to display conditional damage
   - Auto-calculate and apply bonuses during card play

3. **Turn 2 Damage System**
   - Add `turn_2_damage` property to Card class
   - Add `delayed_damage_effects: Array[Dictionary]` to Character class
   - Implement delayed damage application at turn start
   - Update combat log to show delayed damage triggers

4. **UI Polish**
   - Status effect icons on player panels
   - Tooltips for status effects
   - Aura display for Enrique
   - Satchel panel for Kevin
   - Passive ability indicators
   - v2 card choice modal polish

5. **Balance Testing**
   - Test all 3 characters vs minions/boss
   - Multiplayer testing with all combinations
   - Adjust card values if needed

6. **Documentation Update**
   - Update `docs/HOW_TO_ADD_CARD.md` with new properties
   - Update `.claude/CLAUDE.md` with new systems
   - Document Kevin's final Alchemy design choice

**Files Modified**:
- MODIFY: `scripts/card.gd` - Add conditional_damage, turn_2_damage
- MODIFY: `scripts/character.gd` - Add delayed_damage_effects
- MODIFY: `scripts/combat.gd` - Implement all status effects
- MODIFY: `scripts/game_manager.gd` - Turn start/end processing
- MODIFY: `scripts/ui/player_panel.gd` - All status effect icons
- MODIFY: `docs/HOW_TO_ADD_CARD.md`
- MODIFY: `.claude/CLAUDE.md`

---

### Phase 5: Remove Old Heroes (Final)

**Tasks**:
1. Remove old 6 heroes from `scripts/data/heroes_data.gd`
2. Remove old hero cards from `scripts/card_database.gd` (if exclusive to old heroes)
3. Update character selection UI if needed
4. Final testing with only Fabio, Enrique, Kevin

**Testing**: Full multiplayer game loop with new characters only.

---

## Card List by Character

### Fabio's Cards (26 Total)

#### Base Deck (9 cards)
1. **Slash** - Basic attack
2. **Big Smack** - Heavy damage
3. **Duel Purpose** - Multi-effect
4. **Rest** - Heal/recover (shared with Kevin)
5. **Bulk Up** - Gain Invigorated + Fatigued
6. **"Dig a Hole"** - Defensive ability
7. **Protector** - Redirect damage to self
8. **Protective Footwear** - Shield ability
9. **Hunter's Instinct** - Conditional bonus

#### Reward Cards (17 cards)
10. **Medkit** - Strong heal
11. **Dual Wield** - Attack twice
12. **Circular Strike** - Multi-target attack
13. **Cursed Dagger** - High damage, drawback (Rare)
14. **Jumping Strike** - Turn 2 damage
15. **Execution** - Conditional high damage
16. **Frenzy!** - Multi-hit attack
17. **Weak Point!** - Armor bypass
18. **Fighter's Spirit** (v1) - Discard for benefit
19. **Fighter's Spirit** (v2) - Gain 5 shield
20. **Sacrifice** - Self-damage for ally benefit
21. **Leader** (v1) - Give 2 cards to allies
22. **Leader** (v2) - Give 1 card to ally
23-26. (Additional cards from CSV to be detailed during implementation)

### Enrique's Cards (20 Total)

#### Base Deck (8 cards)
1. **Focused Purge** - Attack with condition
2. **Holy Plight** - Damage + effect
3. **Humble Request** - Support ability
4. **Divine Reflection** - Defensive ability
5. **Healing Aura** - AoE heal
6. **Magical Purge** - Cleanse debuffs
7. **Story Of Jacob** - Card draw + effect
8. **Protection** - Grant shield to ally

#### Reward Cards (12 cards)
9. **Divine Force** (v1) - Heal ally + Decay
10. **Divine Force** (v2) - Deal 6 damage to enemy
11. **Purging Water** - Cleanse + heal
12. **Divine Barrier** - Large shield with Aura cost
13. **Refuge** - Prevent damage
14. **Gift** - Give cards to allies
15. **Divine Gift** - Strong support effect
16. **Guy with Beard** - (Effect TBD from CSV)
17-20. (Additional cards from CSV to be detailed during implementation)

### Kevin's Cards (24 Total)

#### Main Deck (16 cards)

**Basic/Common (4 cards):**
1. **Poke** - Basic attack
2. **Meditate** - Draw cards (shared with Enrique)
3. **Rest** - Heal/recover (shared with Fabio)
4. **Fetal Position** - Shield skill

**Spell Cards (7 cards):**
5. **Fire Smash** (Fire) - Fire damage
6. **Water Ball** (Water) - Water damage
7. **Earth Quake** (Earth) - Earth damage
8. **Fiery Flash!** (Fire) - Fast fire attack
9. **Tsunami** (Water) - AoE water attack
10-11. (Additional spell cards from CSV)

**Support (2 cards):**
12. **Reformulate** - Manipulate hand/deck
13. **Accretion** - Build up effect

#### Satchel Deck (8 Alc' cards)
14. **Lightning Storm** (Alc' Wind) - Requires Wind discard
15. **Accumulation** (Alc' Dark) - Requires Dark discard (Rare)
16. **Giant Shield** (Alc' Light) - Requires Light discard
17. **Future Vision** (Alc' Earth) - Reveal boss cards, requires Earth discard
18. **Mortar and Pestle** (Alc' Earth) - Requires Earth discard
19. **Enflame** (Alc' Fire) - Requires Fire discard
20. **Restore** (Alc' Water) - Requires Water discard
21. **Ring Of Fire** (Alc' Fire) - Apply Ring of Fire buff, requires Fire discard

---

## Enemy Cards (Not Implemented This Phase)

**Note**: Enemy cards are being skipped for now. Focus is on playable characters only.

**19 Enemy Cards** from CSV:
- Alex (Wolf): Bite
- Swarm of Racoons: Bone-Crushing Bite!, Swarm!
- Giant MOOSE!: Charge!, Stomp!, Roar!, Forage
- Brock/Mommy/Trogdor: Punch!, Brawl, Vulnerable Approach, Angwy Punch
- Mr. 67 (Bodybuilder): Big Punch, Gut Punch, Protein Shake, Muscle Shield, Flexing
- Giant Centipede/Spider-Queen: Venemous Bite, Beastly Chomp, Poison Cloud, Reinforcement, Entangle
- Wendigo/The Amalgamation: Rend, Scary Face
- Mute: Ravage, Black Surge, Instantiation, Hex: Famished Beast, Hex: Acquisition

**Future Work**: Implement enemy AI to use these cards.

---

## Kevin's Alchemy System - Design Options

**Decision Required**: Choose one of these 3 designs during Phase 3 (Kevin implementation).

### Option A: Discard-to-Play (Recommended)

**How It Works**:
1. Kevin has 2 decks: Main deck (16 cards) + Satchel deck (8 Alc' cards)
2. Satchel deck is visible in a separate UI panel during combat
3. To play an Alc' card from Satchel:
   - Card has "ingredient requirements" (e.g., "Requires 1 Wind spell")
   - Player must have required element spell cards in hand
   - Player selects Alc' card → System prompts to discard ingredients → Card plays
4. Alc' cards are more powerful than normal cards (balanced by ingredient cost)

**CSV Evidence**:
- CSV has columns: `Alc Water Discard`, `Alc Earth Discard`, `Alc Fire Discard`
- Example: "Lightning Storm" has `Alc Wind Discard = 1` (discard 1 Wind spell)

**Pros**:
- Clear resource trade-off (discard weak spells for strong Alc' card)
- Matches CSV column names exactly
- Encourages strategic hand management
- Satchel cards are always available (not shuffled in deck)

**Cons**:
- Requires extra UI for Satchel panel
- More complex card play flow
- Kevin's hand can get clogged with element spells

**Implementation Complexity**: Medium

---

### Option B: Resource System

**How It Works**:
1. Kevin has 6 resource pools: Water, Fire, Earth, Wind, Light, Dark
2. When Kevin plays a spell card with an element, he gains 1 of that resource
3. Resources persist between turns (or reset each turn - TBD)
4. To play an Alc' card, spend required resources (e.g., 2 Fire resources)
5. Alc' cards are shuffled into main deck or kept in separate Satchel

**Example**:
- Play "Fire Smash" → Gain 1 Fire resource
- Play "Fiery Flash!" → Gain 1 Fire resource (now have 2 Fire)
- Play "Enflame (Alc' Fire)" → Spend 2 Fire resources

**Pros**:
- Familiar to card game players (mana system)
- Simpler hand management (no discarding)
- Can bank resources across turns for big plays

**Cons**:
- Doesn't match CSV column names ("Discard")
- Requires resource tracking UI
- Less direct connection between spells and Alc' cards

**Implementation Complexity**: Medium

---

### Option C: Combo System

**How It Works**:
1. Kevin's Alc' cards start in a separate "locked" Satchel
2. When Kevin plays specific spell combinations in one turn, Alc' cards unlock
3. Unlocked Alc' cards are added to hand or become playable that turn
4. Example: Play 2 Fire spells in one turn → Unlock "Enflame" from Satchel

**Trigger Examples**:
- Play 2 Fire spells → Unlock all Fire Alc' cards
- Play 1 Fire + 1 Water spell → Unlock Steam-based Alc' card
- Play 3 spells of any element → Unlock powerful multi-element Alc' card

**Pros**:
- Rewards skilled play and sequencing
- Creates exciting "combo turns"
- No resource tracking needed

**Cons**:
- Doesn't match CSV columns at all
- Hard to balance (combos can be too easy or too hard)
- Less predictable (RNG if you draw the right spells)

**Implementation Complexity**: High (requires combo detection system)

---

## Technical Notes

### Backward Compatibility

- Old 6 heroes will remain in `heroes_data.gd` during Phases 1-4
- Old hero cards will remain in `card_database.gd`
- Stamina renaming is backward compatible (just renamed property)
- New status effects default to 0 (won't affect old heroes)
- Phase 5 removes old heroes after testing is complete

### Multiplayer Considerations

- All new systems must sync across clients (Aura, Satchel, passive abilities)
- v2 card choice modal must show on all clients (spectator mode)
- Status effects must sync in character state dictionaries
- Passive abilities must trigger correctly for all players

### Performance

- 89 new cards should not impact performance (existing system handles 100+ cards fine)
- Satchel deck is small (8 cards), negligible UI impact
- Status effect checking should be optimized (check only active effects)

### UI Space

- Player panel needs space for: HP, Stamina, Aura (Enrique), Status effects, Passive indicator
- Card display needs space for: Cost (Stamina + Aura), Element icon, Conditional damage text
- New UI elements: Satchel panel (Kevin), Passive modal (Fabio), v2 choice modal (all)

---

## Verification & Testing

### Per-Phase Testing

**Phase 0 (Stamina Rename + v2 System)**:
- [ ] All old heroes work with renamed Stamina
- [ ] v2 card choice modal appears correctly
- [ ] v2 card effects apply based on player choice
- [ ] Multiplayer: All clients see v2 choice results

**Phase 1 (Fabio)**:
- [ ] Fabio appears in character selection
- [ ] Fabio's passive modal appears during action phase
- [ ] Passive can be used once per turn (resets correctly)
- [ ] All 3 passive effects work (damage, draw, shield)
- [ ] All 26 Fabio cards play correctly
- [ ] v2 cards (Fighter's Spirit, Leader) work
- [ ] Status effects (Rested, Invigorated, Fatigued, DamagePlus) work
- [ ] Full game loop: Fabio vs minions → boss
- [ ] Multiplayer: 3 Fabios can play together

**Phase 2 (Enrique)**:
- [ ] Enrique appears in character selection
- [ ] Aura generates at start of turn (+1)
- [ ] Aura displays on player panel
- [ ] Aura cost shown on cards
- [ ] Aura cost checked when playing cards
- [ ] Aura resets to 0 after each fight
- [ ] Decay blocks healing correctly
- [ ] All 20 Enrique cards play correctly
- [ ] v2 card (Divine Force) works
- [ ] Full game loop: Enrique vs minions → boss
- [ ] Multiplayer: Fabio + Enrique + old hero

**Phase 3 (Kevin)**:
- [ ] Kevin appears in character selection
- [ ] Satchel deck loads correctly (8 Alc' cards)
- [ ] Satchel UI panel displays Alc' cards
- [ ] Spell elements display on cards
- [ ] Ingredient requirements check correctly
- [ ] Alc' card play flow works (discard → play)
- [ ] All 24 Kevin cards play correctly
- [ ] Full game loop: Kevin vs minions → boss
- [ ] Multiplayer: Fabio + Enrique + Kevin

**Phase 4 (Polish)**:
- [ ] All status effects work correctly
- [ ] Conditional damage displays and calculates correctly
- [ ] Turn 2 damage applies at correct time
- [ ] Status effect icons display on player panels
- [ ] Tooltips explain status effects
- [ ] UI polish complete (no visual bugs)

**Phase 5 (Remove Old Heroes)**:
- [ ] Only Fabio, Enrique, Kevin appear in character selection
- [ ] Full game loop with new heroes only
- [ ] Multiplayer: All combinations work

### Final Acceptance Testing

**Full Game Loop**:
1. Character selection: Choose Fabio, Enrique, Kevin
2. First minion fight: All characters work, all cards playable
3. Buff selection: Works correctly
4. Boss phase 1: All characters work, all systems function
5. Boss phase 2: Continues correctly
6. Wizard reward: Works correctly
7. Second minion fight: All characters work
8. Victory: Game completes

**Multiplayer**:
- 3 Fabios
- 3 Enriques
- 3 Kevins
- 1 Fabio + 1 Enrique + 1 Kevin
- All combinations play full game loop without errors

**Edge Cases**:
- Venom reaches 3 stacks (instant kill)
- Exhausted status (cannot play cards)
- Aura at high values (10+)
- Kevin with no element spells in hand
- Fabio uses passive 2+ times in one turn (should prevent)
- v2 card choice canceled/backed out

---

## File Structure Reference

### New Files to Create

```
scripts/
├── passive_ability.gd              # PassiveAbility resource class
├── passive_ability_manager.gd      # Passive ability logic (autoload)
├── alchemy_system.gd               # Kevin's Alchemy logic
└── ui/
    ├── card_v2_choice_modal.gd     # v2 card choice UI logic
    ├── passive_ability_modal.gd    # Fabio's passive choice UI
    └── satchel_panel.gd            # Kevin's Satchel display

scenes/
└── ui/
    ├── card_v2_choice_modal.tscn   # v2 card choice scene
    ├── passive_ability_modal.tscn  # Passive ability scene
    └── satchel_panel.tscn          # Satchel panel scene
```

### Existing Files to Modify

```
scripts/
├── character.gd                    # Add: aura, satchel_deck, passive properties, status effects
├── card.gd                         # Add: aura_cost, spell_element, alchemy properties, v2 properties
├── card_database.gd                # Add: 89 new cards
├── hero_database.gd                # Load satchel_deck
├── combat.gd                       # Implement new mechanics logic
├── game_manager.gd                 # Aura generation, passive triggers, status effects
├── data/
│   └── heroes_data.gd              # Add: Fabio, Enrique, Kevin (later remove old 6)
└── ui/
    ├── card_visual.gd              # Display: aura cost, elements, conditional damage
    ├── card_hand_display.gd        # Integrate: Satchel panel, v2 choice
    └── player_panel.gd             # Display: Aura, status effects, passive indicator
```

---

## Risk Mitigation

### High-Risk Areas

1. **Multiplayer Sync**: New systems (Aura, Satchel, passives) must sync correctly
   - Mitigation: Test multiplayer thoroughly after each phase
   - Use existing RPC patterns from game_manager.gd

2. **v2 Card Choice UI**: Modal must work across multiplayer
   - Mitigation: Implement in Phase 0 before character work
   - Test with all clients watching choice

3. **Kevin's Alchemy System**: Most complex new system
   - Mitigation: Implement last (Phase 3), design carefully
   - Choose simplest viable option if time constrained

4. **Status Effect Interactions**: 15 new status effects may have edge cases
   - Mitigation: Implement incrementally, test thoroughly
   - Document all status effect interactions in code comments

5. **Energy → Stamina Rename**: Risk of missing references
   - Mitigation: Use global search-and-replace, test old heroes
   - Do this first (Phase 0) so all later work uses correct terminology

### Rollback Plan

- Each phase is independent (can stop after any phase)
- Old heroes remain available until Phase 5
- Git commits after each completed phase
- If major blocker occurs, can revert to previous phase

---

## Questions for Later

**Deferred to Implementation**:
1. Kevin's Alchemy: Which of the 3 designs? (Decide in Phase 3)
2. Aura maximum cap: Should Enrique have a max Aura limit? (Default: no cap)
3. Status effect stacking limits: Should stacks have maximums? (Default: no limit)
4. Satchel UI placement: Above hand, side panel, or popup? (Design in Phase 3)
5. Boss Card Reveal (Future Vision): How many cards to reveal? (Implement in Phase 3)
6. "Played Twice" mechanic: Execute effect twice, or play card twice? (Clarify during implementation)
7. Card rarity system: Do rare cards (Cursed Dagger, Accumulation) have special drop rates? (Later)
8. Enemy cards AI: When/how to implement? (Post-Phase 5)

---

## Appendix: CSV Data Samples

### Character Data (from new-character-info.csv)

```csv
Name,Max Stamina,HP,Passive Ability
Fabio,2,50,"Choice each turn: deal 2 damage to boss, draw 1 card, OR give 3 shield to target player"
Kevin,2,40,"Alchemy system - can add Alc' cards from Satchel to hand by discarding Spell cards as ingredients"
Enrique,2,30,"Has Aura resource, gains 1 aura at start of every turn"
```

### Status Effects Data (from buffs-and-debuffs.csv)

```csv
name,system,Stackable?,Description
Wet,,1,"debuff itself does nothing, creates stack on player that have interaction with cards"
Venom,,1,"This debuff is stackable, when the player has 3 Venom their Health is reduced to 0."
Rested,,1,"Gain +1 stamina at the start of your turn, removed after stamina from buff added"
Invincible,invulnerability,0,"Take no damage this turn, buff is removed at the end of the turn."
```

---

**End of Specification**

This document will be updated as implementation progresses. Refer to git commit messages and `.claude/CLAUDE.md` for implementation-specific notes.
