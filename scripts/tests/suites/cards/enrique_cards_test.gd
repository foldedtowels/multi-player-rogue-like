extends "res://scripts/tests/framework/test_base.gd"
class_name EnriqueCardsTest
## Comprehensive tests for all Enrique (Cleric) cards

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "Enrique Cards"


# ============================================
# BASE DECK TESTS
# ============================================

func _test_expulsion_aura_damage():
	var player = TestFixtures.enrique(100, 3, 5)
	var enemy1 = TestFixtures.enemy("Enemy1", 100)
	var enemy2 = TestFixtures.enemy("Enemy2", 100)
	TestFixtures.combat(game_manager, [player], [enemy1, enemy2])

	TestFixtures.give_card(player, "expulsion", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	# Spends all 5 aura, 3 damage per aura = 15 to each enemy
	assert_health(enemy1, 85, "Expulsion deals 15 to enemy1 (5 aura x 3)")
	assert_health(enemy2, 85, "Expulsion deals 15 to enemy2 (AOE)")
	assert_aura(player, 0, "Expulsion consumes all aura")


func _test_focused_purge_aura_gain():
	var player = TestFixtures.enrique(100, 3, 2)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	TestFixtures.give_card(player, "focused_purge", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 97, "Focused Purge deals 3 damage")
	assert_aura(player, 3, "Focused Purge gains 1 aura (2+1=3)")


func _test_holy_plight_aura_cost():
	var player = TestFixtures.enrique(100, 3, 5)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	var card = card_db.get_card("holy_plight")
	TestFixtures.give_card(player, "holy_plight", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 95, "Holy Plight deals 5 damage")
	assert_eq(card.aura_cost, 2, "Holy Plight costs 2 aura")


func _test_prayer_beads_d6():
	var card = card_db.get_card("prayer_beads")

	assert_eq(card.aura_cost, 1, "Prayer Beads costs 1 aura")
	assert_true(card.random_damage_min == 1, "Prayer Beads min damage is 1")
	assert_true(card.random_damage_max == 6, "Prayer Beads max damage is 6")


func _test_humble_request_aura():
	var player = TestFixtures.enrique(100, 3, 2)
	TestFixtures.combat(game_manager, [player], [])

	TestFixtures.give_card(player, "humble_request", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_aura(player, 4, "Humble Request gains 2 aura (2+2=4)")


func _test_divine_reflection_double():
	var player = TestFixtures.enrique(100, 3, 5)
	TestFixtures.combat(game_manager, [player], [])

	var card = card_db.get_card("divine_reflection")
	TestFixtures.give_card(player, "divine_reflection", card_db)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_buff(player, "played_twice", 1, "Divine Reflection grants Played Twice")
	assert_eq(card.aura_cost, 3, "Divine Reflection costs 3 aura")


func _test_healing_aura_decay():
	var player = TestFixtures.enrique(100, 3, 5)
	TestFixtures.set_hp(player, 80)
	var ally = TestFixtures.player("Ally", 100, 10)
	TestFixtures.set_hp(ally, 70)
	TestFixtures.combat(game_manager, [player, ally], [])

	TestFixtures.give_card(player, "healing_aura", card_db)
	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_health(ally, 80, "Healing Aura heals ally 10 HP")
	assert_debuff(player, "decay", 1, "Healing Aura applies Decay 1 to caster")


func _test_magical_purge_debuff():
	var player = TestFixtures.enrique(100, 3, 5)
	TestFixtures.apply_debuff(player, "poison", 3)
	TestFixtures.combat(game_manager, [player], [])

	TestFixtures.give_card(player, "magical_purge", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_no_debuff(player, "poison", "Magical Purge removes debuff")


func _test_story_of_jacob():
	var player = TestFixtures.enrique(100, 3, 2)
	TestFixtures.combat(game_manager, [player], [])

	TestFixtures.give_card(player, "story_of_jacob", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_aura(player, 7, "Story of Jacob gains 5 aura (2+5=7)")
	assert_debuff(player, "fatigued", 1, "Story of Jacob applies 1 Fatigued")


func _test_protection_ally_shield():
	var player = TestFixtures.enrique(100, 3, 5)
	var ally = TestFixtures.player("Ally", 100, 10)
	TestFixtures.combat(game_manager, [player, ally], [])

	var card = card_db.get_card("protection")
	TestFixtures.give_card(player, "protection", card_db)

	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_shield(ally, 5, "Protection grants 5 shield to ally")
	assert_eq(card.aura_cost, 1, "Protection costs 1 aura")


# ============================================
# REWARD CARD TESTS
# ============================================

func _test_divine_force_v1_heal():
	var player = TestFixtures.enrique(100, 3, 5)
	var ally = TestFixtures.player("Ally", 100, 10)
	TestFixtures.set_hp(ally, 80)
	TestFixtures.combat(game_manager, [player, ally], [])

	var card = card_db.get_card("divine_force")
	TestFixtures.give_card(player, "divine_force", card_db)

	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_health(ally, 90, "Divine Force V1 heals ally 10")
	assert_debuff(player, "decay", 1, "Divine Force V1 applies Decay to caster")
	assert_true(card.has_v2, "Divine Force has V2 option")


func _test_divine_force_v2_damage():
	var player = TestFixtures.enrique(100, 3, 5)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	TestFixtures.give_card(player, "divine_force_v2", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 94, "Divine Force V2 deals 6 damage")


func _test_purging_water_cleanse():
	var player = TestFixtures.enrique(100, 3, 5)
	var ally = TestFixtures.player("Ally", 100, 10)
	TestFixtures.apply_debuff(ally, "poison", 2)
	TestFixtures.combat(game_manager, [player, ally], [])

	TestFixtures.give_card(player, "purging_water", card_db)
	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_no_debuff(ally, "poison", "Purging Water removes debuff from ally")


func _test_divine_barrier_invincible():
	var player = TestFixtures.enrique(100, 3, 5)
	var ally = TestFixtures.player("Ally", 100, 10)
	TestFixtures.combat(game_manager, [player, ally], [])

	TestFixtures.give_card(player, "divine_barrier", card_db)
	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_buff(ally, "invincible", 1, "Divine Barrier grants Invincible")


func _test_refuge_shield_aura():
	var player = TestFixtures.enrique(100, 3, 3)
	TestFixtures.combat(game_manager, [player], [])

	TestFixtures.give_card(player, "refuge", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_shield(player, 5, "Refuge grants 5 shield")
	assert_aura(player, 4, "Refuge gains 1 aura (3+1=4)")


func _test_gift_ally_draw():
	var card = card_db.get_card("gift")

	assert_eq(card.target_draw_cards, 2, "Gift makes ally draw 2 cards")


func _test_divine_gift_stamina():
	var card = card_db.get_card("divine_gift")

	assert_eq(card.target_gains_stamina, 2, "Divine Gift grants ally 2 stamina")


func _test_guy_with_beard_all_draw():
	var card = card_db.get_card("guy_with_beard")

	assert_eq(card.all_players_draw, 1, "Guy with Beard makes ALL players draw 1")
