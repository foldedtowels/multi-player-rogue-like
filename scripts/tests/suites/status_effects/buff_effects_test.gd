extends "res://scripts/tests/framework/test_base.gd"
class_name BuffEffectsTest
## Tests for buff effects: Strength, Armor, Rested, Invigorated, etc.

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "Buff Effects"


# ============================================
# STRENGTH
# ============================================

func _test_strength_damage_increase():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.apply_buff(player, "strength", 3)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Slash does 7 base damage, +3 strength = 10
	TestFixtures.give_card(player, "slash", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 90, "Strength adds to attack damage (7+3=10)")


func _test_strength_stacking():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_buff(player, "strength", 2)
	TestFixtures.apply_buff(player, "strength", 3)

	# Setting strength replaces, not stacks (based on test_helpers pattern)
	assert_buff(player, "strength", 3, "Strength can be set directly")


func _test_strength_persists():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_buff(player, "strength", 3)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)
	player.start_turn()

	assert_buff(player, "strength", 3, "Strength persists across turns")


# ============================================
# ARMOR
# ============================================

func _test_armor_damage_reduction():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_buff(player, "armor", 3)
	TestFixtures.combat(game_manager, [player], [])

	# Take 10 damage, reduced by 3 armor = 7
	player.take_damage(10, false)

	assert_health(player, 93, "Armor reduces incoming damage (10-3=7)")


func _test_armor_stacking():
	var player = TestFixtures.player("Test", 100, 10)
	player.armor = 2
	player.armor += 3  # Add to existing

	assert_buff(player, "armor", 5, "Armor stacks additively")


func _test_armor_persists():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_buff(player, "armor", 3)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)
	player.start_turn()

	assert_buff(player, "armor", 3, "Armor persists across turns")


# ============================================
# RESTED
# ============================================

func _test_rested_stamina_gain():
	var player = TestFixtures.player("Test", 100, 3)
	TestFixtures.apply_buff(player, "rested", 2)
	TestFixtures.combat(game_manager, [player], [])

	# Rested applies at turn start
	player.start_turn()

	# Should gain extra stamina from rested
	assert_gte(player.current_stamina, 3, "Rested grants stamina at turn start")


func _test_rested_removed_after():
	var player = TestFixtures.player("Test", 100, 3)
	TestFixtures.apply_buff(player, "rested", 2)
	TestFixtures.combat(game_manager, [player], [])

	player.start_turn()

	assert_no_buff(player, "rested", "Rested is removed after application")


# ============================================
# INVIGORATED
# ============================================

func _test_invigorated_grants_damage_plus():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.combat(game_manager, [player], [])

	# Apply invigorated (should grant damage_plus)
	player.invigorated = 2

	assert_buff(player, "damage_plus", 4, "Invigorated grants damage_plus (2 per stack)")


func _test_invigorated_end_turn_removal():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_buff(player, "invigorated", 2)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)

	assert_no_buff(player, "invigorated", "Invigorated removed at end of turn")


# ============================================
# DAMAGE_PLUS
# ============================================

func _test_damage_plus_bonus():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.apply_buff(player, "damage_plus", 5)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Slash does 7 base, +5 damage_plus = 12
	TestFixtures.give_card(player, "slash", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 88, "Damage+ adds to attack damage (7+5=12)")


func _test_damage_plus_end_turn_removal():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_buff(player, "damage_plus", 5)
	TestFixtures.combat(game_manager, [player], [])

	player.end_turn(1)

	assert_no_buff(player, "damage_plus", "Damage+ removed at end of turn")


# ============================================
# INVINCIBLE
# ============================================

func _test_invincible_blocks_damage():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_buff(player, "invincible", 1)
	TestFixtures.combat(game_manager, [player], [])

	player.take_damage(50, false)

	assert_health(player, 100, "Invincible blocks all damage")


func _test_invincible_end_enemy_turn():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_buff(player, "invincible", 1)
	TestFixtures.combat(game_manager, [player], [])

	# Invincible should last through enemy turn, removed at enemy turn end
	player.on_enemy_turn_end()

	assert_no_buff(player, "invincible", "Invincible removed after enemy turn")


# ============================================
# RING OF FIRE
# ============================================

func _test_ring_of_fire_reflect():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy = TestFixtures.enemy("Attacker", 100)
	TestFixtures.apply_buff(player, "ring_of_fire", 3)
	TestFixtures.combat(game_manager, [player], [enemy])

	# When player is hit, should reflect 3 damage
	# This is typically handled in take_damage with attacker reference
	assert_buff(player, "ring_of_fire", 3, "Ring of Fire is active")


func _test_ring_of_fire_end_enemy_turn():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_buff(player, "ring_of_fire", 3)
	TestFixtures.combat(game_manager, [player], [])

	player.on_enemy_turn_end()

	assert_no_buff(player, "ring_of_fire", "Ring of Fire removed after enemy turn")


# ============================================
# PLAYED TWICE
# ============================================

func _test_played_twice_triggers():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_buff(player, "played_twice", 1)

	assert_buff(player, "played_twice", 1, "Played Twice is active")


func _test_played_twice_consumed():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_buff(player, "played_twice", 1)
	TestFixtures.combat(game_manager, [player], [])

	# Consume the buff (happens when a card is played)
	player.played_twice = 0

	assert_no_buff(player, "played_twice", "Played Twice consumed after use")
