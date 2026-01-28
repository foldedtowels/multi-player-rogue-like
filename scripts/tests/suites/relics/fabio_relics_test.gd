extends "res://scripts/tests/framework/test_base.gd"
class_name FabioRelicsTest
## Tests for Fabio-specific relics

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "Fabio Relics"


# ============================================
# BRASS KNUCKLES
# ============================================

func _test_brass_knuckles_strength():
	var player = TestFixtures.fabio(100, 10)
	TestFixtures.give_relic(player, "brass_knuckles")

	var players: Array[Character] = [player]
	RelicRegistry.apply_fight_start(players)

	assert_buff(player, "strength", 1, "Brass Knuckles grants 1 Strength at fight start")


# ============================================
# DRAGON SCALE CREAM
# ============================================

func _test_dragon_scale_cream_armor():
	var player = TestFixtures.fabio(100, 10)
	TestFixtures.give_relic(player, "dragon_scale_cream")

	var players: Array[Character] = [player]
	RelicRegistry.apply_fight_start(players)

	assert_buff(player, "armor", 2, "Dragon Scale Cream grants 2 Armor at fight start")


# ============================================
# FOREARM TRAINER
# ============================================

func _test_forearm_trainer_cost_reduction():
	var player = TestFixtures.fabio(100, 10)
	TestFixtures.give_relic(player, "forearm_trainer")

	# Big Smack costs 3
	var card = card_db.get_card("big_smack")

	var reduction = RelicRegistry.get_cost_reduction(player, card)

	assert_eq(reduction, 1, "Forearm Trainer reduces cost by 1 for 2+ stamina attacks")


func _test_forearm_trainer_1_cost_no_reduction():
	var player = TestFixtures.fabio(100, 10)
	TestFixtures.give_relic(player, "forearm_trainer")

	# Slash costs 2, but let's test with a 1-cost card
	var card = TestFixtures.make_attack_card("Cheap Attack", 5, 1)

	var reduction = RelicRegistry.get_cost_reduction(player, card)

	assert_eq(reduction, 0, "Forearm Trainer doesn't reduce 1-cost attacks")
