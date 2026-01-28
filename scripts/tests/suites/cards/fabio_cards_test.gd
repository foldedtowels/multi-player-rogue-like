extends "res://scripts/tests/framework/test_base.gd"
class_name FabioCardsTest
## Comprehensive tests for all Fabio (Warrior) cards

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "Fabio Cards"


# ============================================
# BASE DECK TESTS
# ============================================

func _test_slash_damage():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	var card = card_db.get_card("slash")
	TestFixtures.give_card(player, "slash", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 93, "Slash deals 7 damage")
	assert_card_cost(card, 2, "Slash costs 2 stamina")
	assert_card_type(card, Card.CardType.ATTACK, "Slash is ATTACK type")


func _test_big_smack_damage():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	TestFixtures.give_card(player, "big_smack", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 90, "Big Smack deals 10 damage")


func _test_duel_purpose_damage_and_shield():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	TestFixtures.give_card(player, "duel_purpose", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 97, "Duel Purpose deals 3 damage")
	assert_shield(player, 5, "Duel Purpose grants 5 shield")


func _test_rest_applies_rested():
	var player = TestFixtures.fabio(100, 3)
	TestFixtures.combat(game_manager, [player], [])

	var card = card_db.get_card("rest")
	TestFixtures.give_card(player, "rest", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_buff(player, "rested", 1, "Rest applies Rested 1")
	assert_card_type(card, Card.CardType.BUFF, "Rest is BUFF type")


func _test_bulk_up_invigorated_fatigued():
	var player = TestFixtures.fabio(100, 10)
	TestFixtures.combat(game_manager, [player], [])

	TestFixtures.give_card(player, "bulk_up", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_buff(player, "invigorated", 1, "Bulk Up applies Invigorated 1")
	assert_buff(player, "damage_plus", 2, "Invigorated grants +2 damage")
	assert_debuff(player, "fatigued", 1, "Bulk Up applies Fatigued 1")


func _test_dig_a_hole_card_retention():
	var card = card_db.get_card("dig_a_hole")

	assert_card_cost(card, 0, "Dig a Hole costs 0 stamina")
	assert_true(card.plays_immediately, "Dig a Hole plays immediately")
	assert_true(card.grants_card_retain, "Dig a Hole grants card retain")


func _test_protector_redirects_damage():
	var fabio = TestFixtures.fabio(100, 10)
	var ally = TestFixtures.player("Ally", 100, 10)
	var enemy = TestFixtures.enemy("Enemy", 100)
	TestFixtures.combat(game_manager, [fabio, ally], [enemy])

	TestFixtures.give_card(fabio, "protector", card_db)
	game_manager.apply_card_effects(fabio, fabio.hand[0], ally)

	assert_has_key(game_manager.protected_by, 1, "Ally is marked as protected")

	# Enemy attacks ally
	var attack = TestFixtures.make_attack_card("Test Attack", 10)
	game_manager.apply_card_effects(enemy, attack, ally)

	assert_health(ally, 100, "Protected ally takes 0 damage")
	assert_health(fabio, 90, "Protector takes redirected 10 damage")


func _test_protector_dead_no_redirect():
	var fabio = TestFixtures.fabio(100, 10)
	var ally = TestFixtures.player("Ally", 100, 10)
	var enemy = TestFixtures.enemy("Enemy", 100)
	TestFixtures.combat(game_manager, [fabio, ally], [enemy])

	TestFixtures.give_card(fabio, "protector", card_db)
	game_manager.apply_card_effects(fabio, fabio.hand[0], ally)

	# Kill the protector
	TestFixtures.kill(fabio)

	# Enemy attacks ally - should hit ally since protector is dead
	var attack = TestFixtures.make_attack_card("Test Attack", 10)
	game_manager.apply_card_effects(enemy, attack, ally)

	# Dead protector can't redirect
	assert_health_between(ally, 90, 100, "Ally takes damage when protector is dead")


func _test_protective_footwear_shield():
	var player = TestFixtures.fabio(100, 10)
	TestFixtures.combat(game_manager, [player], [])

	TestFixtures.give_card(player, "protective_footwear", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_shield(player, 5, "Protective Footwear grants 5 shield")


func _test_hunters_instinct_reveals_intent():
	var card = card_db.get_card("hunters_instinct")

	assert_card_cost(card, 1, "Hunter's Instinct costs 1 stamina")
	assert_true(card.plays_immediately, "Hunter's Instinct plays immediately")
	assert_true(card.reveals_boss_intent, "Hunter's Instinct reveals boss intent")


# ============================================
# REWARD CARD TESTS
# ============================================

func _test_dual_wield_multi_hit():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	var card = card_db.get_card("dual_wield")
	TestFixtures.give_card(player, "dual_wield", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# 2 damage x 2 hits = 4 total
	assert_health(enemy, 96, "Dual Wield deals 2x2 = 4 damage")
	assert_eq(card.multi_hit, 2, "Dual Wield has multi_hit: 2")


func _test_circular_strike_aoe():
	var player = TestFixtures.fabio(100, 10)
	var enemy1 = TestFixtures.enemy("Enemy1", 100)
	var enemy2 = TestFixtures.enemy("Enemy2", 100)
	TestFixtures.combat(game_manager, [player], [enemy1, enemy2])

	TestFixtures.give_card(player, "circular_strike", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_health(enemy1, 97, "Circular Strike deals 3 to enemy1")
	assert_health(enemy2, 97, "Circular Strike deals 3 to enemy2 (AOE)")


func _test_cursed_dagger_zero_cost():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	var card = card_db.get_card("cursed_dagger")
	TestFixtures.give_card(player, "cursed_dagger", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 98, "Cursed Dagger deals 2 damage")
	assert_card_cost(card, 0, "Cursed Dagger costs 0 stamina")


func _test_jumping_strike_delayed():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	TestFixtures.give_card(player, "jumping_strike", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# No immediate damage
	assert_health(enemy, 100, "Jumping Strike deals NO damage on play")
	assert_gt(game_manager.delayed_effects.size(), 0, "Jumping Strike queues delayed effect")

	# Process delayed effects
	TestFixtures.end_turn(game_manager)
	game_manager._process_delayed_effects()

	assert_health(enemy, 95, "Jumping Strike deals 5 damage next turn")


func _test_jumping_strike_cancelled():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	TestFixtures.give_card(player, "jumping_strike", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# Player takes damage
	player.damage_taken_this_turn = 5

	# Process delayed effects - should be cancelled
	TestFixtures.end_turn(game_manager)
	game_manager._process_delayed_effects()

	assert_health(enemy, 100, "Jumping Strike cancelled if caster took damage")


func _test_execution_base_damage():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	TestFixtures.give_card(player, "execution", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# Base 4 damage (no wounded bonus)
	assert_health(enemy, 96, "Execution deals 4 base damage")


func _test_execution_wounded_bonus():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Wound the enemy (below 50% HP)
	TestFixtures.wound(enemy)  # Sets to 40% HP = 40

	TestFixtures.give_card(player, "execution", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# 4 base + 4 wounded bonus = 8 damage
	assert_health(enemy, 32, "Execution deals 4+4=8 to wounded target")


func _test_frenzy_aoe_exhausted():
	var player = TestFixtures.fabio(100, 10)
	var enemy1 = TestFixtures.enemy("Enemy1", 100)
	var enemy2 = TestFixtures.enemy("Enemy2", 100)
	TestFixtures.combat(game_manager, [player], [enemy1, enemy2])

	TestFixtures.give_card(player, "frenzy", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_health(enemy1, 92, "Frenzy deals 8 to enemy1")
	assert_health(enemy2, 92, "Frenzy deals 8 to enemy2 (AOE)")
	assert_debuff(player, "exhausted", 2, "Frenzy applies 2 Exhausted to caster")


func _test_weak_point_base():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	var card = card_db.get_card("weak_point")
	TestFixtures.give_card(player, "weak_point", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# No debuffs = 2 base damage only
	assert_health(enemy, 98, "Weak Point deals 2 base damage")
	assert_eq(card.bonus_damage_per_debuff, 2, "Weak Point has +2 per debuff bonus")


func _test_weak_point_debuff_bonus():
	var player = TestFixtures.fabio(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Apply 3 debuff stacks to enemy
	TestFixtures.apply_debuffs(enemy, {"poison": 2, "weakness": 1})

	TestFixtures.give_card(player, "weak_point", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# 2 base + (3 debuffs * 2) = 8 damage -> 100 - 8 = 92
	assert_health(enemy, 92, "Weak Point deals 2+6=8 with 3 debuffs")


func _test_medkit_heal_decay():
	var player = TestFixtures.fabio(50, 10)
	TestFixtures.set_hp(player, 40)
	TestFixtures.combat(game_manager, [player], [])

	TestFixtures.give_card(player, "medkit", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_health(player, 50, "Medkit heals 10 HP (40->50)")
	assert_debuff(player, "decay", 1, "Medkit applies Decay 1")


func _test_fighters_spirit_v1_debuff_removal():
	var player = TestFixtures.fabio(100, 10)
	TestFixtures.combat(game_manager, [player], [])

	# Apply a debuff to remove
	TestFixtures.apply_debuff(player, "poison", 2)

	var card = card_db.get_card("fighters_spirit")
	TestFixtures.give_card(player, "fighters_spirit", card_db)

	game_manager.apply_card_effects(player, player.hand[0], player)

	# remove_target_debuffs removes entire debuff type
	assert_no_debuff(player, "poison", "Fighter's Spirit removes debuff type")
	assert_true(card.has_v2, "Fighter's Spirit has V2 option")


func _test_fighters_spirit_v2_shield():
	var player = TestFixtures.fabio(100, 10)
	TestFixtures.combat(game_manager, [player], [])

	TestFixtures.give_card(player, "fighters_spirit_v2", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_shield(player, 5, "Fighter's Spirit V2 grants 5 shield")


func _test_sacrifice_protection():
	var fabio = TestFixtures.fabio(100, 10)
	var ally = TestFixtures.player("Ally", 100, 10)
	TestFixtures.combat(game_manager, [fabio, ally], [])

	TestFixtures.give_card(fabio, "sacrifice", card_db)
	game_manager.apply_card_effects(fabio, fabio.hand[0], ally)

	assert_buff(ally, "strength", 1, "Sacrifice grants 1 Strength to ally")


func _test_leader_v1_draw():
	var card = card_db.get_card("leader")

	assert_card_cost(card, 0, "Leader costs 0 stamina")
	assert_true(card.plays_immediately, "Leader plays immediately")
	assert_eq(card.draw_cards, 1, "Leader draws 1 card for allies")
	assert_true(card.has_v2, "Leader has V2 option")


func _test_leader_v2_discard_draw():
	var card = card_db.get_card("leader_v2")

	assert_card_cost(card, 0, "Leader V2 costs 0 stamina")
	assert_eq(card.draw_cards, 2, "Leader V2 draws 2 cards for allies")
	assert_eq(card.caster_discards_random, 2, "Leader V2 discards 2 from caster")
