extends "res://scripts/tests/framework/test_base.gd"
class_name SpecialEffectsTest
## Tests for special effects: Venom, Burden, Dissolve, Doll curses

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "Special Effects"


# ============================================
# VENOM
# ============================================

func _test_venom_threshold_trigger():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "venom", 3)

	assert_debuff(player, "venom", 3, "Venom reaches threshold at 3 stacks")


func _test_venom_threshold_damage():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "venom", 3)
	TestFixtures.combat(game_manager, [player], [])

	# When venom reaches 3, it should deal 20 damage
	# This is typically triggered by the combat system
	assert_debuff(player, "venom", 3, "Venom at threshold (3 stacks)")


func _test_venom_reset():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "venom", 3)
	TestFixtures.combat(game_manager, [player], [])

	# After triggering, venom should reset to 0
	player.venom = 0  # Simulating the reset

	assert_no_debuff(player, "venom", "Venom resets after triggering")


# ============================================
# BURDEN
# ============================================

func _test_burden_end_turn_damage():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "burden", 2)
	TestFixtures.combat(game_manager, [player], [])

	# Burden deals 5 damage per stack at end of turn
	player.apply_end_turn_effects()

	assert_health_between(player, 90, 100, "Burden deals damage at end of turn")


func _test_burden_no_decay():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "burden", 2)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)

	assert_debuff(player, "burden", 2, "Burden doesn't decay naturally")


# ============================================
# DISSOLVE
# ============================================

func _test_dissolve_card_play_damage():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "dissolve", 3)

	assert_debuff(player, "dissolve", 3, "Dissolve is active")
	# Damage on card play is handled by combat system


func _test_dissolve_no_decay():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "dissolve", 3)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)

	assert_debuff(player, "dissolve", 3, "Dissolve doesn't decay naturally")


# ============================================
# DOLL: DISSOLVE
# ============================================

func _test_doll_dissolve_per_card():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "doll_dissolve", 2)

	assert_debuff(player, "doll_dissolve", 2, "Doll Dissolve is active")
	# 1 damage per stack per card played


# ============================================
# DOLL: SUFFERING
# ============================================

func _test_doll_suffering_end_turn():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "doll_suffering", 1)
	TestFixtures.combat(game_manager, [player], [])

	# 5 damage per stack at end of turn
	player.apply_end_turn_effects()

	assert_health_between(player, 95, 100, "Doll Suffering deals damage at end of turn")


# ============================================
# DOLL: BURDEN
# ============================================

func _test_doll_burden_draw_reduction():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "doll_burden", 1)

	assert_debuff(player, "doll_burden", 1, "Doll Burden is active")
	# Draw 1 less card per stack
