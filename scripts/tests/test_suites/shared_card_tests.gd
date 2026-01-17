extends RefCounted
class_name SharedCardTests
## Test suite for shared/utility cards

var game_manager: Node
var card_db: Node
var results: Array[Dictionary]

func _init(gm: Node, cdb: Node, res: Array[Dictionary]):
	game_manager = gm
	card_db = cdb
	results = res

func run_all():
	print("\n--- SHARED CARDS ---")
	_test_energy()
	_test_ember()

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
# SHARED CARD TESTS
# =============================================================================

func _test_energy():
	var player = TestHelpers.create_test_player("Test", 100, 5)
	player.current_stamina = 3
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("energy")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.current_stamina, 4, "Energy grants 1 stamina")
	assert_eq(card.stamina_cost, 0, "Energy costs 0 stamina")
	assert_true(card.plays_immediately, "Energy plays immediately")
	assert_eq(card.stamina_gain, 1, "Energy has stamina_gain 1")

func _test_ember():
	var player = TestHelpers.create_test_player("Test", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("ember")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 96, "Ember deals 4 damage")
	assert_eq(card.stamina_cost, 0, "Ember costs 0 stamina")
	assert_eq(card.card_type, Card.CardType.ATTACK, "Ember is an ATTACK card")
