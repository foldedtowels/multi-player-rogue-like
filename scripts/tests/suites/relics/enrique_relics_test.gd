extends "res://scripts/tests/framework/test_base.gd"
class_name EnriqueRelicsTest
## Tests for Enrique-specific relics

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "Enrique Relics"


# ============================================
# PRAYER BOOK
# ============================================

func _test_prayer_book_fight_start_aura():
	var player = TestFixtures.enrique(100, 3, 5)
	TestFixtures.give_relic(player, "prayer_book")

	var players: Array[Character] = [player]
	RelicRegistry.apply_fight_start(players)

	assert_aura(player, 9, "Prayer Book grants +4 aura at fight start (5+4=9)")


# ============================================
# GENTLE HANDS
# ============================================

func _test_gentle_hands_ally_heal_bonus():
	var player = TestFixtures.enrique(100, 3, 5)
	var ally = TestFixtures.player("Ally", 100, 10)
	TestFixtures.give_relic(player, "gentle_hands")
	TestFixtures.combat(game_manager, [player, ally], [])

	var rng = RandomNumberGenerator.new()
	var enemies: Array[Character] = []

	var bonus = RelicRegistry.calculate_heal_bonus(player, ally, 10, enemies, rng)

	assert_eq(bonus, 5, "Gentle Hands adds +5 when healing allies")


func _test_gentle_hands_self_heal_no_bonus():
	var player = TestFixtures.enrique(100, 3, 5)
	TestFixtures.give_relic(player, "gentle_hands")
	TestFixtures.combat(game_manager, [player], [])

	var rng = RandomNumberGenerator.new()
	var enemies: Array[Character] = []

	var bonus = RelicRegistry.calculate_heal_bonus(player, player, 10, enemies, rng)

	assert_eq(bonus, 0, "Gentle Hands doesn't affect self-healing")


# ============================================
# SHINING FEATHER
# ============================================

func _test_shining_feather_aura_threshold():
	var player = TestFixtures.enrique(100, 3, 5)
	TestFixtures.give_relic(player, "shining_feather")
	TestFixtures.combat(game_manager, [player], [])

	RelicRegistry.apply_turn_end(player)

	assert_shield(player, 5, "Shining Feather grants 5 shield at 5+ aura")


func _test_shining_feather_under_5_no_shield():
	var player = TestFixtures.enrique(100, 3, 4)  # Only 4 aura
	TestFixtures.give_relic(player, "shining_feather")
	TestFixtures.combat(game_manager, [player], [])

	RelicRegistry.apply_turn_end(player)

	assert_shield(player, 0, "Shining Feather doesn't trigger under 5 aura")


# ============================================
# ELECTRIFIED IDOL
# ============================================

func _test_electrified_idol_heal_damage():
	var player = TestFixtures.enrique(100, 3, 5)
	var ally = TestFixtures.player("Ally", 100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.give_relic(player, "electrified_idol")
	TestFixtures.combat(game_manager, [player, ally], [enemy])

	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	var enemies: Array[Character] = [enemy]

	# This should trigger damage to random enemy
	RelicRegistry.calculate_heal_bonus(player, ally, 10, enemies, rng)

	assert_health(enemy, 95, "Electrified Idol deals 5 damage when healing ally")


func _test_electrified_idol_self_heal_no_damage():
	var player = TestFixtures.enrique(100, 3, 5)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.give_relic(player, "electrified_idol")
	TestFixtures.combat(game_manager, [player], [enemy])

	var rng = RandomNumberGenerator.new()
	var enemies: Array[Character] = [enemy]

	# Self-heal shouldn't trigger
	RelicRegistry.calculate_heal_bonus(player, player, 10, enemies, rng)

	assert_health(enemy, 100, "Electrified Idol doesn't trigger on self-heal")
