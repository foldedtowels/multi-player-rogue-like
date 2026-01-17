extends RefCounted
class_name MinionCardTests
## Test suite for minion (enemy) cards

var game_manager: Node
var card_db: Node
var results: Array[Dictionary]

func _init(gm: Node, cdb: Node, res: Array[Dictionary]):
	game_manager = gm
	card_db = cdb
	results = res

func run_all():
	print("\n--- SWARM OF RACCOONS ---")
	_test_ankle_nibble()
	_test_swarm()

	print("\n--- ALEX THE MONKEY ---")
	_test_monkey_punch()
	_test_it_bit_my_hand()
	_test_anger()
	_test_anger_boosts_attack()

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
# SWARM OF RACCOONS TESTS
# =============================================================================

func _test_ankle_nibble():
	var player = TestHelpers.create_test_player("Player", 100, 10)
	var raccoon = TestHelpers.create_test_minion("Swarm of Raccoons", 35)
	TestHelpers.setup_combat(game_manager, [player], [raccoon])

	var card = card_db.get_card("ankle_nibble")
	TestHelpers.give_card(raccoon, card)

	game_manager.apply_card_effects(raccoon, raccoon.hand[0], player)

	assert_eq(player.current_health, 95, "Ankle Nibble deals 5 damage")
	assert_eq(card.stamina_cost, 1, "Ankle Nibble costs 1 stamina")

func _test_swarm():
	var p1 = TestHelpers.create_test_player("P1", 100, 10)
	var p2 = TestHelpers.create_test_player("P2", 100, 10)
	var raccoon = TestHelpers.create_test_minion("Swarm of Raccoons", 35)
	TestHelpers.setup_combat(game_manager, [p1, p2], [raccoon])

	var card = card_db.get_card("swarm")
	TestHelpers.give_card(raccoon, card)

	game_manager.apply_card_effects(raccoon, raccoon.hand[0], p1)

	assert_eq(p1.current_health, 97, "Swarm deals 3 damage to player 1")
	assert_eq(p2.current_health, 97, "Swarm deals 3 damage to player 2 (AOE)")
	assert_eq(card.stamina_cost, 1, "Swarm costs 1 stamina")
	assert_true(card.aoe_damage, "Swarm is AOE")

# =============================================================================
# ALEX THE MONKEY TESTS
# =============================================================================

func _test_monkey_punch():
	var player = TestHelpers.create_test_player("Player", 100, 10)
	var alex = TestHelpers.create_test_minion("Alex", 45)
	TestHelpers.setup_combat(game_manager, [player], [alex])

	var card = card_db.get_card("monkey_punch")
	TestHelpers.give_card(alex, card)

	game_manager.apply_card_effects(alex, alex.hand[0], player)

	assert_eq(player.current_health, 95, "Monkey Punch deals 5 damage")
	assert_eq(card.stamina_cost, 1, "Monkey Punch costs 1 stamina")

func _test_it_bit_my_hand():
	var player = TestHelpers.create_test_player("Player", 100, 10)
	var alex = TestHelpers.create_test_minion("Alex", 45)
	TestHelpers.setup_combat(game_manager, [player], [alex])

	var card = card_db.get_card("it_bit_my_hand")
	TestHelpers.give_card(alex, card)

	game_manager.apply_card_effects(alex, alex.hand[0], player)

	assert_eq(player.current_health, 97, "It bit my Hand deals 3 damage")
	assert_eq(card.stamina_cost, 1, "It bit my Hand costs 1 stamina")

func _test_anger():
	var player = TestHelpers.create_test_player("Player", 100, 10)
	var alex = TestHelpers.create_test_minion("Alex", 45)
	TestHelpers.setup_combat(game_manager, [player], [alex])

	var card = card_db.get_card("anger")
	TestHelpers.give_card(alex, card)

	game_manager.apply_card_effects(alex, card, alex)

	assert_eq(alex.strength, 2, "Anger grants Strength +2")
	assert_eq(card.stamina_cost, 0, "Anger costs 0 stamina")

func _test_anger_boosts_attack():
	var player = TestHelpers.create_test_player("Player", 100, 10)
	var alex = TestHelpers.create_test_minion("Alex", 45)
	TestHelpers.setup_combat(game_manager, [player], [alex])

	# Apply Anger first
	var anger = card_db.get_card("anger")
	game_manager.apply_card_effects(alex, anger, alex)

	# Then attack with boosted damage
	var punch = card_db.get_card("monkey_punch")
	game_manager.apply_card_effects(alex, punch, player)

	# 5 base + 2 strength = 7 damage
	assert_eq(player.current_health, 93, "Monkey Punch with Strength deals 7 damage")
