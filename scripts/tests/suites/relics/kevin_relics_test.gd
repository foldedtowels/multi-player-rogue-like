extends "res://scripts/tests/framework/test_base.gd"
class_name KevinRelicsTest
## Tests for Kevin-specific relics

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "Kevin Relics"


# ============================================
# WATER STONE
# ============================================

func _test_water_stone_double_wet():
	var player = TestFixtures.kevin(100, 10)
	TestFixtures.give_relic(player, "water_stone")

	var extra_wet = RelicRegistry.apply_on_debuff_applied(player, "wet", 2)

	assert_eq(extra_wet, 2, "Water Stone doubles Wet application")


func _test_water_stone_other_debuffs_no_effect():
	var player = TestFixtures.kevin(100, 10)
	TestFixtures.give_relic(player, "water_stone")

	var extra = RelicRegistry.apply_on_debuff_applied(player, "poison", 3)

	assert_eq(extra, 0, "Water Stone doesn't affect non-Wet debuffs")


# ============================================
# FAMILIAR BRACELET
# ============================================

func _test_familiar_bracelet_non_spell_bonus():
	var player = TestFixtures.kevin(100, 10)
	TestFixtures.give_relic(player, "familiar_bracelet")

	# Poke is a non-spell attack
	var card = card_db.get_card("poke")

	var bonus = RelicRegistry.get_damage_bonus(player, card)

	assert_eq(bonus, 2, "Familiar Bracelet adds +2 to non-spell cards")


func _test_familiar_bracelet_spell_no_bonus():
	var player = TestFixtures.kevin(100, 10)
	TestFixtures.give_relic(player, "familiar_bracelet")

	# Fire Smash is a spell (has element)
	var card = card_db.get_card("spell_fire_smash")

	var bonus = RelicRegistry.get_damage_bonus(player, card)

	assert_eq(bonus, 0, "Familiar Bracelet doesn't affect spells")


# ============================================
# WOODEN CAULDRON
# ============================================

func _test_wooden_cauldron_brew_draw():
	var player = TestFixtures.kevin(100, 10)
	TestFixtures.give_relic(player, "wooden_cauldron")
	TestFixtures.combat(game_manager, [player], [])

	# Add cards to deck
	for i in range(5):
		var card = TestFixtures.make_attack_card("TestCard%d" % i, 5)
		player.deck.append(card)

	var initial_hand = player.hand.size()

	RelicRegistry.apply_on_brew(player)

	assert_eq(player.hand.size(), initial_hand + 1, "Wooden Cauldron draws 1 card after brewing")
