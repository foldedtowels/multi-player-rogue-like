extends RefCounted
class_name KevinCardTests
## Test suite for all Kevin (Alchemist) cards

var game_manager: Node
var card_db: Node
var results: Array[Dictionary]

func _init(gm: Node, cdb: Node, res: Array[Dictionary]):
	game_manager = gm
	card_db = cdb
	results = res

func run_all():
	print("\n--- KEVIN BASE DECK ---")
	_test_poke()
	_test_meditate()
	_test_fetal_position()
	_test_spell_fire_smash()
	_test_spell_water_ball()
	_test_spell_earthquake()
	_test_spell_fiery_flash()
	_test_spell_ice_shield()
	_test_spell_encapsulation()

	print("\n--- KEVIN ALC (SATCHEL) CARDS ---")
	_test_alc_lightning_storm()
	_test_alc_accumulation()
	_test_alc_giant_shield()

	print("\n--- KEVIN REWARD CARDS ---")
	_test_spell_tsunami()
	_test_repurpose()
	_test_spell_future_vision()
	_test_spell_mortar_pestle()
	_test_spell_enflame()
	_test_spell_restore()
	_test_spell_ring_of_fire()
	_test_reformulate()
	_test_accretion()

# =============================================================================
# ASSERTION HELPERS
# =============================================================================

func assert_eq(actual, expected, test_name: String, detail: String = "") -> bool:
	var passed = actual == expected
	var msg: String
	if passed:
		msg = "PASS: %s" % test_name
	else:
		msg = "FAIL: %s - Expected %s, got %s" % [test_name, str(expected), str(actual)]
	if detail:
		msg += " (%s)" % detail
	results.append({"name": test_name, "passed": passed, "message": msg})
	print("  " + msg)
	return passed

func assert_true(condition: bool, test_name: String, detail: String = "") -> bool:
	return assert_eq(condition, true, test_name, detail)

# =============================================================================
# BASE DECK TESTS
# =============================================================================

func _test_poke():
	var player = TestHelpers.create_kevin_player(100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("poke")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 98, "Poke deals 2 damage")
	assert_eq(card.stamina_cost, 1, "Poke costs 1 stamina")

func _test_meditate():
	var player = TestHelpers.create_kevin_player(100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("meditate")

	assert_eq(card.stamina_cost, 1, "Meditate costs 1 stamina")
	assert_eq(card.draw_cards, 2, "Meditate draws 2 cards")
	assert_eq(card.card_type, Card.CardType.BUFF, "Meditate is a BUFF card")

func _test_fetal_position():
	var player = TestHelpers.create_kevin_player(100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("fetal_position")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.shield, 5, "Fetal Position grants 5 shield")
	assert_eq(card.stamina_cost, 1, "Fetal Position costs 1 stamina")

func _test_spell_fire_smash():
	var player = TestHelpers.create_kevin_player(100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("spell_fire_smash")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 95, "Fire Smash deals 5 damage")
	assert_eq(card.stamina_cost, 2, "Fire Smash costs 2 stamina")
	assert_eq(card.element, Card.ElementType.FIRE, "Fire Smash is FIRE element")

func _test_spell_water_ball():
	var player = TestHelpers.create_kevin_player(100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("spell_water_ball")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 99, "Water Ball deals 1 damage")
	assert_eq(enemy.wet, 1, "Water Ball applies 1 Wet")
	assert_eq(card.stamina_cost, 1, "Water Ball costs 1 stamina")
	assert_eq(card.element, Card.ElementType.WATER, "Water Ball is WATER element")

func _test_spell_earthquake():
	var player = TestHelpers.create_kevin_player(100, 10)
	var enemy1 = TestHelpers.create_test_enemy("Enemy1", 100)
	var enemy2 = TestHelpers.create_test_enemy("Enemy2", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy1, enemy2])

	var card = card_db.get_card("spell_earthquake")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_eq(enemy1.current_health, 98, "Earth Quake deals 2 to enemy1")
	assert_eq(enemy2.current_health, 98, "Earth Quake deals 2 to enemy2 (AOE)")
	assert_eq(card.stamina_cost, 1, "Earth Quake costs 1 stamina")
	assert_eq(card.element, Card.ElementType.EARTH, "Earth Quake is EARTH element")

func _test_spell_fiery_flash():
	var player = TestHelpers.create_kevin_player(100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("spell_fiery_flash")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 96, "Fiery Flash deals 4 damage")
	assert_eq(enemy.hinder, 4, "Fiery Flash applies 4 Hinder")
	assert_eq(card.stamina_cost, 2, "Fiery Flash costs 2 stamina")
	assert_eq(card.element, Card.ElementType.FIRE, "Fiery Flash is FIRE element")

func _test_spell_ice_shield():
	var player = TestHelpers.create_kevin_player(100, 10)
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	TestHelpers.setup_combat(game_manager, [player, ally], [])

	var card = card_db.get_card("spell_ice_shield")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_eq(ally.shield, 5, "Ice Shield grants 5 shield to ally")
	assert_eq(card.stamina_cost, 1, "Ice Shield costs 1 stamina")
	assert_eq(card.element, Card.ElementType.WATER, "Ice Shield is WATER element")

func _test_spell_encapsulation():
	var player = TestHelpers.create_kevin_player(100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("spell_encapsulation")

	assert_eq(card.stamina_cost, 0, "Encapsulation costs 0 stamina")
	assert_true(card.plays_immediately, "Encapsulation plays immediately")
	assert_true(card.grants_card_retain, "Encapsulation grants card retain")
	assert_eq(card.element, Card.ElementType.EARTH, "Encapsulation is EARTH element")

# =============================================================================
# ALC (SATCHEL) CARD TESTS
# =============================================================================

func _test_alc_lightning_storm():
	var player = TestHelpers.create_kevin_player(100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	# Apply Wet to enemy first - Lightning Storm deals damage per Wet stack
	TestHelpers.apply_debuff(enemy, "wet", 2)

	var card = card_db.get_card("alc_lightning_storm")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# Lightning Storm deals 3 damage per Wet stack (2 stacks = 6 damage)
	assert_eq(enemy.current_health, 94, "Alc: Lightning Storm deals 6 damage (3 per Wet stack)")
	assert_eq(card.stamina_cost, 2, "Alc: Lightning Storm costs 2 stamina")
	assert_true(card.is_alc, "Alc: Lightning Storm is an Alc card")

func _test_alc_accumulation():
	var player = TestHelpers.create_kevin_player(100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("alc_accumulation")

	assert_eq(card.stamina_cost, 2, "Alc: Accumulation costs 2 stamina")
	assert_true(card.is_alc, "Alc: Accumulation is an Alc card")
	assert_eq(card.damage_per_spell_discarded, 3, "Alc: Accumulation deals 3 per spell")

func _test_alc_giant_shield():
	var player = TestHelpers.create_kevin_player(100, 10)
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	TestHelpers.setup_combat(game_manager, [player, ally], [])

	var card = card_db.get_card("alc_giant_shield")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.shield, 5, "Alc: Giant Shield gives player 5 shield")
	assert_eq(ally.shield, 5, "Alc: Giant Shield gives ally 5 shield")
	assert_eq(card.stamina_cost, 2, "Alc: Giant Shield costs 2 stamina")
	assert_true(card.is_alc, "Alc: Giant Shield is an Alc card")

# =============================================================================
# REWARD CARD TESTS
# =============================================================================

func _test_spell_tsunami():
	var player = TestHelpers.create_kevin_player(100, 10)
	var enemy1 = TestHelpers.create_test_enemy("Enemy1", 100)
	var enemy2 = TestHelpers.create_test_enemy("Enemy2", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy1, enemy2])

	var card = card_db.get_card("spell_tsunami")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_eq(enemy1.current_health, 96, "Tsunami deals 4 to enemy1")
	assert_eq(enemy2.current_health, 96, "Tsunami deals 4 to enemy2 (AOE)")
	assert_eq(enemy1.wet, 1, "Tsunami applies 1 Wet to enemy1")
	assert_eq(enemy2.wet, 1, "Tsunami applies 1 Wet to enemy2")
	assert_eq(card.stamina_cost, 2, "Tsunami costs 2 stamina")

func _test_repurpose():
	var player = TestHelpers.create_kevin_player(100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("repurpose")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# Base 2 damage without any spells discarded this turn
	assert_eq(enemy.current_health, 98, "Repurpose deals 2 base damage")
	assert_eq(card.stamina_cost, 0, "Repurpose costs 0 stamina")

func _test_spell_future_vision():
	var player = TestHelpers.create_kevin_player(100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("spell_future_vision")

	assert_eq(card.stamina_cost, 0, "Future Vision costs 0 stamina")
	assert_true(card.plays_immediately, "Future Vision plays immediately")
	assert_true(card.reveals_boss_intent, "Future Vision reveals boss intent")
	assert_eq(card.element, Card.ElementType.EARTH, "Future Vision is EARTH element")

func _test_spell_mortar_pestle():
	var player = TestHelpers.create_kevin_player(100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("spell_mortar_pestle")

	assert_eq(card.stamina_cost, 0, "Mortar and Pestle costs 0 stamina")
	assert_true(card.plays_immediately, "Mortar and Pestle plays immediately")
	assert_eq(card.draw_cards, 2, "Mortar and Pestle draws 2 cards")
	assert_eq(card.element, Card.ElementType.EARTH, "Mortar and Pestle is EARTH element")

func _test_spell_enflame():
	var player = TestHelpers.create_kevin_player(100, 10)
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	TestHelpers.setup_combat(game_manager, [player, ally], [])

	var card = card_db.get_card("spell_enflame")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_eq(ally.damage_plus, 2, "Enflame grants +2 damage")
	assert_eq(card.stamina_cost, 1, "Enflame costs 1 stamina")
	assert_eq(card.element, Card.ElementType.FIRE, "Enflame is FIRE element")

func _test_spell_restore():
	var player = TestHelpers.create_kevin_player(100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("spell_restore")

	# Verify card properties (effect not fully implemented yet)
	assert_true(card.remove_all_wet, "Restore has remove_all_wet")
	assert_eq(card.heal_per_wet_removed, 5, "Restore heals 5 per Wet removed")
	assert_eq(card.stamina_cost, 1, "Restore costs 1 stamina")
	assert_eq(card.element, Card.ElementType.WATER, "Restore is WATER element")

func _test_spell_ring_of_fire():
	var player = TestHelpers.create_kevin_player(100, 10)
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	TestHelpers.setup_combat(game_manager, [player, ally], [])

	var card = card_db.get_card("spell_ring_of_fire")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_eq(ally.shield, 5, "Ring Of Fire grants 5 shield")
	assert_eq(ally.ring_of_fire, 1, "Ring Of Fire applies ring_of_fire status")
	assert_eq(card.stamina_cost, 1, "Ring Of Fire costs 1 stamina")
	assert_eq(card.element, Card.ElementType.FIRE, "Ring Of Fire is FIRE element")

func _test_reformulate():
	var player = TestHelpers.create_kevin_player(100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("reformulate")

	assert_eq(card.stamina_cost, 0, "Reformulate costs 0 stamina")
	assert_eq(card.discard_spell_requirement, 1, "Reformulate requires discarding 1 spell")
	assert_eq(card.choose_spell_from_deck, 1, "Reformulate searches for 1 spell")

func _test_accretion():
	var player = TestHelpers.create_kevin_player(100, 10)
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	TestHelpers.setup_combat(game_manager, [player, ally], [])

	var card = card_db.get_card("accretion")

	assert_eq(card.stamina_cost, 0, "Accretion costs 0 stamina")
	assert_eq(card.discard_spell_requirement, 2, "Accretion requires discarding 2 spells")
	assert_eq(card.target_stamina_gain, 1, "Accretion grants target 1 stamina")
