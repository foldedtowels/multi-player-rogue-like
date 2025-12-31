# How to Add a New Hero

This guide walks you through adding a new playable hero character to the game using the data-driven architecture.

## Quick Summary

Adding a new hero requires **ONE FILE EDIT**:
1. Add hero definition to `scripts/data/heroes_data.gd`

That's it! The HeroDatabase factory will automatically create the hero from your data.

---

## Step-by-Step Guide

### Step 1: Design Your Hero

Before coding, decide on:
- **Name**: Character name (e.g., "Ignis, Flame Mage")
- **Archetype**: Playstyle (tank, healer, damage dealer, support)
- **Max Health**: HP pool (see GameConstants.HERO_MAX_HEALTH for balance)
- **Starting Energy**: Energy per turn (usually 3)
- **Deck Theme**: What type of cards? (fire, poison, healing, etc.)

**Balance Guidelines**:
- **Glass Cannon**: 85-95 HP, high damage cards
- **Balanced**: 95-105 HP, mix of offense and defense
- **Tank**: 110-120 HP, shields and sustain

### Step 2: Plan the Deck

Each hero needs **14-15 cards** for their starting deck.

**Deck Composition Tips**:
- **4-6 Basic Attacks**: Low-cost damage (1 energy, 8-12 damage)
- **2-3 Power Cards**: High-cost finishers (2-3 energy, 14+ damage or big effects)
- **3-4 Defense/Utility**: Shields, heals, or card draw
- **2-3 Synergy Cards**: Cards that work together (e.g., poison + poison damage)

**Important**: All cards must already exist in `scripts/card_database.gd`. If you need custom cards, add them there first (see HOW_TO_ADD_CARD.md).

### Step 3: Add Hero Data

Open `scripts/data/heroes_data.gd` and add a new entry to the `HEROES` dictionary:

```gdscript
const HEROES = {
	# ... existing heroes ...

	"your_hero_id": {
		"name": "Hero Name, The Title",
		"description": "One-line description of playstyle and theme.",
		"max_health": 100,
		"starting_energy": 3,
		"deck": [
			# Basic attacks (4-6 cards)
			"card_id_1",
			"card_id_1",  # Duplicates are allowed
			"card_id_2",
			"card_id_2",

			# Power cards (2-3 cards)
			"powerful_card",
			"finisher_card",

			# Defense/Utility (3-4 cards)
			"shield_card",
			"shield_card",
			"heal_card",

			# Synergy cards (2-3 cards)
			"synergy_card_1",
			"synergy_card_2"
		]
	}
}
```

**Naming Convention**:
- **hero_id**: lowercase_with_underscores (e.g., `"ice_mage"`, `"blood_knight"`)
- **name**: Proper Name, The Title (e.g., `"Frost, Ice Mage"`)

### Step 4: Update Constants (Optional)

If your hero has unique max HP, add it to `scripts/game_constants.gd`:

```gdscript
const HERO_MAX_HEALTH: Dictionary = {
	"flame_wielder": 90,
	"life_weaver": 110,
	# ... existing heroes ...
	"your_hero_id": 105  # Your new hero
}
```

**Note**: If you don't add this, use `max_health` in the hero data directly.

### Step 5: Test Your Hero

1. **Run the game**
2. **Select your hero** from the character selection screen
3. **Verify**:
   - Correct name and description display
   - HP shows correctly (e.g., 100/100)
   - Energy shows correctly (e.g., 3/3)
   - Deck has 14-15 cards
   - Cards can be played and work as expected

**Testing Checklist**:
- [ ] Hero appears in selection screen
- [ ] Stats display correctly
- [ ] Deck shuffles and draws 5 cards on turn start
- [ ] All cards are playable
- [ ] Hero can defeat at least the first boss

---

## Example: Adding "Vex, Shadow Mage"

Let's add a poison/drain-focused hero.

### 1. Design

```
Name: Vex, Shadow Mage
Archetype: Drain/Poison specialist
Max Health: 90 (glass cannon)
Energy: 3
Theme: Life drain and poison damage over time
```

### 2. Plan Deck

```
Basic Attacks:
- doom_blade × 2 (1 energy, 10 damage)
- poison_strike × 3 (poison damage over time)

Power Cards:
- assassination × 1 (high burst)
- vampiric_touch × 1 (lifesteal)

Defense:
- shadow_step × 2 (evasion/shield)
- drain_life × 2 (heal through damage)

Synergy:
- corrupt × 2 (amplifies poison)
- dark_pact × 1 (sacrifice HP for power)
```

### 3. Add to heroes_data.gd

```gdscript
const HEROES = {
	# ... existing heroes ...

	"shadow_mage": {
		"name": "Vex, Shadow Mage",
		"description": "Master of poison and life drain who thrives on suffering.",
		"max_health": 90,
		"starting_energy": 3,
		"deck": [
			"doom_blade",
			"doom_blade",
			"poison_strike",
			"poison_strike",
			"poison_strike",
			"assassination",
			"vampiric_touch",
			"shadow_step",
			"shadow_step",
			"drain_life",
			"drain_life",
			"corrupt",
			"corrupt",
			"dark_pact"
		]
	}
}
```

### 4. Test

Run game → Select "Vex, Shadow Mage" → Play through first boss encounter

---

## Common Issues

### Issue: Hero doesn't appear in selection
**Solution**: Check that you added the hero to `HEROES` dictionary and the key is unique

### Issue: Cards missing from deck
**Solution**: Verify all card IDs in the `deck` array exist in CardDatabase
- Check spelling (e.g., `lightning_bolt` not `lightning-bolt`)
- Run game and check console for warnings: `"Failed to add card to deck: X"`

### Issue: Hero stats wrong
**Solution**: Double-check `max_health` and `starting_energy` values in your hero data

### Issue: Hero too weak/strong
**Solution**: Adjust deck composition or HP
- **Too weak**: Add more damage cards or increase HP
- **Too strong**: Reduce HP or swap power cards for weaker alternatives

---

## Advanced: Hero-Specific Cards

If you want cards ONLY your hero can use:

1. Add cards to `card_database.gd` (see HOW_TO_ADD_CARD.md)
2. Add card IDs to your hero's deck
3. **Don't** add those cards to other heroes' decks

The cards will only appear in your hero's games.

---

## Balance Reference

### Existing Heroes

| Hero | HP | Archetype | Key Mechanic |
|------|-----|-----------|--------------|
| Pyra (Flame Wielder) | 90 | Aggro | Burn damage |
| Selene (Life Weaver) | 110 | Support | Healing + shields |
| Nyx (Shadow Assassin) | 85 | Control | Poison + drain |
| Zephyr (Storm Caller) | 95 | Spellcaster | AoE + card draw |
| Thorne (Beast Tamer) | 120 | Tank | High HP + sustain |
| Kairos (Chrono Mage) | 100 | Tempo | Card advantage |

### Recommended Starting Stats

```gdscript
"starting_energy": 3  # All heroes use 3 energy currently
"max_health": 85-120  # Based on archetype
"deck": 14-15 cards   # Standard deck size
```

---

## Next Steps

- **Add custom cards**: See `HOW_TO_ADD_CARD.md`
- **Understand architecture**: See `ARCHITECTURE.md`
- **Test balance**: Play through all 5 bosses with your hero
