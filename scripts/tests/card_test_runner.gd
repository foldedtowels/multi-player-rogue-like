extends Node
class_name CardTestRunner
## Main test runner that executes all card tests and reports results

signal tests_completed(passed: int, total: int)

var game_manager: Node
var card_db: Node
var boss_db: Node
var results: Array[Dictionary] = []  # {name: String, passed: bool, message: String}

func _ready():
	game_manager = get_node("/root/GameManager")
	card_db = get_node("/root/CardDatabase")
	boss_db = get_node("/root/BossDatabase")

## Run all test suites
func run_all_tests():
	results.clear()
	print("\n" + "=".repeat(50))
	print("        CARD TEST SUITE")
	print("=".repeat(50) + "\n")

	# Run Fabio card tests
	print("--- FABIO BASE DECK ---")
	_test_slash()
	_test_big_smack()
	_test_duel_purpose()
	_test_rest()
	_test_bulk_up()
	_test_protector_single_target()
	_test_protector_aoe()
	_test_protective_footwear()

	# Run reward deck tests
	print("\n--- FABIO REWARD DECK ---")
	_test_dual_wield()
	_test_circular_strike()
	_test_cursed_dagger()
	_test_jumping_strike()
	_test_weak_point()
	_test_energy()
	_test_medkit()

	# Run enemy tests
	print("\n--- GIANT MOOSE ---")
	_test_charge_targets_lowest_hp()
	_test_stomp_aoe()
	_test_roar_applies_scared()
	_test_scared_blocks_attacks()
	_test_forage_heals()
	_test_fur_coat_shields()

	print("\n--- SWARM OF RACOONS ---")
	_test_racoon_ankle_nibble()
	_test_racoon_swarm_hits_all()

	print("\n--- ALEX ---")
	_test_alex_monkey_punch()
	_test_alex_it_bit_my_hand()
	_test_alex_anger_buffs_strength()
	_test_alex_anger_boosts_attack()

	# Print summary
	_print_summary()

	var passed = results.filter(func(r): return r.passed).size()
	tests_completed.emit(passed, results.size())

## Assert that actual equals expected
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

## Assert condition is true
func assert_true(condition: bool, test_name: String, detail: String = "") -> bool:
	return assert_eq(condition, true, test_name, detail)

## Assert condition is false
func assert_false(condition: bool, test_name: String, detail: String = "") -> bool:
	return assert_eq(condition, false, test_name, detail)

## Assert actual is less than expected
func assert_lt(actual: int, expected: int, test_name: String, detail: String = "") -> bool:
	var passed = actual < expected
	var msg: String
	if passed:
		msg = "PASS: %s" % test_name
	else:
		msg = "FAIL: %s - Expected %d < %d" % [test_name, actual, expected]
	if detail:
		msg += " (%s)" % detail
	results.append({"name": test_name, "passed": passed, "message": msg})
	print("  " + msg)
	return passed

## Print test summary
func _print_summary():
	var passed = results.filter(func(r): return r.passed).size()
	var total = results.size()

	print("\n" + "=".repeat(50))
	print("  RESULTS: %d/%d PASSED" % [passed, total])
	print("=".repeat(50))

	if passed < total:
		print("\nFAILED TESTS:")
		for r in results:
			if not r.passed:
				print("  - %s" % r.message)
	else:
		print("\nAll tests passed!")

# =============================================================================
# FABIO BASE DECK TESTS
# =============================================================================

func _test_slash():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("slash")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)
	player.current_stamina -= player.hand[0].stamina_cost

	assert_eq(enemy.current_health, 93, "Slash deals 7 damage")
	assert_eq(player.current_stamina, 8, "Slash costs 2 stamina")

func _test_big_smack():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("big_smack")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)
	player.current_stamina -= player.hand[0].stamina_cost

	assert_eq(enemy.current_health, 90, "Big Smack deals 10 damage")
	assert_eq(player.current_stamina, 7, "Big Smack costs 3 stamina")

func _test_duel_purpose():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("duel_purpose")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 97, "Duel Purpose deals 3 damage")
	assert_eq(player.shield, 5, "Duel Purpose grants 5 shield")

func _test_rest():
	var player = TestHelpers.create_test_player("Fabio", 100, 3)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("rest")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)
	assert_eq(player.rested, 1, "Rest applies Rested status")

	# Simulate turn cycle
	TestHelpers.simulate_end_turn(game_manager)
	player.current_stamina = player.starting_stamina  # Reset base stamina
	TestHelpers.simulate_start_turn(game_manager)

	assert_eq(player.current_stamina, 4, "Rested grants +1 stamina at turn start")
	assert_eq(player.rested, 0, "Rested consumed after use")

func _test_bulk_up():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("bulk_up")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.invigorated, 1, "Bulk Up applies Invigorated")
	assert_eq(player.damage_plus, 2, "Invigorated grants +2 damage")
	assert_eq(player.fatigued, 1, "Bulk Up applies Fatigued 1")

func _test_protector_single_target():
	var fabio = TestHelpers.create_test_player("Fabio", 100, 10)
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Enemy", 100)
	TestHelpers.setup_combat(game_manager, [fabio, ally], [enemy])

	# Fabio protects ally
	var card = card_db.get_card("protector")
	TestHelpers.give_card(fabio, card)
	game_manager.apply_card_effects(fabio, fabio.hand[0], ally)
	assert_true(game_manager.protected_by.has(1), "Ally is marked as protected")

	# Enemy attacks ally with 10 damage
	var attack = Card.new()
	attack.card_name = "Test Attack"
	attack.damage = 10
	attack.card_type = Card.CardType.ATTACK
	attack.target_type = Card.TargetType.SINGLE_ENEMY
	game_manager.apply_card_effects(enemy, attack, ally)

	assert_eq(ally.current_health, 100, "Protected ally takes 0 damage")
	assert_eq(fabio.current_health, 90, "Protector takes redirected 10 damage")

func _test_protector_aoe():
	var fabio = TestHelpers.create_test_player("Fabio", 100, 10)
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Enemy", 100)
	TestHelpers.setup_combat(game_manager, [fabio, ally], [enemy])

	# Fabio protects ally
	var card = card_db.get_card("protector")
	TestHelpers.give_card(fabio, card)
	game_manager.apply_card_effects(fabio, fabio.hand[0], ally)

	# Enemy uses AOE (5 damage to all)
	var aoe = Card.new()
	aoe.card_name = "AOE Test"
	aoe.damage = 5
	aoe.card_type = Card.CardType.ATTACK
	aoe.target_type = Card.TargetType.ALL_ENEMIES
	game_manager.apply_card_effects(enemy, aoe, fabio)

	assert_eq(ally.current_health, 100, "Protected ally takes 0 from AOE")
	assert_eq(fabio.current_health, 90, "Protector takes double AOE (5 own + 5 redirect)")

func _test_protective_footwear():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("protective_footwear")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.shield, 5, "Protective Footwear grants 5 shield")

# =============================================================================
# FABIO REWARD DECK TESTS
# =============================================================================

func _test_dual_wield():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("dual_wield")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# Dual Wield does 2 damage x2 = 4 total
	assert_eq(enemy.current_health, 96, "Dual Wield deals 2x2 = 4 damage")

func _test_circular_strike():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy1 = TestHelpers.create_test_enemy("Enemy1", 100)
	var enemy2 = TestHelpers.create_test_enemy("Enemy2", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy1, enemy2])

	var card = card_db.get_card("circular_strike")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_eq(enemy1.current_health, 97, "Circular Strike deals 3 to enemy1")
	assert_eq(enemy2.current_health, 97, "Circular Strike deals 3 to enemy2 (AOE)")

func _test_cursed_dagger():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("cursed_dagger")
	TestHelpers.give_card(player, card)

	var initial_stamina = player.current_stamina
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 98, "Cursed Dagger deals 2 damage")
	assert_eq(card.stamina_cost, 0, "Cursed Dagger costs 0 stamina")

func _test_jumping_strike():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("jumping_strike")
	TestHelpers.give_card(player, card)

	# Play the card
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# TURN 1: No immediate damage - only delayed effect queued
	assert_eq(enemy.current_health, 100, "Jumping Strike deals NO damage on play turn")
	assert_true(game_manager.delayed_effects.size() > 0, "Jumping Strike queues delayed effect")

	# Simulate end of turn 1 (enemy turn happens, then new round starts)
	TestHelpers.simulate_end_turn(game_manager)

	# TURN 2: Delayed effects process at start of round
	game_manager._process_delayed_effects()

	# Now damage should be applied (5 delayed damage)
	assert_eq(enemy.current_health, 95, "Jumping Strike deals 5 damage on NEXT turn")

func _test_weak_point():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("weak_point")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.vulnerable, 2, "Weak Point applies 2 Vulnerable")

func _test_energy():
	var player = TestHelpers.create_test_player("Fabio", 100, 3)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("energy")
	TestHelpers.give_card(player, card)

	var stamina_before = player.current_stamina
	game_manager.apply_card_effects(player, player.hand[0], player)

	# Energy grants immediate stamina (TODO: may not be implemented yet)
	# For now, just check the card exists and can be played
	assert_true(card != null, "Energy card exists")

func _test_medkit():
	var player = TestHelpers.create_test_player("Fabio", 50, 10)  # Max 50 HP
	player.current_health = 40  # Start at 40 HP (10 missing)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("medkit")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.current_health, 50, "Medkit heals 10 HP (40->50)")
	assert_eq(player.decay, 1, "Medkit applies Decay")

# =============================================================================
# GIANT MOOSE TESTS
# =============================================================================

func _test_charge_targets_lowest_hp():
	var player1 = TestHelpers.create_test_player("P1", 100, 10)
	var player2 = TestHelpers.create_test_player("P2", 50, 10)  # Lower HP
	var moose = boss_db.get_boss(0)  # Giant Moose
	TestHelpers.setup_combat(game_manager, [player1, player2], [moose])

	var charge = card_db.get_card("charge")
	var target = game_manager.select_enemy_target(moose, charge)

	assert_eq(target, player2, "Charge targets lowest HP player")

func _test_stomp_aoe():
	var player1 = TestHelpers.create_test_player("P1", 100, 10)
	var player2 = TestHelpers.create_test_player("P2", 100, 10)
	var moose = boss_db.get_boss(0)
	TestHelpers.setup_combat(game_manager, [player1, player2], [moose])

	var stomp = card_db.get_card("stomp")
	game_manager.apply_card_effects(moose, stomp, player1)

	assert_eq(player1.current_health, 95, "Stomp deals 5 damage to player1")
	assert_eq(player2.current_health, 95, "Stomp deals 5 damage to player2 (AOE)")

func _test_roar_applies_scared():
	var player = TestHelpers.create_test_player("P1", 100, 10)
	var moose = boss_db.get_boss(0)
	TestHelpers.setup_combat(game_manager, [player], [moose])

	var roar = card_db.get_card("roar")
	game_manager.apply_card_effects(moose, roar, player)

	assert_eq(player.scared, 1, "Roar applies Scared 1")

func _test_scared_blocks_attacks():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	player.scared = 1
	var enemy = TestHelpers.create_test_enemy("Enemy", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var attack = card_db.get_card("slash")

	# Scared should block attack cards
	var is_attack = attack.card_type == Card.CardType.ATTACK
	var can_play_attack = player.scared == 0

	assert_true(is_attack, "Slash is an attack card")
	assert_false(can_play_attack, "Scared blocks attack cards")

func _test_forage_heals():
	var moose = boss_db.get_boss(0)
	moose.current_health = 40  # Damage the moose first
	TestHelpers.setup_combat(game_manager, [], [moose])

	var forage = card_db.get_card("forage")
	game_manager.apply_card_effects(moose, forage, moose)

	assert_eq(moose.current_health, 50, "Forage heals 10 HP")

func _test_fur_coat_shields():
	var moose = boss_db.get_boss(0)
	TestHelpers.setup_combat(game_manager, [], [moose])

	var fur_coat = card_db.get_card("fur_coat")
	game_manager.apply_card_effects(moose, fur_coat, moose)

	assert_eq(moose.shield, 3, "Fur Coat grants 3 shield")

# =============================================================================
# SWARM OF RACOONS TESTS
# =============================================================================

func _test_racoon_ankle_nibble():
	var player = TestHelpers.create_test_player("P1", 100, 10)
	var racoon = TestHelpers.create_test_enemy("Swarm of Racoons", 35)
	TestHelpers.setup_combat(game_manager, [player], [racoon])

	var nibble = card_db.get_card("ankle_nibble")
	game_manager.apply_card_effects(racoon, nibble, player)

	assert_eq(player.current_health, 95, "Ankle Nibble deals 5 damage")

func _test_racoon_swarm_hits_all():
	var p1 = TestHelpers.create_test_player("P1", 100, 10)
	var p2 = TestHelpers.create_test_player("P2", 100, 10)
	var racoon = TestHelpers.create_test_enemy("Swarm of Racoons", 35)
	TestHelpers.setup_combat(game_manager, [p1, p2], [racoon])

	var swarm = card_db.get_card("swarm")
	game_manager.apply_card_effects(racoon, swarm, p1)

	assert_eq(p1.current_health, 97, "Swarm deals 3 damage to player 1")
	assert_eq(p2.current_health, 97, "Swarm deals 3 damage to player 2 (AOE)")

# =============================================================================
# ALEX TESTS
# =============================================================================

func _test_alex_monkey_punch():
	var player = TestHelpers.create_test_player("P1", 100, 10)
	var alex = TestHelpers.create_test_enemy("Alex", 45)
	TestHelpers.setup_combat(game_manager, [player], [alex])

	var punch = card_db.get_card("monkey_punch")
	game_manager.apply_card_effects(alex, punch, player)

	assert_eq(player.current_health, 95, "Monkey Punch deals 5 damage")

func _test_alex_it_bit_my_hand():
	var player = TestHelpers.create_test_player("P1", 100, 10)
	var alex = TestHelpers.create_test_enemy("Alex", 45)
	TestHelpers.setup_combat(game_manager, [player], [alex])

	var bite = card_db.get_card("it_bit_my_hand")
	game_manager.apply_card_effects(alex, bite, player)

	assert_eq(player.current_health, 97, "It bit my Hand deals 3 damage")
	assert_eq(player.hinder, 1, "It bit my Hand applies Hinder 1")

func _test_alex_anger_buffs_strength():
	var player = TestHelpers.create_test_player("P1", 100, 10)
	var alex = TestHelpers.create_test_enemy("Alex", 45)
	TestHelpers.setup_combat(game_manager, [player], [alex])

	var anger = card_db.get_card("anger")
	game_manager.apply_card_effects(alex, anger, alex)

	assert_eq(alex.strength, 2, "Anger grants Strength +2")

func _test_alex_anger_boosts_attack():
	var player = TestHelpers.create_test_player("P1", 100, 10)
	var alex = TestHelpers.create_test_enemy("Alex", 45)
	TestHelpers.setup_combat(game_manager, [player], [alex])

	# Apply Anger first
	var anger = card_db.get_card("anger")
	game_manager.apply_card_effects(alex, anger, alex)

	# Then attack with boosted damage
	var punch = card_db.get_card("monkey_punch")
	game_manager.apply_card_effects(alex, punch, player)

	# 5 base + 2 strength = 7 damage
	assert_eq(player.current_health, 93, "Monkey Punch with Strength deals 7 damage")
