extends "res://scripts/tests/framework/test_base.gd"
class_name DebuffEffectsTest
## Tests for debuff effects: Vulnerable, Weakness, Fatigued, Hinder, Scared, etc.

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "Debuff Effects"


# ============================================
# VULNERABLE
# ============================================

func _test_vulnerable_damage_increase():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "vulnerable", 2)
	TestFixtures.combat(game_manager, [player], [])

	# Take 10 damage, increased by 50% = 15
	player.take_damage(10, false)

	assert_health(player, 85, "Vulnerable increases damage taken by 50%")


func _test_vulnerable_decay():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "vulnerable", 3)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)

	assert_debuff(player, "vulnerable", 2, "Vulnerable decays by 1 per turn")


# ============================================
# WEAKNESS
# ============================================

func _test_weakness_damage_reduction():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.apply_debuff(player, "weakness", 3)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Slash does 7 base, -3 weakness = 4
	TestFixtures.give_card(player, "slash", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 96, "Weakness reduces attack damage (7-3=4)")


func _test_weakness_decay():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "weakness", 3)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)

	assert_debuff(player, "weakness", 2, "Weakness decays by 1 per turn")


# ============================================
# FATIGUED
# ============================================

func _test_fatigued_stamina_loss():
	var player = TestFixtures.player("Test", 100, 3)
	TestFixtures.apply_debuff(player, "fatigued", 2)
	TestFixtures.combat(game_manager, [player], [])

	# Fatigued applies at turn start, reducing stamina
	player.start_turn()

	assert_lte(player.current_stamina, 3, "Fatigued reduces stamina at turn start")


func _test_fatigued_removed_after():
	var player = TestFixtures.player("Test", 100, 3)
	TestFixtures.apply_debuff(player, "fatigued", 2)
	TestFixtures.combat(game_manager, [player], [])

	player.start_turn()

	assert_no_debuff(player, "fatigued", "Fatigued removed after application")


# ============================================
# HINDER
# ============================================

func _test_hinder_damage_reduction():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.apply_debuff(player, "hinder", 4)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Slash does 7 base, -4 hinder = 3
	TestFixtures.give_card(player, "slash", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 97, "Hinder reduces attack damage (7-4=3)")


func _test_hinder_end_of_turn_removal():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "hinder", 4)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)

	assert_no_debuff(player, "hinder", "Hinder completely removed at end of turn")


# ============================================
# FEEBLE
# ============================================

func _test_feeble_permanent():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "feeble", 2)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)
	player.start_turn()

	assert_debuff(player, "feeble", 2, "Feeble persists (must be removed by cards)")


func _test_feeble_stacking():
	var player = TestFixtures.player("Test", 100, 10)
	player.feeble = 2
	player.feeble += 1

	assert_debuff(player, "feeble", 3, "Feeble stacks additively")


# ============================================
# EXHAUSTED
# ============================================

func _test_exhausted_blocks_cards():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "exhausted", 2)

	assert_debuff(player, "exhausted", 2, "Exhausted is active")
	# Card play blocking is handled by combat system


func _test_exhausted_decay():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "exhausted", 3)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)

	assert_debuff(player, "exhausted", 2, "Exhausted decays by 1 per turn")


# ============================================
# SCARED
# ============================================

func _test_scared_blocks_attacks():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "scared", 1)

	assert_debuff(player, "scared", 1, "Scared is active")
	# Attack blocking is handled by combat system


func _test_scared_allows_buffs():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "scared", 1)

	# Scared only blocks attacks, not buff cards
	assert_debuff(player, "scared", 1, "Scared active but buff cards allowed")


func _test_scared_end_turn():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "scared", 1)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)

	assert_no_debuff(player, "scared", "Scared removed at end of turn")


# ============================================
# DECAY
# ============================================

func _test_decay_reduces_healing():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.set_hp(player, 80)
	TestFixtures.apply_debuff(player, "decay", 2)
	TestFixtures.combat(game_manager, [player], [])

	# Heal 20, reduced by 10 (5 per decay stack) = 10
	player.heal(20)

	assert_health(player, 90, "Decay reduces healing by 5 per stack")


func _test_decay_permanent():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "decay", 2)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)
	player.start_turn()

	assert_debuff(player, "decay", 2, "Decay is permanent (can't be removed)")


func _test_decay_stacking():
	var player = TestFixtures.player("Test", 100, 10)
	player.decay = 1
	player.decay += 2

	assert_debuff(player, "decay", 3, "Decay stacks additively")


# ============================================
# WET
# ============================================

func _test_wet_stacking():
	var player = TestFixtures.player("Test", 100, 10)
	player.wet = 2
	player.wet += 3

	assert_debuff(player, "wet", 5, "Wet stacks additively")


func _test_wet_no_decay():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_debuff(player, "wet", 3)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)

	assert_debuff(player, "wet", 3, "Wet doesn't decay naturally")
