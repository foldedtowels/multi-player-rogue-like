# Deck Masters Roguelike

A multiplayer team-based deck building roguelike game built in Godot 4, inspired by Magic: The Gathering mechanics.

## Game Overview

Deck Masters is a cooperative card game where 3 players team up to defeat 5 increasingly difficult bosses. Each player chooses from 6 unique heroes, each with their own themed deck and playstyle. The game features turn-based combat where all players take their turns, followed by the boss's turn.

## Heroes (6 Playable Characters)

### 1. Pyra, Flame Wielder
- **Health:** 90 HP
- **Energy:** 3
- **Playstyle:** Aggressive burn damage and direct attacks
- **Signature Cards:** Lightning Bolt, Fireball, Burning Hands
- **Theme:** Red mage inspired by MTG burn spells

### 2. Selene, Life Weaver
- **Health:** 110 HP
- **Energy:** 3
- **Playstyle:** Healing and protective support
- **Signature Cards:** Divine Light, Mass Heal, Guardian Shield
- **Theme:** White/green healer with buffs and protection

### 3. Nyx, Shadow Assassin
- **Health:** 85 HP
- **Energy:** 3
- **Playstyle:** Life drain and poison damage over time
- **Signature Cards:** Doom Blade, Drain Life, Assassination
- **Theme:** Black removal and life steal mechanics

### 4. Zephyr, Storm Caller
- **Health:** 95 HP
- **Energy:** 3
- **Playstyle:** Control and card advantage
- **Signature Cards:** Chain Lightning, Storm Surge, Arcane Intellect
- **Theme:** Blue control with card draw and lightning

### 5. Thorne, Beast Tamer
- **Health:** 120 HP
- **Energy:** 3
- **Playstyle:** Primal strength and regeneration
- **Signature Cards:** Giant Growth, Stampede, Primal Rage
- **Theme:** Green creature power and growth

### 6. Kairos, Chrono Mage
- **Health:** 100 HP
- **Energy:** 3
- **Playstyle:** Time manipulation and tempo control
- **Signature Cards:** Time Warp, Blink, Chrono Blast
- **Theme:** Blue/white time magic with card advantage

## Bosses (5 Escalating Encounters)

### Boss 1: Corrupted Treant
- **Health:** 200 HP
- **Energy:** 2
- **Difficulty:** Easy
- **Mechanics:** Basic attacks and minor armor

### Boss 2: Flame Warlord
- **Health:** 280 HP
- **Energy:** 3
- **Difficulty:** Medium
- **Mechanics:** Strong attacks with burn damage

### Boss 3: Lich Summoner
- **Health:** 350 HP
- **Energy:** 3
- **Difficulty:** Hard
- **Mechanics:** Life drain, poison, and healing

### Boss 4: Storm Dragon
- **Health:** 450 HP
- **Energy:** 4
- **Difficulty:** Very Hard
- **Mechanics:** Powerful AoE attacks, high armor

### Boss 5: Void Titan
- **Health:** 600 HP
- **Energy:** 4
- **Difficulty:** Final Boss
- **Mechanics:** Piercing damage, massive debuffs, reality-bending powers

## Game Mechanics

### Card System
- **Energy Cost:** Cards require energy to play (1-3 energy)
- **Card Types:** Attack, Spell, Buff, Debuff, Heal
- **Target Types:** Self, Single Ally, All Allies, Single Enemy, All Enemies

### Status Effects
- **Poison:** Damage over time that decreases each turn
- **Burn:** Damage over time that persists
- **Strength:** Increases damage dealt
- **Vulnerable:** Take 50% more damage
- **Weakness:** Deal less damage
- **Armor:** Reduces incoming damage
- **Shield:** Temporary HP that resets each turn

### Special Mechanics
- **Piercing:** Ignores armor and shield
- **Lifesteal:** Heal for damage dealt
- **Multi-hit:** Apply effects multiple times
- **AoE:** Affects all enemies

## Game Loop

1. **Character Selection:** Players choose 3 heroes from the 6 available
2. **Combat Round:**
   - Player 1 takes their turn (play cards, end turn)
   - Player 2 takes their turn
   - Player 3 takes their turn
   - Boss takes their turn (AI controlled)
3. **Repeat** until boss is defeated or all players die
4. **Progress** to next boss or receive rewards
5. **Victory** after defeating all 5 bosses

### Turn Structure
- Start of turn: Gain full energy, apply status effects, draw 5 cards
- Play cards by spending energy
- Select targets for single-target cards
- End turn: Discard hand, lose shield, decay some status effects

## How to Play

1. Open the project in Godot 4.3 or later
2. Run the project (F5)
3. Select 3 heroes from the character selection screen
4. In combat:
   - Click cards in your hand to play them
   - Click enemies or allies to target them (when required)
   - Click "End Turn" when done
5. Defeat all 5 bosses to win!

## File Structure

```
deck-masters-roguelike/
├── scenes/
│   ├── main_menu.tscn          # Main menu scene
│   ├── character_selection.tscn # Hero selection screen
│   ├── combat.tscn              # Main combat scene
│   └── card_visual.tscn         # Card display component
├── scripts/
│   ├── card.gd                  # Card resource definition
│   ├── character.gd             # Character/player resource
│   ├── card_database.gd         # All card definitions (autoload)
│   ├── hero_database.gd         # Hero definitions (autoload)
│   ├── boss_database.gd         # Boss definitions (autoload)
│   ├── game_manager.gd          # Turn management (autoload)
│   ├── main_menu.gd             # Main menu controller
│   ├── character_selection.gd   # Hero selection logic
│   ├── combat.gd                # Combat UI controller
│   └── card_visual.gd           # Card visual component
├── project.godot                # Godot project file
└── README.md                    # This file
```

## Future Enhancements

Potential features to add:
- Deck building between encounters
- Card rewards after boss fights
- Upgraded/rare cards
- More heroes and bosses
- Persistent progression
- Multiplayer networking
- Animations and visual effects
- Sound effects and music
- Relics/artifacts system
- Different difficulty modes

## Credits

Inspired by:
- Magic: The Gathering (card mechanics)
- Slay the Spire (roguelike deck building)
- Monster Train (cooperative deck building)

Built with Godot 4.3
