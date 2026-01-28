extends "res://scripts/tests/framework/test_base.gd"
class_name RewardCardsTest
## Tests for all generic reward cards (rare and common)

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "Reward Cards"


# ============================================
# RARE CARDS
# ============================================

func _test_apocalypse_massive_aoe():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy1 = TestFixtures.enemy("Enemy1", 100)
	var enemy2 = TestFixtures.enemy("Enemy2", 100)
	TestFixtures.combat(game_manager, [player], [enemy1, enemy2])

	TestFixtures.give_card(player, "apocalypse", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_health(enemy1, 70, "Apocalypse deals 30 to enemy1")
	assert_health(enemy2, 70, "Apocalypse deals 30 to enemy2 (AOE)")


func _test_divine_intervention():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.set_hp(player, 40)
	TestFixtures.combat(game_manager, [player], [])

	TestFixtures.give_card(player, "divine_intervention", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_health(player, 90, "Divine Intervention heals 50 HP")
	assert_shield(player, 30, "Divine Intervention grants 30 shield")


func _test_berserker_rage_strength():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.combat(game_manager, [player], [])

	TestFixtures.give_card(player, "berserker_rage", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_buff(player, "strength", 5, "Berserker Rage grants 5 Strength")


func _test_meteor_swarm_multi_aoe():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy1 = TestFixtures.enemy("Enemy1", 100)
	var enemy2 = TestFixtures.enemy("Enemy2", 100)
	TestFixtures.combat(game_manager, [player], [enemy1, enemy2])

	var card = card_db.get_card("meteor_swarm")
	TestFixtures.give_card(player, "meteor_swarm", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	# 12 damage x 3 hits to ALL = 36 each
	assert_health(enemy1, 64, "Meteor Swarm deals 12x3=36 to enemy1")
	assert_health(enemy2, 64, "Meteor Swarm deals 12x3=36 to enemy2")
	assert_eq(card.multi_hit, 3, "Meteor Swarm has multi_hit: 3")


func _test_time_stop_draw():
	var card = card_db.get_card("time_stop")

	assert_eq(card.draw_cards, 5, "Time Stop draws 5 cards")


func _test_life_drain_lifesteal():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.set_hp(player, 70)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	var card = card_db.get_card("life_drain")
	TestFixtures.give_card(player, "life_drain", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 75, "Life Drain deals 25 damage")
	assert_true(card.lifesteal, "Life Drain has lifesteal")
	# Lifesteal should heal player
	assert_gte(player.current_health, 70, "Life Drain heals with lifesteal")


func _test_annihilation_piercing():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.give_shield(enemy, 50)
	TestFixtures.combat(game_manager, [player], [enemy])

	var card = card_db.get_card("annihilation")
	TestFixtures.give_card(player, "annihilation", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# Piercing damage ignores shield
	assert_health(enemy, 65, "Annihilation deals 35 piercing damage")
	assert_true(card.piercing, "Annihilation has piercing")


func _test_omnipotence_buffs():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.combat(game_manager, [player], [])

	var card = card_db.get_card("omnipotence")
	TestFixtures.give_card(player, "omnipotence", card_db)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_shield(player, 15, "Omnipotence grants 15 shield")
	assert_buff(player, "strength", 3, "Omnipotence grants 3 Strength")
	assert_buff(player, "armor", 3, "Omnipotence grants 3 Armor")
	assert_eq(card.draw_cards, 3, "Omnipotence draws 3 cards")


# ============================================
# COMMON CARDS
# ============================================

func _test_steel_strike():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	TestFixtures.give_card(player, "steel_strike", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 84, "Steel Strike deals 16 damage")


func _test_healing_potion():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.set_hp(player, 80)
	TestFixtures.combat(game_manager, [player], [])

	TestFixtures.give_card(player, "healing_potion", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_health(player, 95, "Healing Potion heals 15")


func _test_fortify():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.combat(game_manager, [player], [])

	TestFixtures.give_card(player, "fortify", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_shield(player, 12, "Fortify grants 12 shield")


func _test_power_strike():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	TestFixtures.give_card(player, "power_strike", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 82, "Power Strike deals 18 damage")


func _test_battle_focus():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.combat(game_manager, [player], [])

	var card = card_db.get_card("battle_focus")
	TestFixtures.give_card(player, "battle_focus", card_db)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_buff(player, "strength", 2, "Battle Focus grants 2 Strength")
	assert_eq(card.draw_cards, 1, "Battle Focus draws 1 card")


func _test_cleave_aoe():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy1 = TestFixtures.enemy("Enemy1", 100)
	var enemy2 = TestFixtures.enemy("Enemy2", 100)
	TestFixtures.combat(game_manager, [player], [enemy1, enemy2])

	TestFixtures.give_card(player, "cleave", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_health(enemy1, 90, "Cleave deals 10 to enemy1")
	assert_health(enemy2, 90, "Cleave deals 10 to enemy2 (AOE)")


func _test_rejuvenation():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.set_hp(player, 80)
	TestFixtures.combat(game_manager, [player], [])

	TestFixtures.give_card(player, "rejuvenation", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_health(player, 92, "Rejuvenation heals 12")
	assert_shield(player, 8, "Rejuvenation grants 8 shield")


func _test_iron_will():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.combat(game_manager, [player], [])

	TestFixtures.give_card(player, "iron_will", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_shield(player, 10, "Iron Will grants 10 shield")
	assert_buff(player, "armor", 2, "Iron Will grants 2 Armor")


func _test_quick_strike():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	TestFixtures.give_card(player, "quick_strike", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 88, "Quick Strike deals 12 damage")


func _test_tactical_advantage():
	var card = card_db.get_card("tactical_advantage")

	assert_eq(card.draw_cards, 2, "Tactical Advantage draws 2 cards")


# ============================================
# DEMO/SPECIAL CARDS
# ============================================

func _test_vampiric_strike():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.set_hp(player, 80)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	var card = card_db.get_card("vampiric_strike")
	TestFixtures.give_card(player, "vampiric_strike", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 88, "Vampiric Strike deals 12 damage")
	assert_true(card.lifesteal, "Vampiric Strike has lifesteal")


func _test_toxic_cloud():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy1 = TestFixtures.enemy("Enemy1", 100)
	var enemy2 = TestFixtures.enemy("Enemy2", 100)
	TestFixtures.combat(game_manager, [player], [enemy1, enemy2])

	TestFixtures.give_card(player, "toxic_cloud", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_health(enemy1, 92, "Toxic Cloud deals 8 to enemy1")
	assert_health(enemy2, 92, "Toxic Cloud deals 8 to enemy2 (AOE)")
	assert_debuff(enemy1, "poison", 4, "Toxic Cloud applies 4 Poison")
	assert_debuff(enemy2, "poison", 4, "Toxic Cloud applies 4 Poison to all")


func _test_dark_pact():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.combat(game_manager, [player], [])

	var card = card_db.get_card("dark_pact")
	TestFixtures.give_card(player, "dark_pact", card_db)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_health(player, 95, "Dark Pact costs 5 HP")
	assert_buff(player, "strength", 4, "Dark Pact grants 4 Strength")
	assert_eq(card.draw_cards, 2, "Dark Pact draws 2 cards")


func _test_blazing_fury():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	TestFixtures.give_card(player, "blazing_fury", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 85, "Blazing Fury deals 15 damage")
	assert_debuff(enemy, "burn", 3, "Blazing Fury applies 3 Burn")
	assert_debuff(enemy, "vulnerable", 2, "Blazing Fury applies 2 Vulnerable")


func _test_pyroclasm():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy1 = TestFixtures.enemy("Enemy1", 100)
	var enemy2 = TestFixtures.enemy("Enemy2", 100)
	TestFixtures.combat(game_manager, [player], [enemy1, enemy2])

	var card = card_db.get_card("pyroclasm")
	TestFixtures.give_card(player, "pyroclasm", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_health(enemy1, 82, "Pyroclasm deals 18 to enemy1")
	assert_health(enemy2, 82, "Pyroclasm deals 18 to enemy2 (AOE)")
	assert_eq(card.add_ember_to_hand, 2, "Pyroclasm adds 2 Ember tokens")
