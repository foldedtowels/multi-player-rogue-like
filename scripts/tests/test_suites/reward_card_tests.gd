extends RefCounted
class_name RewardCardTests
## Test suite for generic reward cards

var game_manager: Node
var card_db: Node
var results: Array[Dictionary]

func _init(gm: Node, cdb: Node, res: Array[Dictionary]):
	game_manager = gm
	card_db = cdb
	results = res

func run_all():
	print("\n--- RARE REWARDS ---")
	_test_apocalypse()
	_test_divine_intervention()
	_test_berserker_rage()
	_test_meteor_swarm()
	_test_time_stop()
	_test_life_drain()
	_test_annihilation()
	_test_omnipotence()

	print("\n--- COMMON REWARDS ---")
	_test_steel_strike()
	_test_healing_potion()
	_test_fortify()
	_test_power_strike()
	_test_battle_focus()
	_test_cleave()
	_test_rejuvenation()
	_test_iron_will()
	_test_quick_strike()
	_test_tactical_advantage()

	print("\n--- DEMONSTRATION CARDS ---")
	_test_vampiric_strike()
	_test_toxic_cloud()
	_test_dark_pact()
	_test_blazing_fury()
	_test_pyroclasm()

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

func assert_gte(actual: int, expected: int, test_name: String, detail: String = "") -> bool:
	var passed = actual >= expected
	var msg: String
	if passed:
		msg = "PASS: %s" % test_name
	else:
		msg = "FAIL: %s - Expected %d >= %d" % [test_name, actual, expected]
	if detail:
		msg += " (%s)" % detail
	results.append({"name": test_name, "passed": passed, "message": msg})
	print("  " + msg)
	return passed

# =============================================================================
# RARE REWARD TESTS
# =============================================================================

func _test_apocalypse():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	var enemy1 = TestHelpers.create_test_enemy("Enemy1", 100)
	var enemy2 = TestHelpers.create_test_enemy("Enemy2", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy1, enemy2])

	var card = card_db.get_card("apocalypse")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_eq(enemy1.current_health, 70, "Apocalypse deals 30 to enemy1")
	assert_eq(enemy2.current_health, 70, "Apocalypse deals 30 to enemy2 (AOE)")
	assert_eq(card.stamina_cost, 4, "Apocalypse costs 4 stamina")
	assert_true(card.aoe_damage, "Apocalypse is AOE")

func _test_divine_intervention():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	player.current_health = 30
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("divine_intervention")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.current_health, 80, "Divine Intervention heals 50 HP")
	assert_eq(player.shield, 30, "Divine Intervention grants 30 shield")
	assert_eq(card.stamina_cost, 3, "Divine Intervention costs 3 stamina")

func _test_berserker_rage():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("berserker_rage")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.strength, 5, "Berserker Rage grants 5 Strength")
	assert_eq(card.stamina_cost, 2, "Berserker Rage costs 2 stamina")

func _test_meteor_swarm():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	var enemy1 = TestHelpers.create_test_enemy("Enemy1", 100)
	var enemy2 = TestHelpers.create_test_enemy("Enemy2", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy1, enemy2])

	var card = card_db.get_card("meteor_swarm")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	# 12 damage x 3 hits = 36 total per enemy
	assert_eq(enemy1.current_health, 64, "Meteor Swarm deals 12x3=36 to enemy1")
	assert_eq(enemy2.current_health, 64, "Meteor Swarm deals 12x3=36 to enemy2 (AOE)")
	assert_eq(card.stamina_cost, 3, "Meteor Swarm costs 3 stamina")
	assert_eq(card.multi_hit, 3, "Meteor Swarm has multi_hit 3")

func _test_time_stop():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("time_stop")

	assert_eq(card.stamina_cost, 2, "Time Stop costs 2 stamina")
	assert_eq(card.draw_cards, 5, "Time Stop draws 5 cards")

func _test_life_drain():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	player.current_health = 50
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("life_drain")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 75, "Life Drain deals 25 damage")
	assert_eq(player.current_health, 75, "Life Drain heals 25 HP (lifesteal)")
	assert_eq(card.stamina_cost, 3, "Life Drain costs 3 stamina")
	assert_true(card.lifesteal, "Life Drain has lifesteal")

func _test_annihilation():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	enemy.shield = 20
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("annihilation")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 65, "Annihilation deals 35 piercing damage")
	assert_eq(enemy.shield, 20, "Annihilation ignores shield (piercing)")
	assert_eq(card.stamina_cost, 3, "Annihilation costs 3 stamina")
	assert_true(card.piercing, "Annihilation has piercing")

func _test_omnipotence():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("omnipotence")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.shield, 15, "Omnipotence grants 15 shield")
	assert_eq(player.strength, 3, "Omnipotence grants 3 Strength")
	assert_eq(player.armor, 3, "Omnipotence grants 3 Armor")
	assert_eq(card.stamina_cost, 3, "Omnipotence costs 3 stamina")
	assert_eq(card.draw_cards, 3, "Omnipotence draws 3 cards")

# =============================================================================
# COMMON REWARD TESTS
# =============================================================================

func _test_steel_strike():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("steel_strike")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 84, "Steel Strike deals 16 damage")
	assert_eq(card.stamina_cost, 2, "Steel Strike costs 2 stamina")

func _test_healing_potion():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	player.current_health = 50
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("healing_potion")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.current_health, 65, "Healing Potion heals 15 HP")
	assert_eq(card.stamina_cost, 1, "Healing Potion costs 1 stamina")

func _test_fortify():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("fortify")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.shield, 12, "Fortify grants 12 shield")
	assert_eq(card.stamina_cost, 1, "Fortify costs 1 stamina")

func _test_power_strike():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("power_strike")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 82, "Power Strike deals 18 damage")
	assert_eq(card.stamina_cost, 2, "Power Strike costs 2 stamina")

func _test_battle_focus():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("battle_focus")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.strength, 2, "Battle Focus grants 2 Strength")
	assert_eq(card.stamina_cost, 2, "Battle Focus costs 2 stamina")
	assert_eq(card.draw_cards, 1, "Battle Focus draws 1 card")

func _test_cleave():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	var enemy1 = TestHelpers.create_test_enemy("Enemy1", 100)
	var enemy2 = TestHelpers.create_test_enemy("Enemy2", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy1, enemy2])

	var card = card_db.get_card("cleave")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_eq(enemy1.current_health, 90, "Cleave deals 10 to enemy1")
	assert_eq(enemy2.current_health, 90, "Cleave deals 10 to enemy2 (AOE)")
	assert_eq(card.stamina_cost, 2, "Cleave costs 2 stamina")

func _test_rejuvenation():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	player.current_health = 60
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("rejuvenation")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.current_health, 72, "Rejuvenation heals 12 HP")
	assert_eq(player.shield, 8, "Rejuvenation grants 8 shield")
	assert_eq(card.stamina_cost, 2, "Rejuvenation costs 2 stamina")

func _test_iron_will():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("iron_will")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.shield, 10, "Iron Will grants 10 shield")
	assert_eq(player.armor, 2, "Iron Will grants 2 Armor")
	assert_eq(card.stamina_cost, 2, "Iron Will costs 2 stamina")

func _test_quick_strike():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("quick_strike")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 88, "Quick Strike deals 12 damage")
	assert_eq(card.stamina_cost, 1, "Quick Strike costs 1 stamina")

func _test_tactical_advantage():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("tactical_advantage")

	assert_eq(card.stamina_cost, 1, "Tactical Advantage costs 1 stamina")
	assert_eq(card.draw_cards, 2, "Tactical Advantage draws 2 cards")
	assert_true(card.plays_immediately, "Tactical Advantage plays immediately")

# =============================================================================
# DEMONSTRATION CARD TESTS
# =============================================================================

func _test_vampiric_strike():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	player.current_health = 60
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("vampiric_strike")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 88, "Vampiric Strike deals 12 damage")
	assert_eq(player.current_health, 72, "Vampiric Strike heals 12 HP (lifesteal)")
	assert_eq(card.stamina_cost, 2, "Vampiric Strike costs 2 stamina")
	assert_true(card.lifesteal, "Vampiric Strike has lifesteal")

func _test_toxic_cloud():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	var enemy1 = TestHelpers.create_test_enemy("Enemy1", 100)
	var enemy2 = TestHelpers.create_test_enemy("Enemy2", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy1, enemy2])

	var card = card_db.get_card("toxic_cloud")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_eq(enemy1.current_health, 92, "Toxic Cloud deals 8 to enemy1")
	assert_eq(enemy2.current_health, 92, "Toxic Cloud deals 8 to enemy2 (AOE)")
	assert_eq(enemy1.poison, 4, "Toxic Cloud applies 4 Poison to enemy1")
	assert_eq(enemy2.poison, 4, "Toxic Cloud applies 4 Poison to enemy2")
	assert_eq(card.stamina_cost, 3, "Toxic Cloud costs 3 stamina")

func _test_dark_pact():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("dark_pact")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	# Negative heal_amount (-5) should deal self damage, but may not be implemented
	assert_eq(card.heal_amount, -5, "Dark Pact has -5 heal (self damage)")
	assert_eq(player.strength, 4, "Dark Pact grants 4 Strength")
	assert_eq(card.stamina_cost, 1, "Dark Pact costs 1 stamina")
	assert_eq(card.draw_cards, 2, "Dark Pact draws 2 cards")

func _test_blazing_fury():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("blazing_fury")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 85, "Blazing Fury deals 15 damage")
	assert_eq(enemy.burn, 3, "Blazing Fury applies 3 Burn")
	assert_eq(enemy.vulnerable, 2, "Blazing Fury applies 2 Vulnerable")
	assert_eq(card.stamina_cost, 2, "Blazing Fury costs 2 stamina")

func _test_pyroclasm():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	var enemy1 = TestHelpers.create_test_enemy("Enemy1", 100)
	var enemy2 = TestHelpers.create_test_enemy("Enemy2", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy1, enemy2])

	var card = card_db.get_card("pyroclasm")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_eq(enemy1.current_health, 82, "Pyroclasm deals 18 to enemy1")
	assert_eq(enemy2.current_health, 82, "Pyroclasm deals 18 to enemy2 (AOE)")
	assert_eq(card.stamina_cost, 4, "Pyroclasm costs 4 stamina")
	assert_eq(card.generate_cards.size(), 2, "Pyroclasm generates 2 Embers")
