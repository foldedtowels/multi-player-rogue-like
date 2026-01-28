extends "res://scripts/tests/framework/test_base.gd"
class_name DotEffectsTest
## Tests for Damage Over Time effects: Poison, Bleed, Burn

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "DOT Effects"


# ============================================
# POISON
# ============================================

func _test_poison_damage():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "poison", 5)
	TestFixtures.combat(game_manager, [player], [])

	# Simulate DOT application at turn end
	player.apply_dot_damage()

	assert_health(player, 95, "Poison deals damage equal to stacks")


func _test_poison_decay():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "poison", 5)
	TestFixtures.combat(game_manager, [player], [])

	# End turn should decay poison
	player.end_turn(1)

	assert_debuff(player, "poison", 4, "Poison decays by 1 per turn")


func _test_poison_piercing():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_shield(player, 10)
	TestFixtures.apply_debuff(player, "poison", 5)
	TestFixtures.combat(game_manager, [player], [])

	player.apply_dot_damage()

	assert_health(player, 95, "Poison bypasses shield (piercing)")
	assert_shield(player, 10, "Shield remains after poison")


# ============================================
# BLEED
# ============================================

func _test_bleed_damage():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "bleed", 4)
	TestFixtures.combat(game_manager, [player], [])

	player.apply_dot_damage()

	assert_health(player, 96, "Bleed deals damage equal to stacks")


func _test_bleed_decay():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "bleed", 4)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)

	assert_debuff(player, "bleed", 3, "Bleed decays by 1 per turn")


func _test_bleed_piercing():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_shield(player, 10)
	TestFixtures.apply_debuff(player, "bleed", 4)
	TestFixtures.combat(game_manager, [player], [])

	player.apply_dot_damage()

	assert_health(player, 96, "Bleed bypasses shield (piercing)")
	assert_shield(player, 10, "Shield remains after bleed")


# ============================================
# BURN
# ============================================

func _test_burn_damage():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "burn", 3)
	TestFixtures.combat(game_manager, [player], [])

	player.apply_dot_damage()

	assert_health(player, 97, "Burn deals damage equal to stacks")


func _test_burn_no_decay():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "burn", 3)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)

	assert_debuff(player, "burn", 3, "Burn doesn't decay naturally")


func _test_burn_piercing():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_shield(player, 10)
	TestFixtures.apply_debuff(player, "burn", 3)
	TestFixtures.combat(game_manager, [player], [])

	player.apply_dot_damage()

	assert_health(player, 97, "Burn bypasses shield (piercing)")
	assert_shield(player, 10, "Shield remains after burn")
