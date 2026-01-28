# Comprehensive Test Suite Plan - Deck Masters

## Executive Summary

This document outlines a complete test framework for Deck Masters, providing systematic coverage of all game mechanics with measurable success criteria and realistic implementation timelines.

### Coverage Targets

| Category | Count | Test Estimate |
|----------|-------|---------------|
| Player Cards | 83 | ~120 tests |
| Enemy Cards | 86+ | ~100 tests |
| Relics | 23 | ~70 tests |
| Status Effects | 26 | ~100 tests |
| Interactions | - | ~100 tests |
| Multiplayer | - | ~50 tests |
| **Total** | - | **~540 tests** |

### Card Breakdown

- **Fabio**: 25 cards (9 base + 16 reward)
- **Kevin**: 21 cards (9 base + 3 Alc + 9 reward)
- **Enrique**: 17 cards (10 base + 7 reward)
- **Shared**: 2 cards (Energy, Ember)
- **Generic Rewards**: 23 cards (8 rare + 10 common + 5 demo)
- **Enemy**: 86+ cards across 5 bosses, 8 minion types, 3 Dark Heroes

---

## 1. Scope and Non-Goals

### In Scope

- Unit tests for all card effects and damage calculations
- Unit tests for all relic triggers and modifiers
- Unit tests for all status effect application, stacking, and decay
- Integration tests for key card/relic/status interactions
- Multiplayer state synchronization tests (simulated network)
- CLI execution with JSON/XML output for CI integration

### Non-Goals (Out of Scope for Phase 1)

| Item | Reason |
|------|--------|
| UI/Scene visual testing | Requires screenshot comparison tooling; defer to Phase 2 |
| Performance profiling | Focus on correctness first; profiling is separate initiative |
| Network reliability testing | Packet loss, latency simulation deferred to Phase 2 |
| Save/Load state testing | Lower priority; manual QA sufficient initially |
| Audio testing | Not applicable to unit test framework |

### Coverage Criteria

For interaction tests, "covered" means:

1. **Damage modifiers**: All effects that modify outgoing or incoming damage (Strength, Weakness, Vulnerable, Hinder, Armor, Damage+)
2. **Resource modifiers**: Effects that change stamina, draw, or aura (Rested, Fatigued, relics)
3. **Healing modifiers**: Decay and healing bonus relics
4. **Trigger chains**: Multi-hit cards with relics/DOTs, spell discard combos

---

## 2. Environment Requirements

### Runtime

| Requirement | Version/Value |
|-------------|---------------|
| Godot Engine | 4.2+ (4.3+ recommended) |
| Headless Mode | `--headless` flag required |
| Export Template | Headless Linux or Windows Server |

### CI Targets

| Platform | Runner |
|----------|--------|
| Windows | Windows Server 2022 or Windows 11 |
| Linux | Ubuntu 22.04 LTS |

### Dependencies

- No external testing frameworks required
- All test utilities built in GDScript
- JSON/XML output for CI tool parsing (GitHub Actions, GitLab CI)

---

## 3. Test Framework Architecture

### 3.1 Directory Structure

```
scripts/tests/
├── framework/
│   ├── test_base.gd           # Base class for all test suites
│   ├── test_runner.gd         # CLI test orchestrator
│   ├── test_assertions.gd     # Centralized assertion library
│   ├── test_fixtures.gd       # Character/combat setup utilities
│   ├── test_mocks.gd          # Mock objects for isolation
│   └── test_reporter.gd       # Output formatting (console, JSON, XML)
│
├── suites/
│   ├── cards/
│   │   ├── fabio_cards_test.gd
│   │   ├── kevin_cards_test.gd
│   │   ├── enrique_cards_test.gd
│   │   ├── shared_cards_test.gd
│   │   ├── reward_cards_test.gd
│   │   └── enemy_cards_test.gd
│   │
│   ├── relics/
│   │   ├── universal_relics_test.gd
│   │   ├── fabio_relics_test.gd
│   │   ├── kevin_relics_test.gd
│   │   └── enrique_relics_test.gd
│   │
│   ├── status_effects/
│   │   ├── dot_effects_test.gd
│   │   ├── buff_effects_test.gd
│   │   ├── debuff_effects_test.gd
│   │   └── special_effects_test.gd
│   │
│   ├── interactions/
│   │   ├── card_relic_test.gd
│   │   ├── card_status_test.gd
│   │   ├── relic_status_test.gd
│   │   ├── multi_effect_test.gd
│   │   └── edge_cases_test.gd
│   │
│   └── multiplayer/
│       ├── state_sync_test.gd
│       ├── turn_order_test.gd
│       ├── rpc_test.gd
│       └── protection_test.gd
│
├── smoke_test.gd              # Quick verification subset
└── run_tests.gd               # CLI entry point
```

### 3.2 Determinism Strategy

All tests must be deterministic and reproducible.

| Mechanism | Implementation |
|-----------|----------------|
| RNG Seeding | Fixed seed per test suite via `seed(12345)` in `before_all()` |
| Fixture Versioning | Character stats and card data loaded from registry, not hardcoded |
| No Timing Dependencies | Use frame counts or explicit waits, never wall-clock time |
| Isolated State | Each test gets fresh GameManager instance via `before_each()` |

### 3.3 Framework Components

#### TestBase (test_base.gd)

```gdscript
class_name TestBase extends RefCounted

var game_manager: GameManager
var card_db: CardDatabase
var boss_db: BossDatabase
var relic_registry: RelicRegistry
var results: Array[Dictionary] = []
var current_test: String = ""

func before_all() -> void:
    seed(12345)  # Deterministic RNG

func after_all() -> void: pass
func before_each() -> void: pass
func after_each() -> void: pass

func run_all() -> Array[Dictionary]  # Execute all _test_* methods
func run_test(name: String) -> Dictionary  # Execute single test
```

#### TestAssertions (test_assertions.gd)

```gdscript
class_name TestAssertions

# Equality
static func eq(actual, expected, msg: String) -> Dictionary
static func ne(actual, expected, msg: String) -> Dictionary

# Comparison
static func gt(actual, expected, msg: String) -> Dictionary
static func gte(actual, expected, msg: String) -> Dictionary
static func lt(actual, expected, msg: String) -> Dictionary
static func lte(actual, expected, msg: String) -> Dictionary
static func in_range(value, min_val, max_val, msg: String) -> Dictionary

# Boolean
static func is_true(condition: bool, msg: String) -> Dictionary
static func is_false(condition: bool, msg: String) -> Dictionary

# Null checks
static func is_null(value, msg: String) -> Dictionary
static func not_null(value, msg: String) -> Dictionary

# Collections
static func contains(array: Array, item, msg: String) -> Dictionary
static func has_key(dict: Dictionary, key: String, msg: String) -> Dictionary

# Error handling
static func throws(callable: Callable, msg: String) -> Dictionary

# Game-specific helpers
static func health_is(char: Character, hp: int, msg: String) -> Dictionary
static func shield_is(char: Character, shield: int, msg: String) -> Dictionary
static func has_buff(char: Character, buff: String, stacks: int, msg: String) -> Dictionary
static func has_debuff(char: Character, debuff: String, stacks: int, msg: String) -> Dictionary
static func is_dead(char: Character, msg: String) -> Dictionary
static func is_alive(char: Character, msg: String) -> Dictionary
```

#### TestFixtures (test_fixtures.gd)

```gdscript
class_name TestFixtures

# Character Creation
static func player(name: String, hp: int, stamina: int) -> Character
static func fabio(hp: int = 50, stamina: int = 3) -> Character
static func kevin(hp: int = 40, stamina: int = 3) -> Character
static func enrique(hp: int = 30, stamina: int = 3, aura: int = 5) -> Character
static func enemy(name: String, hp: int) -> Character
static func boss(name: String, hp: int, cards: Array) -> Character
static func minion(name: String, hp: int) -> Character

# Combat Setup
static func combat(gm: GameManager, players: Array, enemies: Array) -> void
static func multiplayer_combat(gm: GameManager, player_count: int, enemy_count: int) -> void

# Card Manipulation
static func give_card(char: Character, card_id: String, card_db: CardDatabase) -> Card
static func give_cards(char: Character, card_ids: Array, card_db: CardDatabase) -> Array[Card]
static func set_hand(char: Character, card_ids: Array, card_db: CardDatabase) -> void

# Status Effects
static func apply_buff(char: Character, name: String, stacks: int) -> void
static func apply_debuff(char: Character, name: String, stacks: int) -> void
static func clear_effects(char: Character) -> void

# Relics
static func give_relic(char: Character, relic_id: String) -> void
static func give_relics(char: Character, relic_ids: Array) -> void

# Turn Simulation
static func start_turn(gm: GameManager) -> void
static func end_turn(gm: GameManager) -> void
static func advance_turns(gm: GameManager, count: int) -> void

# State Helpers
static func wound(char: Character) -> void      # Set to 40% HP (wounded threshold)
static func set_hp(char: Character, hp: int) -> void
static func kill(char: Character) -> void
static func revive(char: Character, hp: int) -> void
```

#### TestMocks (test_mocks.gd)

```gdscript
class_name TestMocks

# Mock RPC calls for multiplayer testing
static func mock_rpc_layer() -> MockRPC
static func mock_network_peer(peer_id: int) -> MockPeer

# Mock UI components
static func mock_card_selection() -> MockCardSelector
static func mock_target_selection() -> MockTargetSelector

# Mock randomness
static func mock_rng(sequence: Array[int]) -> MockRNG
```

---

## 4. Smoke Test Suite

A minimal subset for rapid verification during development.

### Smoke Tests (15 tests, target: under 5 seconds)

| Category | Tests |
|----------|-------|
| **Cards (5)** | Slash damage, Fire Smash damage, Expulsion aura spend, Dual Wield multi-hit, Healing Potion heal |
| **Relics (3)** | Backpack draw, Second Wind stamina, Copying Machine extra hit |
| **Status (4)** | Poison DOT + decay, Strength damage bonus, Vulnerable damage increase, Scared blocks attacks |
| **Interactions (2)** | Slash + Strength, Medkit + Decay |
| **Multiplayer (1)** | HP sync after damage |

### CLI Usage

```bash
# Run smoke tests only
godot --headless --script scripts/tests/run_tests.gd -- --suite=smoke
```

---

## 5. Card Tests (~220 tests)

### 5.1 Fabio Cards (25 cards, ~35 tests)

#### Base Deck (9 cards)

| Card ID | Test Name | What to Test |
|---------|-----------|--------------|
| slash | `test_slash_damage` | Deals 7 damage to single enemy |
| big_smack | `test_big_smack_damage` | Deals 10 damage to single enemy |
| duel_purpose | `test_duel_purpose_damage_and_shield` | Deals 3 damage AND grants 5 shield to caster |
| rest | `test_rest_applies_rested` | Applies 1 Rested buff |
| bulk_up | `test_bulk_up_invigorated_fatigued` | Applies 1 Invigorated AND 1 Fatigued |
| dig_a_hole | `test_dig_a_hole_card_retention` | Opens retention modal, card persists next turn |
| protector | `test_protector_redirects_damage` | Enemy attacks on target redirect to caster |
| protector | `test_protector_dead_no_redirect` | Dead protector doesn't redirect |
| protective_footwear | `test_protective_footwear_shield` | Grants 5 shield to self |
| hunters_instinct | `test_hunters_instinct_reveals_intent` | Boss cards revealed for next turn |

#### Reward Cards (16 cards)

| Card ID | Test Name | What to Test |
|---------|-----------|--------------|
| dual_wield | `test_dual_wield_multi_hit` | Hits 2 times for 2 damage each |
| circular_strike | `test_circular_strike_aoe` | Deals 3 damage to ALL enemies |
| cursed_dagger | `test_cursed_dagger_zero_cost` | Costs 0 stamina, deals 2 damage |
| jumping_strike | `test_jumping_strike_delayed` | Damage queued, applies next turn if no damage taken |
| jumping_strike | `test_jumping_strike_cancelled` | No damage if caster took damage |
| execution | `test_execution_base_damage` | Deals 4 damage normally |
| execution | `test_execution_wounded_bonus` | Deals 8 damage if target below 50% HP |
| frenzy | `test_frenzy_aoe_exhausted` | Deals 8 to all, applies 2 Exhausted to caster |
| weak_point | `test_weak_point_base` | Deals 2 damage with no debuffs |
| weak_point | `test_weak_point_debuff_bonus` | Deals 2 + 2 per debuff stack |
| medkit | `test_medkit_heal_decay` | Heals 10 HP, applies 1 Decay to caster |
| fighters_spirit | `test_fighters_spirit_v1_debuff_removal` | V1: Removes 1 debuff from self |
| fighters_spirit | `test_fighters_spirit_v2_shield` | V2: Grants 5 shield |
| sacrifice | `test_sacrifice_protection` | Redirects attacks on ally to caster |
| leader | `test_leader_v1_draw` | V1: All OTHER allies draw 1 |
| leader | `test_leader_v2_discard_draw` | V2: Caster discards 2, allies draw 2 |

### 5.2 Kevin Cards (21 cards, ~35 tests)

#### Base Deck (9 spells + 3 Alc)

| Card ID | Test Name | What to Test |
|---------|-----------|--------------|
| poke | `test_poke_damage` | Deals 2 damage |
| meditate | `test_meditate_draw` | Draw 2 cards |
| fetal_position | `test_fetal_position_shield` | Gain 5 shield |
| spell_fire_smash | `test_fire_smash_damage` | Deals 5 damage, is FIRE spell |
| spell_water_ball | `test_water_ball_wet` | Deals 1 damage, applies 1 Wet |
| spell_earthquake | `test_earthquake_aoe` | Deals 2 to ALL, is EARTH spell |
| spell_fiery_flash | `test_fiery_flash_hinder` | Deals 4, applies 4 Hinder |
| spell_ice_shield | `test_ice_shield_ally` | Gives ally 5 shield, is WATER spell |
| spell_encapsulation | `test_encapsulation_retain` | Card retention, is EARTH spell |
| alc_lightning_storm | `test_lightning_storm_wet_bonus` | Deals 3 damage per Wet on target |
| alc_lightning_storm | `test_lightning_storm_removes_wet` | Removes Wet after calculating |
| alc_accumulation | `test_accumulation_spell_discard` | Discards all spells, 3 damage per |
| alc_giant_shield | `test_giant_shield_all_allies` | All allies gain 5 shield |

#### Reward Cards (9 cards)

| Card ID | Test Name | What to Test |
|---------|-----------|--------------|
| spell_tsunami | `test_tsunami_aoe_wet` | 4 damage to all, 1 Wet to all |
| repurpose | `test_repurpose_spell_bonus` | 2 + 2 per spell discarded |
| spell_future_vision | `test_future_vision_reveal` | Reveals boss intent |
| spell_mortar_pestle | `test_mortar_pestle_discard_draw` | Discard 1 spell, draw 2 |
| spell_enflame | `test_enflame_damage_buff` | Target's next attack +2 damage |
| spell_restore | `test_restore_wet_heal` | Removes Wet, heals 5 per Wet removed |
| spell_ring_of_fire | `test_ring_of_fire_reflect` | Shield + reflect 3 damage on hit |
| reformulate | `test_reformulate_spell_search` | Discard spell, search for different |
| accretion | `test_accretion_stamina` | Discard 2 spells, ally gains 1 stamina |

### 5.3 Enrique Cards (17 cards, ~25 tests)

#### Base Deck (10 cards)

| Card ID | Test Name | What to Test |
|---------|-----------|--------------|
| expulsion | `test_expulsion_aura_damage` | Spends ALL aura, 3 damage per to ALL |
| focused_purge | `test_focused_purge_aura_gain` | 3 damage + gain 1 aura |
| holy_plight | `test_holy_plight_aura_cost` | 5 damage, costs 2 aura |
| prayer_beads | `test_prayer_beads_d6` | Random 1-6 damage, costs 1 aura |
| humble_request | `test_humble_request_aura` | Gain 2 aura |
| divine_reflection | `test_divine_reflection_double` | Next card plays twice, costs 3 aura |
| healing_aura | `test_healing_aura_decay` | Heal 10, caster gets 1 Decay |
| magical_purge | `test_magical_purge_debuff` | Remove 1 debuff from self |
| story_of_jacob | `test_story_of_jacob` | Gain 5 aura + 1 Fatigued |
| protection | `test_protection_ally_shield` | Ally gains 5 shield, costs 1 aura |

#### Reward Cards (7 cards)

| Card ID | Test Name | What to Test |
|---------|-----------|--------------|
| divine_force | `test_divine_force_v1_heal` | V1: Heal ally 10, gain Decay |
| divine_force | `test_divine_force_v2_damage` | V2: Deal 6 damage to enemy |
| purging_water | `test_purging_water_cleanse` | Remove 1 debuff from ally |
| divine_barrier | `test_divine_barrier_invincible` | Ally becomes Invincible |
| refuge | `test_refuge_shield_aura` | Gain 5 shield + 1 aura |
| gift | `test_gift_ally_draw` | Ally draws 2 cards |
| divine_gift | `test_divine_gift_stamina` | Ally gains 2 stamina |
| guy_with_beard | `test_guy_with_beard_all_draw` | ALL players draw 1 |

### 5.4 Shared Cards (2 cards, 2 tests)

| Card ID | Test Name | What to Test |
|---------|-----------|--------------|
| energy | `test_energy_instant_stamina` | Plays instantly, +1 stamina |
| ember | `test_ember_token_damage` | Token deals 4 damage |

### 5.5 Generic Reward Cards (23 cards, ~25 tests)

#### Rare (8 cards)

| Card ID | Test Name | What to Test |
|---------|-----------|--------------|
| apocalypse | `test_apocalypse_massive_aoe` | 30 damage to ALL enemies |
| divine_intervention | `test_divine_intervention` | Heal 50 + 30 shield |
| berserker_rage | `test_berserker_rage_strength` | Gain 5 permanent Strength |
| meteor_swarm | `test_meteor_swarm_multi_aoe` | 12 damage x3 to ALL |
| time_stop | `test_time_stop_draw` | Draw 5 cards |
| life_drain | `test_life_drain_lifesteal` | 25 damage with lifesteal |
| annihilation | `test_annihilation_piercing` | 35 piercing damage |
| omnipotence | `test_omnipotence_buffs` | 15 shield + 3 Str + 3 Armor + draw 3 |

#### Common (10 cards)

| Card ID | Test Name | What to Test |
|---------|-----------|--------------|
| steel_strike | `test_steel_strike` | 16 damage |
| healing_potion | `test_healing_potion` | Heal 15 |
| fortify | `test_fortify` | Gain 12 shield |
| power_strike | `test_power_strike` | 18 damage |
| battle_focus | `test_battle_focus` | +2 Strength + draw 1 |
| cleave | `test_cleave_aoe` | 10 damage to ALL |
| rejuvenation | `test_rejuvenation` | Heal 12 + 8 shield |
| iron_will | `test_iron_will` | 10 shield + 2 Armor |
| quick_strike | `test_quick_strike` | 12 damage |
| tactical_advantage | `test_tactical_advantage` | Draw 2 cards |

#### Demo (5 cards)

| Card ID | Test Name | What to Test |
|---------|-----------|--------------|
| vampiric_strike | `test_vampiric_strike` | 12 damage + lifesteal |
| toxic_cloud | `test_toxic_cloud` | 8 damage to ALL + 4 Poison |
| dark_pact | `test_dark_pact` | -5 HP, +4 Str, draw 2 |
| blazing_fury | `test_blazing_fury` | 15 damage + 3 Burn + 2 Vulnerable |
| pyroclasm | `test_pyroclasm` | 18 to ALL + 2 Ember tokens |

### 5.6 Enemy Cards (~100 tests)

#### Bosses

| Boss | HP | Cards | Key Tests |
|------|----|-------|-----------|
| Giant Moose | 60 | 6 | Charge targets lowest HP, Stomp AOE, Roar applies Scared |
| Mr. 67 | 75 | 6 | Big Punch random target, Protein Shake Strength, Ground Smash AOE |
| Spider-Queen | 75 | 7 | Venom Bite + Venom, Spawn Spiderling summon, Web Shield |
| Mute | 80 | 5 | Ravage marked target, Instantiation Doll curse, Hex effects |
| The Doctor | 120 | 10 | Rupture debuff scaling, Potion Instantiate summon, Deep Stabs multi-effect |

#### Minions (8 types, ~20 tests)

| Minion | Cards | Key Tests |
|--------|-------|-----------|
| Swarm of Raccoons | 2 | Basic attack, Rabid Bite |
| Alex the Monkey | 3 | Banana throw, Screech debuff |
| Brock | 2 | Heavy slam, Shield up |
| Mommy | 2 | Embrace (heal), Scold (debuff) |
| Trogdor | 2 | Burninate AOE, Arm strike |
| Giant Centipede | 4 | Multi-leg strike, Poison bite, Burrow |
| Wendigo | 4 | Claw attack, Howl (Scared), Regeneration |
| Amalgamation | 4 | Absorb, Multi-strike, Reformation |

#### Spiderlings (3 types, 3 tests)

| Spiderling | Card | Test |
|------------|------|------|
| Alf | Web Shot | `test_spiderling_alf_web` |
| Enrique | Venom Spit | `test_spiderling_enrique_venom` |
| Jeff | Skitter | `test_spiderling_jeff_skitter` |

#### Dark Heroes (3 heroes × 8 cards = 24 tests)

| Dark Hero | Key Cards to Test |
|-----------|-------------------|
| Fabio The Usurper | Dark Slash, Corrupted Bulk Up, Shadow Protector |
| Kevin The Druid | Twisted Spells, Dark Alchemy, Corrupted Elements |
| Enrique The Fallen | Unholy Plight, Dark Reflection, Corrupted Healing |

---

## 6. Relic Tests (23 relics, ~70 tests)

### 6.1 Universal Relics (13 relics)

| Relic ID | Trigger | Tests |
|----------|---------|-------|
| backpack | Turn Start | `test_backpack_draw_turn_start` |
| second_wind | On Damage Dealt | `test_second_wind_10_damage_threshold`, `test_second_wind_under_10_no_trigger` |
| copying_machine | Passive | `test_copying_machine_extra_hit`, `test_copying_machine_single_hit_no_effect` |
| cracked_gem | Turn Start | `test_cracked_gem_turn_1_only`, `test_cracked_gem_turn_2_no_effect` |
| restorative_locket | Fight End | `test_restorative_locket_fight_end` |
| nipple_protectors | Fight Start | `test_nipple_protectors_fight_start_armor` |
| grandmas_cookies | On Heal | `test_grandmas_cookies_heal_bonus` |
| coffee_soda | On Pickup | `test_coffee_soda_on_pickup_hp` |
| power_ring | Fight Start | `test_power_ring_fight_start_strength` |
| rage_meter | On Card Played | `test_rage_meter_3rd_card`, `test_rage_meter_reset_each_turn` |
| blood_crystal | Turn Start | `test_blood_crystal_stamina_and_bleed` |
| radiating_apple | Turn Start/End | `test_radiating_apple_stamina_and_damage` |
| revive_relic | Active Use | `test_revive_relic_active_use`, `test_revive_relic_once_per_fight` |

### 6.2 Fabio Relics (3 relics)

| Relic ID | Trigger | Tests |
|----------|---------|-------|
| brass_knuckles | Fight Start | `test_brass_knuckles_strength` |
| dragon_scale_cream | Fight Start | `test_dragon_scale_cream_armor` |
| forearm_trainer | Passive | `test_forearm_trainer_cost_reduction`, `test_forearm_trainer_1_cost_no_reduction` |

### 6.3 Kevin Relics (3 relics)

| Relic ID | Trigger | Tests |
|----------|---------|-------|
| water_stone | On Debuff Applied | `test_water_stone_double_wet` |
| familiar_bracelet | Passive | `test_familiar_bracelet_non_spell_bonus`, `test_familiar_bracelet_spell_no_bonus` |
| wooden_cauldron | On Brew | `test_wooden_cauldron_brew_draw` |

### 6.4 Enrique Relics (4 relics)

| Relic ID | Trigger | Tests |
|----------|---------|-------|
| prayer_book | Fight Start | `test_prayer_book_fight_start_aura` |
| gentle_hands | On Heal | `test_gentle_hands_ally_heal_bonus`, `test_gentle_hands_self_heal_no_bonus` |
| shining_feather | Turn End | `test_shining_feather_aura_threshold`, `test_shining_feather_under_5_no_shield` |
| electrified_idol | On Heal | `test_electrified_idol_heal_damage` |

---

## 7. Status Effect Tests (26 effects, ~100 tests)

### 7.1 DOT Effects (3 effects)

| Effect | Decay | Tests |
|--------|-------|-------|
| Poison | -1/turn | `test_poison_damage`, `test_poison_decay`, `test_poison_piercing` |
| Bleed | -1/turn | `test_bleed_damage`, `test_bleed_decay`, `test_bleed_piercing` |
| Burn | None | `test_burn_damage`, `test_burn_no_decay`, `test_burn_piercing` |

### 7.2 Permanent Buffs (2 effects)

| Effect | Tests |
|--------|-------|
| Strength | `test_strength_damage_increase`, `test_strength_stacking`, `test_strength_persists` |
| Armor | `test_armor_damage_reduction`, `test_armor_stacking`, `test_armor_persists` |

### 7.3 Decaying Debuffs (5 effects)

| Effect | Decay | Tests |
|--------|-------|-------|
| Vulnerable | -1/turn | `test_vulnerable_damage_increase`, `test_vulnerable_decay` |
| Weakness | -1/turn | `test_weakness_damage_reduction`, `test_weakness_decay` |
| Fatigued | After turn start | `test_fatigued_stamina_loss`, `test_fatigued_removed_after` |
| Hinder | End of turn | `test_hinder_damage_reduction`, `test_hinder_end_of_turn_removal` |
| Feeble | None (permanent) | `test_feeble_permanent`, `test_feeble_stacking` |

### 7.4 Single-Turn Buffs (3 effects)

| Effect | Tests |
|--------|-------|
| Rested | `test_rested_stamina_gain`, `test_rested_removed_after` |
| Invigorated | `test_invigorated_grants_damage_plus`, `test_invigorated_end_turn_removal` |
| Damage+ | `test_damage_plus_bonus`, `test_damage_plus_end_turn_removal` |

### 7.5 Single-Turn Debuffs (3 effects)

| Effect | Tests |
|--------|-------|
| Exhausted | `test_exhausted_blocks_cards`, `test_exhausted_decay` |
| Scared | `test_scared_blocks_attacks`, `test_scared_allows_buffs`, `test_scared_end_turn` |
| Decay | `test_decay_reduces_healing`, `test_decay_permanent`, `test_decay_stacking` |

### 7.6 Special Effects (7 effects)

| Effect | Tests |
|--------|-------|
| Venom | `test_venom_threshold_trigger`, `test_venom_threshold_damage`, `test_venom_reset` |
| Wet | `test_wet_stacking`, `test_wet_lightning_storm_bonus`, `test_wet_no_decay` |
| Ring of Fire | `test_ring_of_fire_reflect`, `test_ring_of_fire_end_enemy_turn` |
| Played Twice | `test_played_twice_triggers`, `test_played_twice_consumed` |
| Invincible | `test_invincible_blocks_damage`, `test_invincible_end_enemy_turn` |
| Burden | `test_burden_end_turn_damage` |
| Dissolve | `test_dissolve_card_play_damage` |

### 7.7 Doll Effects (3 effects)

| Effect | Tests |
|--------|-------|
| Doll: Dissolve | `test_doll_dissolve_per_card` |
| Doll: Suffering | `test_doll_suffering_end_turn` |
| Doll: Burden | `test_doll_burden_draw_reduction` |

---

## 8. Interaction Tests (~100 tests)

### 8.1 Card + Relic Interactions

| Interaction | Test |
|-------------|------|
| Multi-hit + Copying Machine | `test_dual_wield_with_copying_machine` (3 hits instead of 2) |
| Lifesteal + Grandma's Cookies | `test_lifesteal_with_cookies` (heal bonus applies) |
| Non-spell + Familiar Bracelet | `test_slash_with_familiar_bracelet` (+2 damage) |
| Spell + Familiar Bracelet | `test_fire_smash_no_bracelet_bonus` |
| High damage + Second Wind | `test_big_smack_triggers_second_wind` |
| Healing + Gentle Hands + Electrified Idol | `test_healing_aura_with_both_relics` |
| Wet application + Water Stone | `test_water_ball_with_water_stone` |
| Kevin brew + Wooden Cauldron | `test_brew_triggers_cauldron` |
| Attack cost + Forearm Trainer | `test_big_smack_cost_reduction` |

### 8.2 Card + Status Effect Interactions

| Interaction | Test |
|-------------|------|
| Damage + Strength | `test_slash_with_strength` |
| Damage + Weakness | `test_slash_with_weakness` |
| Damage + Vulnerable target | `test_slash_vs_vulnerable` |
| Damage + Hinder | `test_slash_with_hinder` |
| Multi-hit + DOTs | `test_dual_wield_triggers_bleed_each_hit` |
| Debuff bonus damage | `test_weak_point_with_multiple_debuffs` |
| Wounded bonus | `test_execution_wounded_calculation` |
| Shield + Piercing | `test_annihilation_ignores_shield` |
| Healing + Decay | `test_medkit_with_decay_penalty` |
| Invincible blocks damage | `test_divine_barrier_blocks_boss_attack` |

### 8.3 Relic + Status Effect Interactions

| Interaction | Test |
|-------------|------|
| Blood Crystal + Bleed decay | `test_blood_crystal_bleed_decays` |
| Shining Feather + Aura threshold | `test_shining_feather_exact_5_aura` |
| Rage Meter + Exhausted | `test_rage_meter_exhausted_no_cards` |
| Second Wind + Strength bonus | `test_second_wind_with_strength` |

### 8.4 Multi-Effect Stacking

| Interaction | Test |
|-------------|------|
| Multiple Strength sources | `test_strength_from_card_and_relic` |
| Multiple Armor sources | `test_armor_stacking_cap` |
| Heal bonuses stack | `test_multiple_heal_relics` |
| Damage modifiers stack | `test_strength_and_damage_plus` |
| Multiple DOTs | `test_poison_and_bleed_both_trigger` |
| Decay + Grandma's Cookies | `test_decay_vs_heal_bonus` |

### 8.5 Edge Cases

| Test | What to Verify |
|------|----------------|
| `test_overkill_damage` | Damage exceeding HP handled correctly |
| `test_heal_at_max_hp` | No overhealing |
| `test_shield_cap` | Shield doesn't exceed cap |
| `test_zero_stamina_play` | Cards unplayable at 0 stamina |
| `test_empty_hand_draw` | Draw with empty deck |
| `test_dead_target` | Effects on dead characters |
| `test_self_damage_death` | Cards that hurt caster |
| `test_negative_damage` | Damage can't go negative |
| `test_max_debuff_stacks` | Debuff stacking limits |

---

## 9. Multiplayer Tests (~50 tests)

### 9.1 State Synchronization

| Test | What to Verify |
|------|----------------|
| `test_hp_sync_after_damage` | HP matches across all clients |
| `test_shield_sync` | Shield values synchronized |
| `test_buff_sync` | Buffs appear on all clients |
| `test_debuff_sync` | Debuffs appear on all clients |
| `test_hand_size_sync` | Hand sizes match (not contents) |
| `test_deck_size_sync` | Deck sizes synchronized |
| `test_relic_sync` | Relics visible to all players |

### 9.2 Turn System

| Test | What to Verify |
|------|----------------|
| `test_simultaneous_card_queue` | Both players' cards queued correctly |
| `test_turn_order_resolution` | Cards resolve in correct order |
| `test_turn_end_sync` | All players end turn together |
| `test_round_increment` | Round number increments for all |

### 9.3 Protection Mechanics

| Test | What to Verify |
|------|----------------|
| `test_cross_player_protection` | Protection works across network |
| `test_protection_cleared_on_death` | Dead protector releases protection |
| `test_multiple_protectors` | Multiple protection sources |

### 9.4 RPC Verification

| Test | What to Verify |
|------|----------------|
| `test_card_play_rpc` | Card play broadcasts to all |
| `test_damage_rpc` | Damage synced via RPC |
| `test_heal_rpc` | Healing synced via RPC |
| `test_buff_application_rpc` | Buff application broadcast |
| `test_delayed_effect_rpc` | Delayed effects sync correctly |

### 9.5 Host vs Client Differences

| Test | What to Verify |
|------|----------------|
| `test_host_instant_execution` | Host executes immediately |
| `test_client_delayed_execution` | Client waits for confirmation |
| `test_state_consistency` | Final state matches |

---

## 10. CLI Usage

### Commands

```bash
# Run all tests
godot --headless --script scripts/tests/run_tests.gd

# Run smoke tests only
godot --headless --script scripts/tests/run_tests.gd -- --suite=smoke

# Run specific suite
godot --headless --script scripts/tests/run_tests.gd -- --suite=cards/fabio

# Run single test
godot --headless --script scripts/tests/run_tests.gd -- --test=test_slash_damage

# JSON output for CI
godot --headless --script scripts/tests/run_tests.gd -- --format=json

# XML output for CI
godot --headless --script scripts/tests/run_tests.gd -- --format=xml

# Verbose output
godot --headless --script scripts/tests/run_tests.gd -- --verbose

# Stop on first failure
godot --headless --script scripts/tests/run_tests.gd -- --fail-fast
```

### Output Formats

**Console (default):**
```
[SUITE] Fabio Cards
  ✓ test_slash_damage (2ms)
  ✓ test_big_smack_damage (1ms)
  ✗ test_duel_purpose_damage_and_shield
    Expected: 97
    Actual: 100
    at fabio_cards_test.gd:45

Results: 23/25 passed, 2 failed (156ms)
```

**JSON (for CI):**
```json
{
  "passed": 538,
  "failed": 2,
  "skipped": 0,
  "duration_ms": 45000,
  "suites": [...]
}
```

---

## 11. Implementation Timeline

| Phase | Scope | Estimate |
|-------|-------|----------|
| **Phase 1: Framework** | test_base, assertions, fixtures, mocks, runner, reporter | 3-5 days |
| **Phase 2: Smoke + Cards** | Smoke suite, all player and enemy cards | 5-7 days |
| **Phase 3: Status/Relics** | All status effects and relics | 3-5 days |
| **Phase 4: Interactions** | Card/relic/status combinations, edge cases | 4-6 days |
| **Phase 5: Multiplayer** | State sync, turn system, protection, RPCs | 3-5 days |
| **Total** | | **18-28 days** |

### Milestone Checkpoints

1. **Framework Complete**: Run empty suite, verify CLI output
2. **Smoke Tests Pass**: 15 core tests green
3. **Card Coverage**: All 83 player cards tested
4. **Full Suite**: ~540 tests, under 60 seconds

---

## 12. Performance Budgets

| Suite | Target |
|-------|--------|
| Smoke | < 5 seconds |
| Cards | < 20 seconds |
| Status Effects | < 10 seconds |
| Relics | < 10 seconds |
| Interactions | < 15 seconds |
| Multiplayer | < 10 seconds |
| **Full Suite** | **< 60 seconds** |

---

## 13. Success Criteria

### Pass/Fail

- [ ] All ~540 tests pass
- [ ] Zero flaky tests (100% deterministic)
- [ ] CLI returns exit code 0 on success, 1 on failure
- [ ] JSON/XML output parseable by CI tools

### Coverage

- [ ] Every player card tested for primary effect
- [ ] Every relic tested for trigger condition
- [ ] Every status effect tested for application and decay
- [ ] Top interactions per mechanic category covered
- [ ] Multiplayer state consistency verified

---

## 14. Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Tests too slow | Parallel execution, optimize fixtures, lazy loading |
| Flaky tests | Fixed RNG seed, no timing deps, isolated state |
| Missing edge cases | Review sessions, add tests when bugs found |
| Framework bugs | Self-test suite validates assertions and fixtures |
| Multiplayer complexity | Mock network layer, defer live network tests to Phase 2 |
| Maintenance burden | New Card Checklist (below) |

---

## 15. New Card Checklist

When adding a new card, ensure test coverage:

1. [ ] Add test to appropriate `*_cards_test.gd`
2. [ ] Test primary effect (damage, heal, buff, etc.)
3. [ ] Test any conditional logic (wounded bonus, debuff scaling)
4. [ ] Test any self-applied effects (Exhausted, Decay)
5. [ ] If multi-hit, add interaction test with Copying Machine
6. [ ] Update CARDS_REFERENCE.md
7. [ ] Run smoke tests before commit

---

## Files to Create/Modify

| Path | Action |
|------|--------|
| `scripts/tests/framework/*.gd` | Create framework files |
| `scripts/tests/suites/**/*.gd` | Create test suites |
| `scripts/tests/smoke_test.gd` | Create smoke suite |
| `scripts/tests/run_tests.gd` | Create CLI entry point |
| `project.godot` | Optional: add test autoload |
| `.github/workflows/test.yml` | Optional: CI workflow |

---

**Document Version**: 1.0 (Combined)
**Last Updated**: 2026-01-22
