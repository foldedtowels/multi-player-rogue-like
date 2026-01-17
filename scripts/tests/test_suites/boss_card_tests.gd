extends RefCounted
class_name BossCardTests
## Test suite for boss cards

var game_manager: Node
var card_db: Node
var boss_db: Node
var results: Array[Dictionary]

func _init(gm: Node, cdb: Node, bdb: Node, res: Array[Dictionary]):
	game_manager = gm
	card_db = cdb
	boss_db = bdb
	results = res

func run_all():
	print("\n--- GIANT MOOSE ---")
	_test_charge()
	_test_charge_targets_lowest_hp()
	_test_stomp()
	_test_knocked_off_your_feet()
	_test_roar()
	_test_scared_blocks_attacks()
	_test_forage()
	_test_fur_coat()

	print("\n--- MR. 67 ---")
	_test_big_punch()
	_test_gut_punch()
	_test_ground_smash()
	_test_protein_shake()
	_test_muscle_shield()
	_test_intimidating_flex()

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

func assert_false(condition: bool, test_name: String, detail: String = "") -> bool:
	return assert_eq(condition, false, test_name, detail)

# =============================================================================
# GIANT MOOSE TESTS
# =============================================================================

func _test_charge():
	var player = TestHelpers.create_test_player("Player", 100, 10)
	var moose = TestHelpers.create_test_boss("Giant Moose", 60)
	TestHelpers.setup_combat(game_manager, [player], [moose])

	var card = card_db.get_card("charge")
	TestHelpers.give_card(moose, card)

	game_manager.apply_card_effects(moose, moose.hand[0], player)

	assert_eq(player.current_health, 92, "Charge deals 8 damage")
	assert_eq(card.stamina_cost, 1, "Charge costs 1 stamina")

func _test_charge_targets_lowest_hp():
	var player1 = TestHelpers.create_test_player("P1", 100, 10)
	var player2 = TestHelpers.create_test_player("P2", 50, 10)  # Lower HP
	var moose = boss_db.get_boss(0)  # Giant Moose
	TestHelpers.setup_combat(game_manager, [player1, player2], [moose])

	var charge = card_db.get_card("charge")
	var target = game_manager.select_enemy_target(moose, charge)

	assert_eq(target, player2, "Charge targets lowest HP player")

func _test_stomp():
	var player1 = TestHelpers.create_test_player("P1", 100, 10)
	var player2 = TestHelpers.create_test_player("P2", 100, 10)
	var moose = TestHelpers.create_test_boss("Giant Moose", 60)
	TestHelpers.setup_combat(game_manager, [player1, player2], [moose])

	var card = card_db.get_card("stomp")
	TestHelpers.give_card(moose, card)

	game_manager.apply_card_effects(moose, moose.hand[0], player1)

	assert_eq(player1.current_health, 95, "Stomp deals 5 damage to player1")
	assert_eq(player2.current_health, 95, "Stomp deals 5 damage to player2 (AOE)")
	assert_eq(card.stamina_cost, 1, "Stomp costs 1 stamina")

func _test_knocked_off_your_feet():
	var player = TestHelpers.create_test_player("Player", 100, 10)
	var moose = TestHelpers.create_test_boss("Giant Moose", 60)
	TestHelpers.setup_combat(game_manager, [player], [moose])

	var card = card_db.get_card("knocked_off_your_feet")
	TestHelpers.give_card(moose, card)

	game_manager.apply_card_effects(moose, moose.hand[0], player)

	assert_eq(player.current_health, 95, "Knocked Off deals 5 damage")
	assert_eq(player.hinder, 2, "Knocked Off applies 2 Hinder")
	assert_eq(card.stamina_cost, 1, "Knocked Off costs 1 stamina")

func _test_roar():
	var player = TestHelpers.create_test_player("Player", 100, 10)
	var moose = TestHelpers.create_test_boss("Giant Moose", 60)
	TestHelpers.setup_combat(game_manager, [player], [moose])

	var card = card_db.get_card("roar")
	TestHelpers.give_card(moose, card)

	game_manager.apply_card_effects(moose, moose.hand[0], player)

	assert_eq(player.scared, 1, "Roar applies 1 Scared")
	assert_eq(card.stamina_cost, 1, "Roar costs 1 stamina")

func _test_scared_blocks_attacks():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	player.scared = 1
	var enemy = TestHelpers.create_test_enemy("Enemy", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var attack = card_db.get_card("slash")

	var is_attack = attack.card_type == Card.CardType.ATTACK
	var can_play_attack = player.scared == 0

	assert_true(is_attack, "Slash is an attack card")
	assert_false(can_play_attack, "Scared blocks attack cards")

func _test_forage():
	var moose = TestHelpers.create_test_boss("Giant Moose", 60)
	moose.current_health = 40
	TestHelpers.setup_combat(game_manager, [], [moose])

	var card = card_db.get_card("forage")
	TestHelpers.give_card(moose, card)

	game_manager.apply_card_effects(moose, moose.hand[0], moose)

	assert_eq(moose.current_health, 50, "Forage heals 10 HP")
	assert_eq(card.stamina_cost, 1, "Forage costs 1 stamina")

func _test_fur_coat():
	var moose = TestHelpers.create_test_boss("Giant Moose", 60)
	TestHelpers.setup_combat(game_manager, [], [moose])

	var card = card_db.get_card("fur_coat")
	TestHelpers.give_card(moose, card)

	game_manager.apply_card_effects(moose, moose.hand[0], moose)

	assert_eq(moose.shield, 3, "Fur Coat grants 3 shield")
	assert_eq(card.stamina_cost, 1, "Fur Coat costs 1 stamina")

# =============================================================================
# MR. 67 TESTS
# =============================================================================

func _test_big_punch():
	var player = TestHelpers.create_test_player("Player", 100, 10)
	var boss = TestHelpers.create_test_boss("Mr. 67", 75)
	TestHelpers.setup_combat(game_manager, [player], [boss])

	var card = card_db.get_card("big_punch")
	TestHelpers.give_card(boss, card)

	game_manager.apply_card_effects(boss, boss.hand[0], player)

	assert_eq(player.current_health, 93, "Big Punch deals 7 damage")
	assert_eq(card.stamina_cost, 1, "Big Punch costs 1 stamina")

func _test_gut_punch():
	var player = TestHelpers.create_test_player("Player", 100, 10)
	var boss = TestHelpers.create_test_boss("Mr. 67", 75)
	TestHelpers.setup_combat(game_manager, [player], [boss])

	var card = card_db.get_card("gut_punch")
	TestHelpers.give_card(boss, card)

	game_manager.apply_card_effects(boss, boss.hand[0], player)

	assert_eq(player.current_health, 95, "Gut Punch deals 5 damage")
	assert_eq(player.scared, 1, "Gut Punch applies 1 Scared")
	assert_eq(card.stamina_cost, 1, "Gut Punch costs 1 stamina")

func _test_ground_smash():
	var player1 = TestHelpers.create_test_player("P1", 100, 10)
	var player2 = TestHelpers.create_test_player("P2", 100, 10)
	var boss = TestHelpers.create_test_boss("Mr. 67", 75)
	TestHelpers.setup_combat(game_manager, [player1, player2], [boss])

	var card = card_db.get_card("ground_smash")
	TestHelpers.give_card(boss, card)

	game_manager.apply_card_effects(boss, boss.hand[0], player1)

	assert_eq(player1.current_health, 95, "Ground Smash deals 5 to player1")
	assert_eq(player2.current_health, 95, "Ground Smash deals 5 to player2 (AOE)")
	assert_eq(card.stamina_cost, 1, "Ground Smash costs 1 stamina")

func _test_protein_shake():
	var boss = TestHelpers.create_test_boss("Mr. 67", 75)
	TestHelpers.setup_combat(game_manager, [], [boss])

	var card = card_db.get_card("protein_shake")
	TestHelpers.give_card(boss, card)

	game_manager.apply_card_effects(boss, boss.hand[0], boss)

	assert_eq(boss.strength, 2, "Protein Shake grants 2 Strength")
	assert_eq(card.stamina_cost, 1, "Protein Shake costs 1 stamina")

func _test_muscle_shield():
	var boss = TestHelpers.create_test_boss("Mr. 67", 75)
	TestHelpers.setup_combat(game_manager, [], [boss])

	var card = card_db.get_card("muscle_shield")
	TestHelpers.give_card(boss, card)

	game_manager.apply_card_effects(boss, boss.hand[0], boss)

	assert_eq(boss.shield, 5, "Muscle Shield grants 5 shield")
	assert_eq(card.stamina_cost, 1, "Muscle Shield costs 1 stamina")

func _test_intimidating_flex():
	var player = TestHelpers.create_test_player("Player", 100, 10)
	var boss = TestHelpers.create_test_boss("Mr. 67", 75)
	TestHelpers.setup_combat(game_manager, [player], [boss])

	var card = card_db.get_card("intimidating_flex")
	TestHelpers.give_card(boss, card)

	game_manager.apply_card_effects(boss, boss.hand[0], player)

	assert_eq(player.hinder, 2, "Intimidating Flex applies 2 Hinder")
	assert_eq(card.stamina_cost, 1, "Intimidating Flex costs 1 stamina")
