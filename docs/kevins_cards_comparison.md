# Kevin's Cards: Specification vs Implementation Comparison

This document compares Kevin's cards as specified in `csvs/Kevins_Cards.csv` against their actual implementation in `csvs/cards.csv`.

## Summary

| Status | Count |
|--------|-------|
| ✅ Match | 17 |
| ⚠️ Mismatch | 4 |
| ❌ Missing | 1 |
| **Total** | **22** |

---

## Base Deck Cards (10 cards)

### Spell: Fire Smash ✅ Match
| Property | Spec | Implementation (`spell_fire_smash`) |
|----------|------|-------------------------------------|
| Type | Attack | ATTACK |
| Element | Fire | FIRE |
| Stamina | 2 | 2 |
| Damage | 5 | 5 |
| Target | Single | SINGLE_ENEMY |

### Spell: Water Ball ✅ Match
| Property | Spec | Implementation (`spell_water_ball`) |
|----------|------|-------------------------------------|
| Type | Attack | ATTACK |
| Element | Water | WATER |
| Stamina | 1 | 1 |
| Damage | 1 | 1 |
| Apply Wet | 1 | 1 |
| Target | Single | SINGLE_ENEMY |

### Spell: Earth Quake ✅ Match
| Property | Spec | Implementation (`spell_earthquake`) |
|----------|------|-------------------------------------|
| Type | Attack | ATTACK |
| Element | Earth | EARTH |
| Stamina | 1 | 1 |
| Damage | 2 | 2 |
| Target | All | ALL_ENEMIES |

### Spell: Fiery Flash! ✅ Match
| Property | Spec | Implementation (`spell_fiery_flash`) |
|----------|------|--------------------------------------|
| Type | Attack | ATTACK |
| Element | Fire | FIRE |
| Stamina | 2 | 2 |
| Damage | 4 | 4 |
| Apply Hinder | 4 | 4 |
| Target | Single | SINGLE_ENEMY |

### Poke ✅ Match
| Property | Spec | Implementation (`poke`) |
|----------|------|-------------------------|
| Type | Attack | ATTACK |
| Stamina | 1 | 1 |
| Damage | 2 | 2 |
| Target | Single | SINGLE_ENEMY |

### Meditate ✅ Match
| Property | Spec | Implementation (`meditate`) |
|----------|------|-----------------------------|
| Type | Skill | BUFF |
| Stamina | 1 | 1 |
| Draw Cards | 2 | 2 |
| Target | Self | SELF |

### Rest ✅ Match
| Property | Spec | Implementation (`rest`) |
|----------|------|-------------------------|
| Type | Skill | BUFF |
| Stamina | 1 | 1 |
| Apply Rested | Yes | 1 |
| Target | Self | SELF |

### Fetal Position ✅ Match
| Property | Spec | Implementation (`fetal_position`) |
|----------|------|-----------------------------------|
| Type | Skill | BUFF |
| Stamina | 1 | 1 |
| Shield | 5 | 5 |
| Target | Self | SELF |

### Spell: Ice Shield ⚠️ Mismatch
| Property | Spec | Implementation (`spell_ice_shield`) | Issue |
|----------|------|-------------------------------------|-------|
| Type | Skill | BUFF | OK |
| Element | Water | WATER | OK |
| Stamina | *not specified* | 1 | **Spec missing cost** |
| Shield | 5 | 5 | OK |
| Target | Any Player | SINGLE_ALLY | OK |

**Note:** Spec has no stamina cost defined. Implementation uses 1 stamina which seems reasonable.

### Spell: Encapsulation ⚠️ Mismatch
| Property | Spec | Implementation (`spell_encapsulation`) | Issue |
|----------|------|----------------------------------------|-------|
| Type | Skill | BUFF | OK |
| Element | Earth | EARTH | OK |
| Stamina | *not specified* | 0 | OK |
| Choose Spell | 1 | 0 (via `choose_spell_from_deck`) | **Missing** |

**Note:** Spec indicates this should search deck for a spell. Implementation has `grants_card_retain=true` and `plays_immediately=true` but `choose_spell_from_deck=0`. The description says "Search your deck for any Spell" but the CSV column isn't populated.

---

## Satchel Cards (Alchemist Cards - 3 cards)

### Alc': Lightning Storm ✅ Match
| Property | Spec | Implementation (`alc_lightning_storm`) |
|----------|------|----------------------------------------|
| Type | Attack | ATTACK |
| Element | Wind | *(not set)* |
| Stamina | 2 | 2 |
| Damage | 3 | 3 |
| Brew Cost | 1 Water + 1 Earth | water\|earth |
| Target | Single | SINGLE_ENEMY |

**Note:** Spec shows Wind element but this isn't tracked in implementation (may not be needed since it's an Alc card).

### Alc': Accumulation ✅ Match
| Property | Spec | Implementation (`alc_accumulation`) |
|----------|------|-------------------------------------|
| Type | Attack | ATTACK |
| Element | Dark | *(not set)* |
| Stamina | 2 | 2 |
| Damage | 0 base | 0 |
| Discard All Spells | Yes | true |
| Damage per Spell | 3 | 3 |
| Brew Cost | 1 Water + 1 Fire | water\|fire |
| Target | Single | SINGLE_ENEMY |

### Alc': Giant Shield ✅ Match
| Property | Spec | Implementation (`alc_giant_shield`) |
|----------|------|-------------------------------------|
| Type | Skill | BUFF |
| Element | Light | *(not set)* |
| Stamina | 2 | 2 |
| All Players Shield | 5 | 5 |
| Brew Cost | 1 Earth + 1 Fire | earth\|fire |

---

## Special/Reward Cards (9 cards)

### Spell: Tsunami ✅ Match
| Property | Spec | Implementation (`spell_tsunami`) |
|----------|------|----------------------------------|
| Type | Attack | ATTACK |
| Element | Water | WATER |
| Stamina | 2 | 2 |
| Damage | 4 | 4 |
| Apply Wet | 1 | 1 |
| Target | All | ALL_ENEMIES |

### Repurpose ✅ Match
| Property | Spec | Implementation (`repurpose`) |
|----------|------|------------------------------|
| Type | Attack | ATTACK |
| Stamina | 0 | 0 |
| Damage | 2 | 2 |
| Discard Spell Req | 1 | 1 |
| Target | Single | SINGLE_ENEMY |

**Note:** Description mentions "+2 per Spell discarded this turn" but spec column for "Additional Damage per spell discarded" is empty. Implementation handles this through card effect engine logic.

### Spell: Future Vision ✅ Match
| Property | Spec | Implementation (`spell_future_vision`) |
|----------|------|----------------------------------------|
| Type | Skill | BUFF |
| Element | Earth | EARTH |
| Stamina | 0 | 0 |
| Reveal Boss Cards | 1 | reveals_boss_intent=true |
| Target | Self | SELF |

### Spell: Mortar and Pestle ⚠️ Mismatch
| Property | Spec | Implementation (`spell_mortar_pestle`) | Issue |
|----------|------|----------------------------------------|-------|
| Type | Skill | BUFF | OK |
| Element | Earth | EARTH | OK |
| Stamina | 0 | 0 | OK |
| Discard Cards | 2 | 2 (draw_cards used as discard) | Confusing |
| Next Card Plays Twice | Yes | Not in CSV | **Logic in code** |
| Choose Spell | 1 | discard_spell_requirement=1 | Different approach |

**Note:** The "plays twice" mechanic isn't stored in CSV but is implemented in card effect engine. The discard mechanism differs from spec.

### Spell: Enflame ✅ Match
| Property | Spec | Implementation (`spell_enflame`) |
|----------|------|----------------------------------|
| Type | Skill | BUFF |
| Element | Fire | FIRE |
| Stamina | 1 | 1 |
| Apply Damage Plus | 2 | 2 |
| Target | Any Player | SINGLE_ALLY |

### Spell: Restore ✅ Match
| Property | Spec | Implementation (`spell_restore`) |
|----------|------|----------------------------------|
| Type | Skill | HEAL |
| Element | Water | WATER |
| Stamina | 1 | 1 |
| Remove All Wet | Yes | true |
| Heal per Wet | 5 | 5 |
| Target | Any Player | SINGLE_ALLY |

### Spell: Ring Of Fire ✅ Match
| Property | Spec | Implementation (`spell_ring_of_fire`) |
|----------|------|---------------------------------------|
| Type | Skill | BUFF |
| Element | Fire | FIRE |
| Stamina | 1 | 1 |
| Shield | 5 | 5 |
| Apply Ring of Fire | Yes | 1 |
| Target | Any Player | SINGLE_ALLY |

### Reformulate ✅ Match
| Property | Spec | Implementation (`reformulate`) |
|----------|------|--------------------------------|
| Type | Skill | BUFF |
| Stamina | 0 | 0 |
| Discard Spell Req | 1 | 1 |
| Choose Spell from Deck | 1 | 1 |
| Target | Self | SELF |

### Accretion ❌ Missing/Wrong Implementation
| Property | Spec | Implementation (`accretion`) | Issue |
|----------|------|------------------------------|-------|
| Type | Skill | BUFF | OK |
| Stamina | 0 | 0 | OK |
| Discard Spells | 2 | 2 | OK |
| Target Draw Cards | 1 | 0 | **MISSING** |
| Target Stamina Gain | 0 | 1 | **WRONG - should be draw** |
| Target | Any Player | SINGLE_ALLY | OK |

**Issue:** The implementation gives target stamina instead of draw cards. Spec clearly shows "Target Draw Cards = 1" and "Target Stamina Gain = 0". The `target_stamina_gain=1` should be `target_draw_cards=1` (or equivalent column).

---

## Issues Summary

### High Priority
1. **Accretion** - Wrong effect implemented (stamina gain vs card draw)

### Medium Priority
2. **Spell: Encapsulation** - Missing `choose_spell_from_deck` functionality in CSV
3. **Spell: Mortar and Pestle** - Discard count and "plays twice" implementation unclear

### Low Priority (Spec Gaps)
4. **Spell: Ice Shield** - Spec missing stamina cost (implementation uses 1)

---

## Card ID Reference

| Card Name | Card ID | CSV Row |
|-----------|---------|---------|
| Spell: Fire Smash | spell_fire_smash | 63 |
| Spell: Water Ball | spell_water_ball | 64 |
| Spell: Earth Quake | spell_earthquake | 65 |
| Spell: Fiery Flash! | spell_fiery_flash | 66 |
| Poke | poke | 67 |
| Meditate | meditate | 68 |
| Rest | rest | 13 |
| Fetal Position | fetal_position | 69 |
| Spell: Ice Shield | spell_ice_shield | 70 |
| Spell: Encapsulation | spell_encapsulation | 71 |
| Alc': Lightning Storm | alc_lightning_storm | 72 |
| Alc': Accumulation | alc_accumulation | 73 |
| Alc': Giant Shield | alc_giant_shield | 74 |
| Spell: Tsunami | spell_tsunami | 75 |
| Repurpose | repurpose | 76 |
| Spell: Future Vision | spell_future_vision | 77 |
| Spell: Mortar and Pestle | spell_mortar_pestle | 78 |
| Spell: Enflame | spell_enflame | 79 |
| Spell: Restore | spell_restore | 80 |
| Spell: Ring Of Fire | spell_ring_of_fire | 81 |
| Reformulate | reformulate | 82 |
| Accretion | accretion | 83 |
