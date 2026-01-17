extends RefCounted
class_name FabioCardTests
## Test suite for all Fabio (Warrior) cards

var game_manager: Node
var card_db: Node
var results: Array[Dictionary]

func _init(gm: Node, cdb: Node, res: Array[Dictionary]):
	game_manager = gm
	card_db = cdb
	results = res

func run_all():
	print("\n--- FABIO BASE DECK ---")
	_test_slash()
	_test_big_smack()
	_test_duel_purpose()
	_test_rest()
	_test_bulk_up()
	_test_dig_a_hole()
	_test_protector_single_target()
	_test_protector_aoe()
	_test_protective_footwear()
	_test_hunters_instinct()

	print("\n--- FABIO REWARD CARDS ---")
	_test_dual_wield()
	_test_circular_strike()
	_test_cursed_dagger()
	_test_jumping_strike()
	_test_execution()
	_test_execution_wounded_bonus()
	_test_frenzy()
	_test_weak_point()
	_test_weak_point_with_debuffs()
	_test_medkit()
	_test_fighters_spirit()
	_test_fighters_spirit_v2()
	_test_sacrifice()
	_test_leader()
	_test_leader_v2()

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

func assert_gt(actual: int, expected: int, test_name: String, detail: String = "") -> bool:
	var passed = actual > expected
	var msg: String
	if passed:
		msg = "PASS: %s" % test_name
	else:
		msg = "FAIL: %s - Expected %d > %d" % [test_name, actual, expected]
	if detail:
		msg += " (%s)" % detail
	results.append({"name": test_name, "passed": passed, "message": msg})
	print("  " + msg)
	return passed

# =============================================================================
# BASE DECK TESTS
# =============================================================================

func _test_slash():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("slash")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 93, "Slash deals 7 damage")
	assert_eq(card.stamina_cost, 2, "Slash costs 2 stamina")
	assert_eq(card.card_type, Card.CardType.ATTACK, "Slash is an ATTACK card")

func _test_big_smack():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("big_smack")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 90, "Big Smack deals 10 damage")
	assert_eq(card.stamina_cost, 3, "Big Smack costs 3 stamina")

func _test_duel_purpose():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("duel_purpose")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 97, "Duel Purpose deals 3 damage")
	assert_eq(player.shield, 5, "Duel Purpose grants 5 shield")
	assert_eq(card.stamina_cost, 1, "Duel Purpose costs 1 stamina")

func _test_rest():
	var player = TestHelpers.create_test_player("Fabio", 100, 3)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("rest")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.rested, 1, "Rest applies Rested 1")
	assert_eq(card.stamina_cost, 1, "Rest costs 1 stamina")
	assert_eq(card.card_type, Card.CardType.BUFF, "Rest is a BUFF card")

func _test_bulk_up():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("bulk_up")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.invigorated, 1, "Bulk Up applies Invigorated 1")
	assert_eq(player.damage_plus, 2, "Invigorated grants +2 damage")
	assert_eq(player.fatigued, 1, "Bulk Up applies Fatigued 1")
	assert_eq(card.stamina_cost, 0, "Bulk Up costs 0 stamina")

func _test_dig_a_hole():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("dig_a_hole")

	assert_eq(card.stamina_cost, 0, "Dig a Hole costs 0 stamina")
	assert_true(card.plays_immediately, "Dig a Hole plays immediately")
	assert_true(card.grants_card_retain, "Dig a Hole grants card retain")

func _test_protector_single_target():
	var fabio = TestHelpers.create_test_player("Fabio", 100, 10)
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Enemy", 100)
	TestHelpers.setup_combat(game_manager, [fabio, ally], [enemy])

	var card = card_db.get_card("protector")
	TestHelpers.give_card(fabio, card)
	game_manager.apply_card_effects(fabio, fabio.hand[0], ally)

	assert_true(game_manager.protected_by.has(1), "Ally is marked as protected")

	# Enemy attacks ally
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

	var card = card_db.get_card("protector")
	TestHelpers.give_card(fabio, card)
	game_manager.apply_card_effects(fabio, fabio.hand[0], ally)

	# Enemy uses AOE
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
	assert_eq(card.stamina_cost, 1, "Protective Footwear costs 1 stamina")

func _test_hunters_instinct():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("hunters_instinct")

	assert_eq(card.stamina_cost, 1, "Hunter's Instinct costs 1 stamina")
	assert_true(card.plays_immediately, "Hunter's Instinct plays immediately")
	assert_true(card.reveals_boss_intent, "Hunter's Instinct reveals boss intent")

# =============================================================================
# REWARD CARD TESTS
# =============================================================================

func _test_dual_wield():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("dual_wield")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# 2 damage x 2 hits = 4 total
	assert_eq(enemy.current_health, 96, "Dual Wield deals 2x2 = 4 damage")
	assert_eq(card.stamina_cost, 2, "Dual Wield costs 2 stamina")
	assert_eq(card.multi_hit, 2, "Dual Wield has multi_hit: 2")

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
	assert_eq(card.stamina_cost, 1, "Circular Strike costs 1 stamina")

func _test_cursed_dagger():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("cursed_dagger")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 98, "Cursed Dagger deals 2 damage")
	assert_eq(card.stamina_cost, 0, "Cursed Dagger costs 0 stamina")

func _test_jumping_strike():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("jumping_strike")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# No immediate damage
	assert_eq(enemy.current_health, 100, "Jumping Strike deals NO damage on play")
	assert_true(game_manager.delayed_effects.size() > 0, "Jumping Strike queues delayed effect")
	assert_eq(card.stamina_cost, 1, "Jumping Strike costs 1 stamina")

	# Process delayed effects
	TestHelpers.simulate_end_turn(game_manager)
	game_manager._process_delayed_effects()

	assert_eq(enemy.current_health, 95, "Jumping Strike deals 5 damage next turn")

func _test_execution():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("execution")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# Base 4 damage (no wounded bonus)
	assert_eq(enemy.current_health, 96, "Execution deals 4 base damage")
	assert_eq(card.stamina_cost, 2, "Execution costs 2 stamina")

func _test_execution_wounded_bonus():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	# Wound the enemy (below 50% HP)
	TestHelpers.make_wounded(enemy)  # Sets to 40% HP = 40

	var card = card_db.get_card("execution")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# 4 base + 4 wounded bonus = 8 damage
	assert_eq(enemy.current_health, 32, "Execution deals 4+4=8 to wounded target")

func _test_frenzy():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy1 = TestHelpers.create_test_enemy("Enemy1", 100)
	var enemy2 = TestHelpers.create_test_enemy("Enemy2", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy1, enemy2])

	var card = card_db.get_card("frenzy")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_eq(enemy1.current_health, 92, "Frenzy deals 8 to enemy1")
	assert_eq(enemy2.current_health, 92, "Frenzy deals 8 to enemy2 (AOE)")
	assert_eq(player.exhausted, 2, "Frenzy applies 2 Exhausted to caster")
	assert_eq(card.stamina_cost, 2, "Frenzy costs 2 stamina")

func _test_weak_point():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("weak_point")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# No debuffs = 2 base damage only
	assert_eq(enemy.current_health, 98, "Weak Point deals 2 base damage")
	assert_eq(card.bonus_damage_per_debuff, 2, "Weak Point has +2 per debuff bonus")

func _test_weak_point_with_debuffs():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	# Apply 3 debuff stacks to enemy
	TestHelpers.apply_debuffs(enemy, {"poison": 2, "weakness": 1})

	var card = card_db.get_card("weak_point")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# 2 base + (3 debuffs * 2) = 8 damage -> 100 - 8 = 92
	assert_eq(enemy.current_health, 92, "Weak Point deals 2+6=8 with 3 debuffs")

func _test_medkit():
	var player = TestHelpers.create_test_player("Fabio", 50, 10)
	player.current_health = 40
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("medkit")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.current_health, 50, "Medkit heals 10 HP (40->50)")
	assert_eq(player.decay, 1, "Medkit applies Decay 1")
	assert_eq(card.stamina_cost, 2, "Medkit costs 2 stamina")

func _test_fighters_spirit():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	# Apply a debuff to remove
	TestHelpers.apply_debuff(player, "poison", 2)

	var card = card_db.get_card("fighters_spirit")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	# remove_target_debuffs removes entire debuff type, not just 1 stack
	assert_eq(player.poison, 0, "Fighter's Spirit removes debuff type")
	assert_eq(card.stamina_cost, 1, "Fighter's Spirit costs 1 stamina")
	assert_true(card.has_v2, "Fighter's Spirit has V2 option")

func _test_fighters_spirit_v2():
	var player = TestHelpers.create_test_player("Fabio", 100, 10)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("fighters_spirit_v2")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.shield, 5, "Fighter's Spirit V2 grants 5 shield")
	assert_eq(card.stamina_cost, 1, "Fighter's Spirit V2 costs 1 stamina")

func _test_sacrifice():
	var fabio = TestHelpers.create_test_player("Fabio", 100, 10)
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	TestHelpers.setup_combat(game_manager, [fabio, ally], [])

	var card = card_db.get_card("sacrifice")
	TestHelpers.give_card(fabio, card)

	game_manager.apply_card_effects(fabio, fabio.hand[0], ally)

	assert_eq(ally.strength, 1, "Sacrifice grants 1 Strength to ally")
	assert_eq(card.stamina_cost, 1, "Sacrifice costs 1 stamina")

func _test_leader():
	var fabio = TestHelpers.create_test_player("Fabio", 100, 10)
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	TestHelpers.setup_combat(game_manager, [fabio, ally], [])

	var card = card_db.get_card("leader")

	assert_eq(card.stamina_cost, 0, "Leader costs 0 stamina")
	assert_true(card.plays_immediately, "Leader plays immediately")
	assert_eq(card.draw_cards, 1, "Leader draws 1 card for allies")
	assert_true(card.has_v2, "Leader has V2 option")

func _test_leader_v2():
	var fabio = TestHelpers.create_test_player("Fabio", 100, 10)
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	TestHelpers.setup_combat(game_manager, [fabio, ally], [])

	var card = card_db.get_card("leader_v2")

	assert_eq(card.stamina_cost, 0, "Leader V2 costs 0 stamina")
	assert_eq(card.draw_cards, 2, "Leader V2 draws 2 cards for allies")
	assert_eq(card.caster_discards_random, 2, "Leader V2 discards 2 from caster")
