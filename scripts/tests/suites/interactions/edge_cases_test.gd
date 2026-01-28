extends "res://scripts/tests/framework/test_base.gd"
class_name EdgeCasesTest
## Tests for edge cases and boundary conditions

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "Edge Cases"


# ============================================
# OVERKILL DAMAGE
# ============================================

func _test_overkill_damage():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy = TestFixtures.enemy("Target", 10)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Deal 30 damage to enemy with 10 HP
	TestFixtures.give_card(player, "apocalypse", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_dead(enemy, "Enemy dies from overkill damage")
	assert_lte(enemy.current_health, 0, "Health can go below zero")


# ============================================
# HEAL AT MAX HP
# ============================================

func _test_heal_at_max_hp():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.combat(game_manager, [player], [])

	# Already at max HP
	player.heal(50)

	assert_health(player, 100, "Healing at max HP doesn't exceed max")


func _test_heal_exceeds_max():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.set_hp(player, 90)
	TestFixtures.combat(game_manager, [player], [])

	# Heal 50 when only 10 below max
	player.heal(50)

	assert_health(player, 100, "Healing is capped at max HP")


# ============================================
# ZERO STAMINA PLAY
# ============================================

func _test_zero_stamina_play():
	var player = TestFixtures.player("Test", 100, 0)
	TestFixtures.combat(game_manager, [player], [])

	var card = card_db.get_card("slash")  # Costs 2

	# Can't play card with 0 stamina (validation happens in combat system)
	assert_eq(player.current_stamina, 0, "Player has 0 stamina")
	assert_eq(card.stamina_cost, 2, "Card costs 2 stamina")


func _test_zero_cost_card_at_zero_stamina():
	var player = TestFixtures.player("Test", 100, 0)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Cursed Dagger costs 0
	TestFixtures.give_card(player, "cursed_dagger", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 98, "0-cost card can be played at 0 stamina")


# ============================================
# EMPTY HAND/DECK
# ============================================

func _test_empty_hand_draw():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.combat(game_manager, [player], [])

	# Empty deck, try to draw
	player.deck.clear()
	player.hand.clear()

	player.draw_cards(3)

	assert_hand_size(player, 0, "Can't draw from empty deck")


func _test_draw_reshuffles_discard():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.combat(game_manager, [player], [])

	# Put cards in discard
	for i in range(5):
		var card = TestFixtures.make_attack_card("Card%d" % i, 5)
		player.discard_pile.append(card)

	player.deck.clear()
	player.hand.clear()

	# Drawing should reshuffle discard into deck
	player.draw_cards(3)

	assert_hand_size(player, 3, "Drawing reshuffles discard pile")


# ============================================
# DEAD TARGET
# ============================================

func _test_dead_target():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy = TestFixtures.enemy("Target", 0)  # Already dead
	TestFixtures.combat(game_manager, [player], [enemy])

	assert_dead(enemy, "Enemy starts dead")


# ============================================
# SELF DAMAGE DEATH
# ============================================

func _test_self_damage_death():
	var player = TestFixtures.player("Test", 5, 10)  # Low HP
	TestFixtures.combat(game_manager, [player], [])

	# Dark Pact costs 5 HP
	TestFixtures.give_card(player, "dark_pact", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_dead(player, "Self-damage can kill player")


# ============================================
# NEGATIVE DAMAGE
# ============================================

func _test_negative_damage():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.apply_debuff(player, "weakness", 10)
	TestFixtures.apply_debuff(player, "hinder", 10)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Slash = 7, -10 weakness -10 hinder = -13 -> should be 0
	TestFixtures.give_card(player, "slash", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 100, "Damage can't go negative (minimum 0)")


# ============================================
# MAX DEBUFF STACKS
# ============================================

func _test_max_debuff_stacks():
	var player = TestFixtures.player("Test", 100, 10)

	# Apply huge amount of poison
	player.poison = 999

	assert_debuff(player, "poison", 999, "Debuffs can stack to high values")


# ============================================
# STRENGTH + WEAKNESS INTERACTION
# ============================================

func _test_strength_and_weakness_cancel():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.apply_buff(player, "strength", 5)
	TestFixtures.apply_debuff(player, "weakness", 5)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Slash = 7, +5 str -5 weakness = 7
	TestFixtures.give_card(player, "slash", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 93, "Strength and Weakness cancel out")


# ============================================
# ARMOR + VULNERABLE INTERACTION
# ============================================

func _test_armor_vs_vulnerable():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.apply_buff(player, "armor", 3)
	TestFixtures.apply_debuff(player, "vulnerable", 2)
	TestFixtures.combat(game_manager, [player], [])

	# Take 10 damage
	# Vulnerable: 10 * 1.5 = 15
	# Armor: 15 - 3 = 12
	player.take_damage(10, false)

	assert_health_between(player, 85, 91, "Armor and Vulnerable both apply")


# ============================================
# SHIELD ABSORPTION
# ============================================

func _test_shield_absorbs_partial():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_shield(player, 5)
	TestFixtures.combat(game_manager, [player], [])

	# Take 10 damage with 5 shield
	player.take_damage(10, false)

	assert_health(player, 95, "Shield absorbs damage, remainder hits HP")
	assert_shield(player, 0, "Shield is depleted")


func _test_shield_absorbs_all():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_shield(player, 20)
	TestFixtures.combat(game_manager, [player], [])

	# Take 10 damage with 20 shield
	player.take_damage(10, false)

	assert_health(player, 100, "Shield absorbs all damage")
	assert_shield(player, 10, "Remaining shield preserved")


# ============================================
# DELAYED EFFECTS + DEATH
# ============================================

func _test_delayed_effect_on_dead_target():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 5)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Queue jumping strike
	TestFixtures.give_card(player, "jumping_strike", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# Kill enemy before delayed effect resolves
	TestFixtures.kill(enemy)

	# Process delayed effects
	TestFixtures.end_turn(game_manager)
	game_manager._process_delayed_effects()

	assert_dead(enemy, "Dead target stays dead")
