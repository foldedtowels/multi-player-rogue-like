# How to Add a New Card

This guide explains how to add new cards to the game's card database.

## Quick Summary

Adding a new card requires **ONE FILE EDIT**:
1. Add card definition to `scripts/card_database.gd` in the `_create_all_cards()` function

The card will automatically be available for heroes and bosses to use.

---

## Understanding Card Parameters

Cards are created using the `create_card()` factory function:

```gdscript
create_card(name, description, card_type, target_type, cost, dmg, heal, shield, draw)
```

### Parameter Reference

| Parameter | Type | Description | Example Values |
|-----------|------|-------------|----------------|
| `name` | String | Display name on card | `"Lightning Bolt"`, `"Heal"` |
| `description` | String | Flavor text | `"A quick jolt of energy"` |
| `card_type` | Enum | Card category | `ATTACK`, `SPELL`, `BUFF`, `DEBUFF`, `HEAL` |
| `target_type` | Enum | Who can be targeted | `SELF`, `SINGLE_ENEMY`, `ALL_ENEMIES` |
| `cost` | Int | Energy to play | `0`, `1`, `2`, `3`, `4`, `5` |
| `dmg` | Int | Base damage dealt | `0`, `8`, `12`, `20` |
| `heal` | Int | HP restored | `0`, `5`, `10` (negative = self-harm) |
| `shield` | Int | Temporary HP | `0`, `8`, `15` |
| `draw` | Int | Cards drawn | `0`, `1`, `2`, `3` |

### Card Types

- **ATTACK**: Direct damage cards (red)
- **SPELL**: Utility or multi-effect cards (yellow)
- **BUFF**: Positive effects on allies (green)
- **DEBUFF**: Negative effects on enemies (purple)
- **HEAL**: Healing and recovery (blue)

### Target Types

- **SELF**: Only targets the caster
- **SINGLE_ALLY**: Choose one friendly character
- **SINGLE_ENEMY**: Choose one enemy
- **RANDOM_ENEMY**: Automatically targets random enemy
- **ALL_ALLIES**: Affects all friendly characters
- **ALL_ENEMIES**: Affects all enemies

---

## Basic Card Examples

### Example 1: Simple Damage Card

```gdscript
all_cards["fireball"] = create_card(
	"Fireball",                      # name
	"Explosive power.",              # description
	Card.CardType.ATTACK,            # card_type
	Card.TargetType.SINGLE_ENEMY,    # target_type
	2,                                # cost = 2 energy
	15,                               # dmg = 15 damage
	0,                                # heal = no healing
	0,                                # shield = no shield
	0                                 # draw = no card draw
)
```

### Example 2: Healing Card

```gdscript
all_cards["healing_salve"] = create_card(
	"Healing Salve",
	"Restore health to an ally.",
	Card.CardType.HEAL,
	Card.TargetType.SINGLE_ALLY,
	1,    # cost = 1 energy
	0,    # dmg = no damage
	10,   # heal = restore 10 HP
	0,    # shield = no shield
	0     # draw = no card draw
)
```

### Example 3: Shield Card

```gdscript
all_cards["guardian_shield"] = create_card(
	"Guardian Shield",
	"Protective barrier.",
	Card.CardType.BUFF,
	Card.TargetType.SELF,
	1,    # cost = 1 energy
	0,    # dmg = no damage
	0,    # heal = no healing
	12,   # shield = gain 12 shield
	0     # draw = no card draw
)
```

### Example 4: Card Draw

```gdscript
all_cards["arcane_intellect"] = create_card(
	"Arcane Intellect",
	"Draw knowledge from the aether.",
	Card.CardType.SPELL,
	Card.TargetType.SELF,
	1,    # cost = 1 energy
	0,    # dmg = no damage
	0,    # heal = no healing
	0,    # shield = no shield
	2     # draw = draw 2 cards
)
```

---

## Advanced Properties

After calling `create_card()`, you can add advanced effects by setting properties on the returned Card object.

### Status Effects

```gdscript
# Apply burn (damage per turn, permanent)
all_cards["burning_hands"] = create_card(...)
all_cards["burning_hands"].apply_burn = 5  # Deal 5 burn per turn

# Apply poison (damage per turn, decays by 1 each turn)
all_cards["poison_strike"] = create_card(...)
all_cards["poison_strike"].apply_poison = 3  # Deal 3 poison, decays

# Apply vulnerable (increases damage taken by 50%)
all_cards["expose_weakness"] = create_card(...)
all_cards["expose_weakness"].apply_vulnerable = 2  # 2 turns of vulnerable

# Apply weakness (reduces damage dealt)
all_cards["enfeeble"] = create_card(...)
all_cards["enfeeble"].apply_weakness = 2  # 2 turns of weakness

# Apply strength (increases damage dealt permanently)
all_cards["battle_rage"] = create_card(...)
all_cards["battle_rage"].apply_strength = 3  # +3 damage to all attacks

# Apply armor (permanent damage reduction)
all_cards["steel_skin"] = create_card(...)
all_cards["steel_skin"].apply_armor = 2  # Reduce all damage by 2
```

### Special Mechanics

```gdscript
# Lifesteal: Heal for damage dealt
all_cards["drain_life"] = create_card(...)
all_cards["drain_life"].lifesteal = true

# Piercing: Ignores shield and armor
all_cards["piercing_shot"] = create_card(...)
all_cards["piercing_shot"].piercing = true

# AoE damage: Hits all targets instead of one
all_cards["meteor"] = create_card(..., Card.TargetType.ALL_ENEMIES, ...)
all_cards["meteor"].aoe_damage = true
```

---

## Step-by-Step: Adding a Card

### Step 1: Design the Card

Decide on:
- **Purpose**: What does this card do? (damage, heal, buff, etc.)
- **Cost**: How much energy? (1-3 for commons, 4-5 for rares)
- **Power Level**: How strong should it be?
- **Target**: Who does it affect?

**Balance Guidelines**:
| Cost | Damage | Heal | Shield |
|------|--------|------|--------|
| 0 | 3-5 | 3-5 | 3-5 |
| 1 | 8-12 | 6-10 | 8-12 |
| 2 | 14-18 | 10-15 | 12-18 |
| 3 | 20-25 | 15-20 | 20-25 |

### Step 2: Open card_database.gd

Navigate to `scripts/card_database.gd` and find the `_create_all_cards()` function.

### Step 3: Choose a Section

Add your card to the appropriate section:
- **Hero Cards**: Group by hero theme (Flame Wielder, Life Weaver, etc.)
- **Boss Cards**: These are created in boss_database.gd instead
- **Common Cards**: Can be used by multiple heroes

### Step 4: Write the Card Definition

```gdscript
func _create_all_cards():
	# ... existing cards ...

	# === YOUR NEW CARD ===
	all_cards["your_card_id"] = create_card(
		"Your Card Name",
		"Card description explaining what it does.",
		Card.CardType.ATTACK,           # Choose appropriate type
		Card.TargetType.SINGLE_ENEMY,   # Choose appropriate target
		2,   # cost
		15,  # damage
		0,   # heal
		0,   # shield
		0    # draw
	)

	# Add advanced properties if needed
	# all_cards["your_card_id"].piercing = true
	# all_cards["your_card_id"].apply_burn = 3
```

**Important**: The `card_id` (dictionary key) must be:
- Lowercase
- Use underscores, not spaces
- Unique (not already used)

### Step 5: Add to Hero Decks (Optional)

If you want heroes to use this card, add it to their decks in `scripts/data/heroes_data.gd`:

```gdscript
"flame_wielder": {
	"deck": [
		"lightning_bolt",
		"shock",
		"your_card_id",  # Your new card
		# ... other cards
	]
}
```

### Step 6: Test the Card

1. Run the game
2. Select a hero that has your card
3. Play the card and verify:
   - Correct name and description display
   - Energy cost is correct
   - Effects work as intended
   - Visual feedback is appropriate

---

## Complete Example: "Chain Lightning"

Let's create a powerful AoE lightning spell.

### Design

```
Name: Chain Lightning
Type: Attack (AoE)
Cost: 3 energy
Effect: Deal 12 damage to all enemies
Theme: Lightning/Storm magic
```

### Implementation

```gdscript
func _create_all_cards():
	# ... existing cards ...

	# === STORM CALLER CARDS ===
	all_cards["chain_lightning"] = create_card(
		"Chain Lightning",
		"Lightning arcs between all foes.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		3,    # Expensive for AoE
		12,   # Moderate damage per target
		0,    # No healing
		0,    # No shield
		0     # No card draw
	)
	all_cards["chain_lightning"].aoe_damage = true  # Mark as AoE
```

### Add to Hero

```gdscript
# In scripts/data/heroes_data.gd
"storm_caller": {
	"deck": [
		"lightning_strike",
		"lightning_strike",
		"chain_lightning",  # Add here
		# ... other cards
	]
}
```

---

## Advanced Example: Status Effect Combo

### "Venom Strike" - Poison Attack

```gdscript
all_cards["venom_strike"] = create_card(
	"Venom Strike",
	"Poisoned blade that festers over time.",
	Card.CardType.ATTACK,
	Card.TargetType.SINGLE_ENEMY,
	2,    # cost
	8,    # Initial damage (lower because of poison)
	0,    # heal
	0,    # shield
	0     # draw
)
all_cards["venom_strike"].apply_poison = 4  # 4 poison damage over time
```

### "Berserk Rage" - Self-Harm Buff

```gdscript
all_cards["berserk_rage"] = create_card(
	"Berserk Rage",
	"Sacrifice health for overwhelming power.",
	Card.CardType.BUFF,
	Card.TargetType.SELF,
	1,    # cost
	0,    # damage
	-10,  # NEGATIVE heal = lose 10 HP
	0,    # shield
	0     # draw
)
all_cards["berserk_rage"].apply_strength = 5  # Gain +5 damage permanently
```

### "Divine Smite" - Piercing AoE

```gdscript
all_cards["divine_smite"] = create_card(
	"Divine Smite",
	"Holy power that pierces all defenses.",
	Card.CardType.ATTACK,
	Card.TargetType.ALL_ENEMIES,
	4,    # Expensive!
	18,   # High damage
	0,    # heal
	0,    # shield
	0     # draw
)
all_cards["divine_smite"].piercing = true    # Ignores shields/armor
all_cards["divine_smite"].aoe_damage = true  # Hits all enemies
```

---

## Balance Guidelines

### Energy Curve

- **0-1 Energy**: Basic, efficient cards you play every turn
- **2 Energy**: Strong midrange options
- **3+ Energy**: Game-winning power cards

### Damage per Energy

- **1 Energy**: 8-12 damage (single target)
- **2 Energy**: 14-18 damage (single target) OR 8-10 (AoE)
- **3 Energy**: 20-25 damage (single target) OR 12-15 (AoE)

### Status Effects Value

- **Burn/Poison**: Worth ~5-8 damage per stack over time
- **Vulnerable**: Worth ~10-15 value (increases damage taken)
- **Strength**: Worth ~5 damage per stack permanently
- **Shield**: Worth slightly less than damage (8 shield ≈ 10 damage value)

### Testing Checklist

- [ ] Card name and description clear
- [ ] Energy cost balanced for effect
- [ ] Works with appropriate targets
- [ ] Visual feedback appears (damage numbers, particles)
- [ ] Status effects apply correctly
- [ ] No crashes or errors in console
- [ ] Feels fair compared to existing cards

---

## Common Issues

### Issue: Card doesn't appear in deck
**Solution**: Check the card_id spelling when adding to hero deck in heroes_data.gd

### Issue: Card has no effect
**Solution**: Verify you set the correct card_type and target_type. Check console for errors.

### Issue: Status effect doesn't work
**Solution**: Make sure you set the property AFTER calling create_card():
```gdscript
all_cards["burn_card"] = create_card(...)
all_cards["burn_card"].apply_burn = 3  # THIS LINE
```

### Issue: Card too powerful/weak
**Solution**: Adjust cost or effect values. Playtest through multiple boss encounters.

---

## Next Steps

- **Add hero with your cards**: See `HOW_TO_ADD_HERO.md`
- **Understand card mechanics**: See `ARCHITECTURE.md`
- **View all card properties**: Check `scripts/card.gd` resource class
