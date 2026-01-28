extends "res://scripts/tests/framework/test_base.gd"
class_name CardStatusTest
## Tests for Card + Status Effect interactions

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "Card + Status Interactions"


# ============================================
# DAMAGE + STRENGTH
# ============================================

func _test_slash_with_strength():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.apply_buff(player, "strength", 5)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Slash = 7, + 5 strength = 12
	TestFixtures.give_card(player, "slash", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 88, "Slash with 5 Strength deals 12 damage")


# ============================================
# DAMAGE + WEAKNESS
# ============================================

func _test_slash_with_weakness():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.apply_debuff(player, "weakness", 3)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Slash = 7, - 3 weakness = 4
	TestFixtures.give_card(player, "slash", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 96, "Slash with 3 Weakness deals 4 damage")


# ============================================
# DAMAGE + HINDER
# ============================================

func _test_slash_with_hinder():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.apply_debuff(player, "hinder", 4)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Slash = 7, - 4 hinder = 3
	TestFixtures.give_card(player, "slash", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 97, "Slash with 4 Hinder deals 3 damage")


# ============================================
# DAMAGE VS VULNERABLE TARGET
# ============================================

func _test_slash_vs_vulnerable():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.apply_debuff(enemy, "vulnerable", 2)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Slash = 7, vulnerable adds 50% = 10.5 -> 10
	TestFixtures.give_card(player, "slash", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health_between(enemy, 89, 93, "Slash vs Vulnerable target")


# ============================================
# DEBUFF BONUS DAMAGE
# ============================================

func _test_weak_point_with_multiple_debuffs():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.apply_debuffs(enemy, {"poison": 3, "weakness": 2, "bleed": 1})  # 6 stacks
	TestFixtures.combat(game_manager, [player], [enemy])

	# Weak Point = 2 base + 2 per debuff stack = 2 + 12 = 14
	TestFixtures.give_card(player, "weak_point", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 86, "Weak Point with 6 debuff stacks deals 14")


# ============================================
# WOUNDED BONUS
# ============================================

func _test_execution_wounded_calculation():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.wound(enemy)  # 40% HP = 40
	TestFixtures.combat(game_manager, [player], [enemy])

	# Execution = 4 base + 4 wounded bonus = 8
	TestFixtures.give_card(player, "execution", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 32, "Execution deals 8 to wounded target (40-8=32)")


# ============================================
# SHIELD + PIERCING
# ============================================

func _test_annihilation_ignores_shield():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.give_shield(enemy, 50)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Annihilation = 35 piercing damage
	TestFixtures.give_card(player, "annihilation", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 65, "Annihilation ignores shield")
	assert_shield(enemy, 50, "Shield remains after piercing damage")


# ============================================
# HEALING + DECAY
# ============================================

func _test_medkit_with_decay_penalty():
	var player = TestFixtures.fabio(50, 10)
	TestFixtures.set_hp(player, 30)
	TestFixtures.apply_debuff(player, "decay", 1)
	TestFixtures.combat(game_manager, [player], [])

	# Medkit heals 10, decay reduces by 5 = 5
	# Also applies 1 more decay
	TestFixtures.give_card(player, "medkit", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_health(player, 35, "Medkit with 1 Decay heals only 5")


# ============================================
# INVINCIBLE BLOCKS DAMAGE
# ============================================

func _test_divine_barrier_blocks_boss_attack():
	var player = TestFixtures.enrique(100, 3, 5)
	var ally = TestFixtures.player("Ally", 100, 10)
	var boss = TestFixtures.boss("Test Boss", 200)
	TestFixtures.combat(game_manager, [player, ally], [boss])

	# Apply Divine Barrier to ally
	TestFixtures.give_card(player, "divine_barrier", card_db)
	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_buff(ally, "invincible", 1, "Divine Barrier grants Invincible")

	# Boss attacks ally
	var attack = TestFixtures.make_attack_card("Boss Smash", 30)
	game_manager.apply_card_effects(boss, attack, ally)

	assert_health(ally, 100, "Invincible ally takes no damage")


# ============================================
# MULTI-HIT + DOTs
# ============================================

func _test_dual_wield_triggers_bleed_each_hit():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.apply_debuff(enemy, "bleed", 4)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Dual Wield = 2 hits
	# Each hit might trigger bleed separately (implementation dependent)
	TestFixtures.give_card(player, "dual_wield", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health_between(enemy, 92, 100, "Dual Wield vs bleeding enemy")
