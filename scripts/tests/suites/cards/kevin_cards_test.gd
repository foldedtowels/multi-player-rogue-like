extends "res://scripts/tests/framework/test_base.gd"
class_name KevinCardsTest
## Comprehensive tests for all Kevin (Alchemist) cards

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "Kevin Cards"


# ============================================
# BASE DECK TESTS
# ============================================

func _test_poke_damage():
	var player = TestFixtures.kevin(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	var card = card_db.get_card("poke")
	TestFixtures.give_card(player, "poke", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 98, "Poke deals 2 damage")
	assert_card_cost(card, 1, "Poke costs 1 stamina")


func _test_meditate_draw():
	var card = card_db.get_card("meditate")

	assert_eq(card.draw_cards, 2, "Meditate draws 2 cards")
	assert_card_cost(card, 1, "Meditate costs 1 stamina")


func _test_fetal_position_shield():
	var player = TestFixtures.kevin(100, 10)
	TestFixtures.combat(game_manager, [player], [])

	TestFixtures.give_card(player, "fetal_position", card_db)
	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_shield(player, 5, "Fetal Position grants 5 shield")


func _test_fire_smash_damage():
	var player = TestFixtures.kevin(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	var card = card_db.get_card("spell_fire_smash")
	TestFixtures.give_card(player, "spell_fire_smash", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 95, "Fire Smash deals 5 damage")
	assert_eq(card.element, Card.ElementType.FIRE, "Fire Smash is FIRE element")


func _test_water_ball_wet():
	var player = TestFixtures.kevin(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	var card = card_db.get_card("spell_water_ball")
	TestFixtures.give_card(player, "spell_water_ball", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 99, "Water Ball deals 1 damage")
	assert_debuff(enemy, "wet", 1, "Water Ball applies 1 Wet")
	assert_eq(card.element, Card.ElementType.WATER, "Water Ball is WATER element")


func _test_earthquake_aoe():
	var player = TestFixtures.kevin(100, 10)
	var enemy1 = TestFixtures.enemy("Enemy1", 100)
	var enemy2 = TestFixtures.enemy("Enemy2", 100)
	TestFixtures.combat(game_manager, [player], [enemy1, enemy2])

	var card = card_db.get_card("spell_earthquake")
	TestFixtures.give_card(player, "spell_earthquake", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_health(enemy1, 98, "Earthquake deals 2 to enemy1")
	assert_health(enemy2, 98, "Earthquake deals 2 to enemy2 (AOE)")
	assert_eq(card.element, Card.ElementType.EARTH, "Earthquake is EARTH element")


func _test_fiery_flash_hinder():
	var player = TestFixtures.kevin(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	TestFixtures.give_card(player, "spell_fiery_flash", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 96, "Fiery Flash deals 4 damage")
	assert_debuff(enemy, "hinder", 4, "Fiery Flash applies 4 Hinder")


func _test_ice_shield_ally():
	var player = TestFixtures.kevin(100, 10)
	var ally = TestFixtures.player("Ally", 100, 10)
	TestFixtures.combat(game_manager, [player, ally], [])

	var card = card_db.get_card("spell_ice_shield")
	TestFixtures.give_card(player, "spell_ice_shield", card_db)

	game_manager.apply_card_effects(player, player.hand[0], ally)

	assert_shield(ally, 5, "Ice Shield grants 5 shield to ally")
	assert_eq(card.element, Card.ElementType.WATER, "Ice Shield is WATER element")


func _test_encapsulation_retain():
	var card = card_db.get_card("spell_encapsulation")

	assert_true(card.grants_card_retain, "Encapsulation grants card retain")
	assert_eq(card.element, Card.ElementType.EARTH, "Encapsulation is EARTH element")


# ============================================
# ALCHEMY CARD TESTS
# ============================================

func _test_lightning_storm_wet_bonus():
	var player = TestFixtures.kevin(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	# Apply 3 wet stacks
	TestFixtures.apply_debuff(enemy, "wet", 3)

	var card = card_db.get_card("alc_lightning_storm")
	TestFixtures.give_card(player, "alc_lightning_storm", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# 3 damage per wet = 9 total damage
	assert_health(enemy, 91, "Lightning Storm deals 3 damage per Wet (3x3=9)")


func _test_lightning_storm_preserves_wet():
	var player = TestFixtures.kevin(100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	TestFixtures.apply_debuff(enemy, "wet", 3)

	TestFixtures.give_card(player, "alc_lightning_storm", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# Lightning Storm does NOT remove Wet - it can be used multiple times for combo damage
	assert_debuff(enemy, "wet", 3, "Lightning Storm preserves Wet stacks")


func _test_accumulation_spell_discard():
	var card = card_db.get_card("alc_accumulation")

	assert_true(card.discard_all_spells, "Accumulation discards all spells")
	assert_eq(card.damage_per_spell_discarded, 3, "Accumulation deals 3 per spell")


func _test_giant_shield_all_allies():
	var player = TestFixtures.kevin(100, 10)
	var ally = TestFixtures.player("Ally", 100, 10)
	TestFixtures.combat(game_manager, [player, ally], [])

	var card = card_db.get_card("alc_giant_shield")
	TestFixtures.give_card(player, "alc_giant_shield", card_db)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_shield(player, 5, "Giant Shield grants 5 shield to caster")
	assert_shield(ally, 5, "Giant Shield grants 5 shield to ally")


func _test_tsunami_aoe_wet():
	var player = TestFixtures.kevin(100, 10)
	var enemy1 = TestFixtures.enemy("Enemy1", 100)
	var enemy2 = TestFixtures.enemy("Enemy2", 100)
	TestFixtures.combat(game_manager, [player], [enemy1, enemy2])

	TestFixtures.give_card(player, "spell_tsunami", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy1)

	assert_health(enemy1, 96, "Tsunami deals 4 to enemy1")
	assert_health(enemy2, 96, "Tsunami deals 4 to enemy2 (AOE)")
	assert_debuff(enemy1, "wet", 1, "Tsunami applies 1 Wet to enemy1")
	assert_debuff(enemy2, "wet", 1, "Tsunami applies 1 Wet to enemy2")


func _test_repurpose_spell_bonus():
	var card = card_db.get_card("repurpose")

	assert_eq(card.damage, 2, "Repurpose base damage is 2")
	assert_eq(card.damage_per_spell_discarded, 2, "Repurpose +2 per spell discarded")


func _test_future_vision_reveal():
	var card = card_db.get_card("spell_future_vision")

	assert_true(card.reveals_boss_intent, "Future Vision reveals boss intent")


func _test_mortar_pestle_discard_draw():
	var card = card_db.get_card("spell_mortar_pestle")

	assert_eq(card.discard_spell_requirement, 1, "Mortar & Pestle discards 1 spell")
	assert_eq(card.draw_cards, 2, "Mortar & Pestle draws 2 cards")


func _test_enflame_damage_buff():
	var card = card_db.get_card("spell_enflame")

	assert_eq(card.apply_damage_plus, 2, "Enflame grants +2 damage")
	assert_eq(card.element, Card.ElementType.FIRE, "Enflame is FIRE element")


func _test_restore_wet_heal():
	var card = card_db.get_card("spell_restore")

	assert_true(card.remove_all_wet, "Restore removes Wet")
	assert_eq(card.heal_per_wet_removed, 5, "Restore heals 5 per Wet removed")


func _test_ring_of_fire_reflect():
	var player = TestFixtures.kevin(100, 10)
	TestFixtures.combat(game_manager, [player], [])

	var card = card_db.get_card("spell_ring_of_fire")
	TestFixtures.give_card(player, "spell_ring_of_fire", card_db)

	game_manager.apply_card_effects(player, player.hand[0], player)

	assert_shield(player, 5, "Ring of Fire grants 5 shield")
	assert_buff(player, "ring_of_fire", 1, "Ring of Fire grants 1 stack (reflects 3 damage per hit)")


func _test_reformulate_spell_search():
	var card = card_db.get_card("reformulate")

	assert_eq(card.discard_spell_requirement, 1, "Reformulate discards 1 spell")
	assert_eq(card.choose_spell_from_deck, 1, "Reformulate searches for 1 spell")


func _test_accretion_stamina():
	var card = card_db.get_card("accretion")

	assert_eq(card.discard_spell_requirement, 2, "Accretion discards 2 spells")
	assert_eq(card.target_stamina_gain, 1, "Accretion grants ally 1 stamina")
