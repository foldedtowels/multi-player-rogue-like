extends RefCounted
class_name EnriqueCardTests
## Test suite for all Enrique (Cleric) cards

var game_manager: Node
var card_db: Node
var results: Array[Dictionary]

func _init(gm: Node, cdb: Node, res: Array[Dictionary]):
	game_manager = gm
	card_db = cdb
	results = res

func run_all():
	print("\n--- ENRIQUE BASE DECK ---")
	_test_expulsion()
	_test_expulsion_with_aura()
	_test_focused_purge()
	_test_holy_plight()
	_test_prayer_beads()
	_test_humble_request()
	_test_divine_reflection()
	_test_healing_aura()
	_test_magical_purge()
	_test_story_of_jacob()
	_test_protection()

	print("\n--- ENRIQUE REWARD CARDS ---")
	_test_divine_force()
	_test_divine_force_v2()
	_test_purging_water()
	_test_divine_barrier()
	_test_refuge()
	_test_gift()
	_test_divine_gift()
	_test_guy_with_beard()

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

func assert_lte(actual: int, expected: int, test_name: String, detail: String = "") -> bool:
	var passed = actual <= expected
	var msg: String
	if passed:
		msg = "PASS: %s" % test_name
	else:
		msg = "FAIL: %s - Expected %d <= %d" % [test_name, actual, expected]
	if detail:
		msg += " (%s)" % detail
	results.append({"name": test_name, "passed": passed, "message": msg})
	print("  " + msg)
	return passed

# =============================================================================
# BASE DECK TESTS
# =============================================================================

func _test_expulsion():
	var player = TestHelpers.create_enrique_player(100, 10, 0)  # 0 aura
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("expulsion")

	assert_eq(card.stamina_cost, 2, "Expulsion costs 2 stamina")
	assert_true(card.aura_cost_all, "Expulsion spends all aura")
	assert_eq(card.damage_per_aura_spent, 3, "Expulsion deals 3 per aura")
	assert_true(card.aoe_damage, "Expulsion is AOE")

func _test_expulsion_with_aura():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 4  # Set current aura
	var enemy1 = TestHelpers.create_test_enemy("Enemy1", 100)
	var enemy2 = TestHelpers.create_test_enemy("Enemy2", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy1, enemy2])

	var card = card_db.get_card("expulsion")

	# Verify card properties for aura-based damage
	assert_true(card.aura_cost_all, "Expulsion spends all aura")
	assert_eq(card.damage_per_aura_spent, 3, "Expulsion deals 3 damage per aura")
	assert_true(card.aoe_damage, "Expulsion hits all enemies")

func _test_focused_purge():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 0
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("focused_purge")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 97, "Focused Purge deals 3 damage")
	assert_eq(player.current_aura, 1, "Focused Purge grants 1 aura")
	assert_eq(card.stamina_cost, 1, "Focused Purge costs 1 stamina")

func _test_holy_plight():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 3
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("holy_plight")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 95, "Holy Plight deals 5 damage")
	assert_eq(card.stamina_cost, 1, "Holy Plight costs 1 stamina")
	assert_eq(card.aura_cost, 2, "Holy Plight has aura_cost 2")

func _test_prayer_beads():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 2
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("prayer_beads")

	assert_eq(card.stamina_cost, 1, "Prayer Beads costs 1 stamina")
	assert_eq(card.aura_cost, 1, "Prayer Beads has aura_cost 1")
	assert_true(card.damage_is_d6, "Prayer Beads damage is D6")

func _test_humble_request():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 1
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("humble_request")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.current_aura, 3, "Humble Request grants 2 aura")
	assert_eq(card.stamina_cost, 1, "Humble Request costs 1 stamina")
	assert_eq(card.aura_gain, 2, "Humble Request has aura_gain 2")

func _test_divine_reflection():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 4
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	TestHelpers.setup_combat(game_manager, [player, ally], [])

	var card = card_db.get_card("divine_reflection")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_eq(ally.played_twice, 1, "Divine Reflection grants played_twice")
	assert_eq(card.stamina_cost, 0, "Divine Reflection costs 0 stamina")
	assert_eq(card.aura_cost, 3, "Divine Reflection has aura_cost 3")

func _test_healing_aura():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 3
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	ally.current_health = 50
	TestHelpers.setup_combat(game_manager, [player, ally], [])

	var card = card_db.get_card("healing_aura")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_eq(ally.current_health, 60, "Healing Aura heals 10 HP")
	assert_eq(player.decay, 1, "Healing Aura applies 1 Decay to caster")
	assert_eq(card.stamina_cost, 0, "Healing Aura costs 0 stamina")
	assert_eq(card.aura_cost, 2, "Healing Aura has aura_cost 2")

func _test_magical_purge():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 3
	TestHelpers.apply_debuff(player, "poison", 3)
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("magical_purge")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	# remove_target_debuffs removes entire debuff type
	assert_eq(player.poison, 0, "Magical Purge removes debuff type")
	assert_eq(card.stamina_cost, 0, "Magical Purge costs 0 stamina")
	assert_eq(card.aura_cost, 2, "Magical Purge has aura_cost 2")

func _test_story_of_jacob():
	var player = TestHelpers.create_enrique_player(100, 10, 10)
	player.current_aura = 0
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("story_of_jacob")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.current_aura, 5, "Story of Jacob grants 5 aura")
	assert_eq(player.fatigued, 1, "Story of Jacob applies 1 Fatigued")
	assert_eq(card.stamina_cost, 1, "Story of Jacob costs 1 stamina")

func _test_protection():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 2
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	TestHelpers.setup_combat(game_manager, [player, ally], [])

	var card = card_db.get_card("protection")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_eq(ally.shield, 5, "Protection grants 5 shield")
	assert_eq(card.stamina_cost, 1, "Protection costs 1 stamina")
	assert_eq(card.aura_cost, 1, "Protection has aura_cost 1")

# =============================================================================
# REWARD CARD TESTS
# =============================================================================

func _test_divine_force():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 3
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	ally.current_health = 70
	TestHelpers.setup_combat(game_manager, [player, ally], [])

	var card = card_db.get_card("divine_force")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_eq(ally.current_health, 80, "Divine Force heals 10 HP")
	assert_eq(player.decay, 1, "Divine Force applies 1 Decay to caster")
	assert_eq(card.stamina_cost, 2, "Divine Force costs 2 stamina")
	assert_eq(card.aura_cost, 2, "Divine Force has aura_cost 2")
	assert_true(card.has_v2, "Divine Force has V2 option")

func _test_divine_force_v2():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 3
	var enemy = TestHelpers.create_test_enemy("Target", 100)
	TestHelpers.setup_combat(game_manager, [player], [enemy])

	var card = card_db.get_card("divine_force_v2")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_eq(enemy.current_health, 94, "Divine Force V2 deals 6 damage")
	assert_eq(card.stamina_cost, 2, "Divine Force V2 costs 2 stamina")
	assert_eq(card.aura_cost, 2, "Divine Force V2 has aura_cost 2")

func _test_purging_water():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 2
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	TestHelpers.apply_debuff(ally, "poison", 2)
	TestHelpers.setup_combat(game_manager, [player, ally], [])

	var card = card_db.get_card("purging_water")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], ally)

	# remove_target_debuffs removes entire debuff type
	assert_eq(ally.poison, 0, "Purging Water removes debuff from ally")
	assert_eq(card.stamina_cost, 1, "Purging Water costs 1 stamina")
	assert_eq(card.aura_cost, 1, "Purging Water has aura_cost 1")

func _test_divine_barrier():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 4
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	TestHelpers.setup_combat(game_manager, [player, ally], [])

	var card = card_db.get_card("divine_barrier")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_eq(ally.invincible, 1, "Divine Barrier grants Invincible")
	assert_eq(card.stamina_cost, 1, "Divine Barrier costs 1 stamina")
	assert_eq(card.aura_cost, 3, "Divine Barrier has aura_cost 3")

func _test_refuge():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 2
	TestHelpers.setup_combat(game_manager, [player], [])

	var card = card_db.get_card("refuge")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_eq(player.shield, 5, "Refuge grants 5 shield")
	assert_eq(player.current_aura, 3, "Refuge grants 1 aura (2+1=3)")
	assert_eq(card.stamina_cost, 1, "Refuge costs 1 stamina")

func _test_gift():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 3
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	TestHelpers.setup_combat(game_manager, [player, ally], [])

	var card = card_db.get_card("gift")

	assert_eq(card.stamina_cost, 0, "Gift costs 0 stamina")
	assert_eq(card.aura_cost, 2, "Gift has aura_cost 2")
	assert_eq(card.draw_cards, 2, "Gift draws 2 cards for target")

func _test_divine_gift():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 3
	var ally = TestHelpers.create_test_player("Ally", 100, 5)
	ally.current_stamina = 3
	TestHelpers.setup_combat(game_manager, [player, ally], [])

	var card = card_db.get_card("divine_gift")
	TestHelpers.give_card(player, card)

	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_eq(ally.current_stamina, 5, "Divine Gift grants 2 stamina to ally")
	assert_eq(card.stamina_cost, 2, "Divine Gift costs 2 stamina")
	assert_eq(card.aura_cost, 2, "Divine Gift has aura_cost 2")

func _test_guy_with_beard():
	var player = TestHelpers.create_enrique_player(100, 10, 5)
	player.current_aura = 3
	var ally = TestHelpers.create_test_player("Ally", 100, 10)
	TestHelpers.setup_combat(game_manager, [player, ally], [])

	var card = card_db.get_card("guy_with_beard")

	assert_eq(card.stamina_cost, 0, "Guy with Beard costs 0 stamina")
	assert_eq(card.aura_cost, 2, "Guy with Beard has aura_cost 2")
	assert_eq(card.all_players_draw, 1, "Guy with Beard draws 1 for all players")
