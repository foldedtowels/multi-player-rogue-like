# Design Notes - Deck Masters Roguelike

## MTG-Inspired Mechanics

This game draws heavily from Magic: The Gathering's color pie philosophy:

### Color Pie Mapping

**Red (Pyra, Flame Wielder)**
- Direct damage
- Fast aggression
- Burn effects (damage over time)
- Low health, high damage output
- Inspired by: Lightning Bolt, Fireball, Shock

**White/Green (Selene, Life Weaver)**
- Healing and life gain
- Protection and shields
- Buffs and enhancements
- High health pool
- Inspired by: Healing Salve, Pacifism, Divine Light

**Black (Nyx, Shadow Assassin)**
- Life drain mechanics
- Poison/damage over time
- Removal spells
- Risk/reward mechanics (Dark Pact)
- Inspired by: Doom Blade, Drain Life, Corrupt

**Blue (Zephyr, Storm Caller)**
- Card draw and advantage
- Control and debuffs
- Efficient spells
- Vulnerable effects
- Inspired by: Counterspell, Divination, Lightning Strike

**Green (Thorne, Beast Tamer)**
- Highest health pool
- Strength buffs
- Regeneration
- Armor mechanics
- Inspired by: Giant Growth, Regrowth, Stampede

**Blue/White (Kairos, Chrono Mage)**
- Tempo advantage
- Card draw
- Time manipulation theme
- Balanced offense/defense
- Inspired by: Time Walk, Blink, Rewind

## Team Synergies

### Recommended Team Compositions

**Balanced Team:**
- Selene (Healer)
- Pyra (Damage)
- Thorne (Tank)
Strategy: Thorne absorbs damage, Selene keeps everyone alive, Pyra burns down the boss

**Aggressive Team:**
- Pyra (Burn)
- Nyx (Poison)
- Zephyr (Lightning)
Strategy: Stack damage over time effects, finish with direct damage

**Control Team:**
- Zephyr (Card Draw)
- Kairos (Tempo)
- Selene (Healing)
Strategy: Outlast the boss with card advantage and healing

**DoT Team:**
- Nyx (Poison)
- Pyra (Burn)
- Thorne (Sustain)
Strategy: Stack poison and burn, tank through the damage

## Boss Strategy Guide

### Boss 1: Corrupted Treant (200 HP)
- Tutorial boss
- Low energy, simple attacks
- Strategy: Learn basic mechanics, practice card combos

### Boss 2: Flame Warlord (280 HP)
- Applies burn damage
- Uses shields
- Strategy: Bring healing, use piercing damage
- Counter: Life Weaver's heals, Shadow Assassin's piercing

### Boss 3: Lich Summoner (350 HP)
- Life drain mechanics
- Applies poison
- Strategy: Burst damage before he heals too much
- Counter: Flame Wielder's high damage, armor to reduce poison

### Boss 4: Storm Dragon (450 HP)
- AoE damage
- High armor
- Vulnerable effects
- Strategy: Use piercing damage, focus healing all allies
- Counter: Piercing attacks (Assassination, Volcanic Strike, Smite)

### Boss 5: Void Titan (600 HP)
- Piercing damage (ignores shields)
- Multiple debuffs
- Highest HP pool
- Strategy: High HP heroes, strong healing, remove debuffs quickly
- Counter: Beast Tamer's high HP, Life Weaver's mass healing

## Card Tier List

### S-Tier Cards
- **Time Warp** (3 energy, draw 3): Massive card advantage
- **Mass Heal** (3 energy, heal 20 all): Best group heal
- **Assassination** (3 energy, 25 piercing): Highest single-target damage
- **Fireball** (3 energy, 15 AoE): Best AoE for the cost

### A-Tier Cards
- **Lightning Bolt** (1 energy, 12 damage): Best damage-to-cost ratio
- **Drain Life** (2 energy, 12 + lifesteal): Damage + healing
- **Giant Growth** (1 energy, +4 strength): Best buff
- **Divination** (2 energy, draw 2): Solid card advantage

### B-Tier Cards
- Most other cards provide good value for cost

### Situational Cards
- **Dark Pact**: High risk, high reward (lose 5 HP, gain 4 strength)
- **Primal Rage**: Similar trade-off (gain strength, become vulnerable)

## Game Balance Notes

### Energy Economy
- Most cards cost 1-2 energy
- Big effects (AoE, major heals) cost 3 energy
- Starting energy: 3 for heroes, 2-4 for bosses
- Bosses gain more energy as difficulty increases

### Damage Scaling
- Early game: 8-12 damage per card
- Mid game: 10-16 damage per card
- Late game: 15-25 damage per card
- Boss HP scales faster than player damage (requires strategy)

### Status Effect Values
- Poison/Burn: 3-5 per application
- Strength: 3-4 per buff
- Vulnerable: 50% damage increase (2 turns)
- Armor: 2-5 reduction per turn

## Difficulty Curve

The game is designed so that:
1. Boss 1: Can be beaten with any team, no strategy needed
2. Boss 2: Requires basic healing or damage focus
3. Boss 3: Requires team coordination
4. Boss 4: Requires understanding of piercing mechanics
5. Boss 5: Requires optimal card play and team synergy

Players should expect to lose their first few runs as they learn boss patterns and card synergies.

## Future Balance Considerations

If implementing card rewards between fights:
- Limit AoE cards (too strong with multiples)
- Limit card draw (can break the game)
- Add deck size considerations
- Consider card upgrade mechanics (inspired by Slay the Spire)

## Multiplayer Considerations

Current design assumes 3 human players taking turns at same computer.

For online multiplayer:
- Add turn timer (30-60 seconds)
- Add chat/emotes
- Consider simultaneous play with resolution phase
- Add reconnection handling

For single player:
- AI for 2 other heroes
- Simplified AI: prioritize healing low HP allies, attack boss with damage cards
- Could make the game easier/different feel
