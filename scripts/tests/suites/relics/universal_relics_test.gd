extends "res://scripts/tests/framework/test_base.gd"
class_name UniversalRelicsTest
## Tests for all universal (shared) relics

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "Universal Relics"


# ============================================
# BACKPACK
# ============================================

func _test_backpack_draw_turn_start():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_relic(player, "backpack")
	TestFixtures.combat(game_manager, [player], [])

	# Add cards to deck
	for i in range(5):
		var card = TestFixtures.make_attack_card("TestCard%d" % i, 5)
		player.deck.append(card)

	var initial_hand = player.hand.size()

	# Apply turn start relics
	RelicRegistry.apply_turn_start(player, 1)

	assert_eq(player.hand.size(), initial_hand + 1, "Backpack draws 1 card at turn start")


# ============================================
# SECOND WIND
# ============================================

func _test_second_wind_10_damage_threshold():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_relic(player, "second_wind")
	TestFixtures.combat(game_manager, [player], [])

	var initial_stamina = player.current_stamina

	# Deal 10+ damage
	RelicRegistry.apply_on_damage_dealt(player, 10)

	assert_eq(player.current_stamina, initial_stamina + 1, "Second Wind grants 1 stamina on 10+ damage")


func _test_second_wind_under_10_no_trigger():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_relic(player, "second_wind")
	TestFixtures.combat(game_manager, [player], [])

	var initial_stamina = player.current_stamina

	# Deal less than 10 damage
	RelicRegistry.apply_on_damage_dealt(player, 9)

	assert_eq(player.current_stamina, initial_stamina, "Second Wind doesn't trigger on <10 damage")


# ============================================
# COPYING MACHINE
# ============================================

func _test_copying_machine_extra_hit():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_relic(player, "copying_machine")

	var extra_hits = RelicRegistry.get_extra_multi_hit(player)

	assert_eq(extra_hits, 1, "Copying Machine adds 1 extra multi-hit")


func _test_copying_machine_single_hit_no_effect():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.give_relic(player, "copying_machine")
	TestFixtures.combat(game_manager, [player], [enemy])

	# Slash is single-hit (multi_hit = 0 or 1)
	TestFixtures.give_card(player, "slash", card_db)
	game_manager.apply_card_effects(player, player.hand[0], enemy)

	# Single-hit cards shouldn't be affected
	assert_health(enemy, 93, "Single-hit card not affected by Copying Machine")


# ============================================
# CRACKED GEM
# ============================================

func _test_cracked_gem_turn_1_only():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_relic(player, "cracked_gem")
	TestFixtures.combat(game_manager, [player], [])

	var initial_stamina = player.current_stamina

	# Round 1
	RelicRegistry.apply_turn_start(player, 1)

	assert_eq(player.current_stamina, initial_stamina + 1, "Cracked Gem grants 1 stamina on turn 1")


func _test_cracked_gem_turn_2_no_effect():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_relic(player, "cracked_gem")
	TestFixtures.combat(game_manager, [player], [])

	var initial_stamina = player.current_stamina

	# Round 2
	RelicRegistry.apply_turn_start(player, 2)

	assert_eq(player.current_stamina, initial_stamina, "Cracked Gem doesn't trigger on turn 2+")


# ============================================
# RESTORATIVE LOCKET
# ============================================

func _test_restorative_locket_fight_end():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.set_hp(player, 80)
	TestFixtures.give_relic(player, "restorative_locket")
	TestFixtures.combat(game_manager, [player], [])

	var players: Array[Character] = [player]
	RelicRegistry.apply_fight_end(players)

	assert_health(player, 90, "Restorative Locket heals 10 at fight end")


# ============================================
# NIPPLE PROTECTORS
# ============================================

func _test_nipple_protectors_fight_start_armor():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_relic(player, "nipple_protectors")

	var players: Array[Character] = [player]
	RelicRegistry.apply_fight_start(players)

	assert_buff(player, "armor", 2, "Nipple Protectors grants 2 armor at fight start")


# ============================================
# GRANDMA'S COOKIES
# ============================================

func _test_grandmas_cookies_heal_bonus():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_relic(player, "grandmas_cookies")
	TestFixtures.set_hp(player, 80)
	TestFixtures.combat(game_manager, [player], [])

	var rng = RandomNumberGenerator.new()
	var enemies: Array[Character] = []

	var bonus = RelicRegistry.calculate_heal_bonus(player, player, 10, enemies, rng)

	assert_eq(bonus, 5, "Grandma's Cookies adds +5 heal bonus")


# ============================================
# COFFEE SODA
# ============================================

func _test_coffee_soda_on_pickup_hp():
	var player = TestFixtures.player("Test", 100, 10)
	var initial_max = player.max_health

	TestFixtures.apply_relic_pickup(player, "coffee_soda")

	assert_eq(player.max_health, initial_max + 10, "Coffee Soda adds +10 max HP")
	assert_health(player, 100, "Coffee Soda heals 10 on pickup")


# ============================================
# POWER RING
# ============================================

func _test_power_ring_fight_start_strength():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_relic(player, "power_ring")

	var players: Array[Character] = [player]
	RelicRegistry.apply_fight_start(players)

	assert_buff(player, "strength", 1, "Power Ring grants 1 Strength at fight start")


# ============================================
# RAGE METER
# ============================================

func _test_rage_meter_3rd_card():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_relic(player, "rage_meter")
	TestFixtures.combat(game_manager, [player], [])

	player.cards_played_this_turn = 0
	var initial_stamina = player.current_stamina

	# Play 3 cards
	RelicRegistry.apply_on_card_played(player)  # 1
	RelicRegistry.apply_on_card_played(player)  # 2
	RelicRegistry.apply_on_card_played(player)  # 3 - triggers

	assert_eq(player.current_stamina, initial_stamina + 1, "Rage Meter triggers on 3rd card")


func _test_rage_meter_reset_each_turn():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_relic(player, "rage_meter")
	TestFixtures.combat(game_manager, [player], [])

	player.cards_played_this_turn = 2
	player.cards_played_this_turn = 0  # Reset for new turn

	var initial_stamina = player.current_stamina

	RelicRegistry.apply_on_card_played(player)  # 1
	RelicRegistry.apply_on_card_played(player)  # 2

	assert_eq(player.current_stamina, initial_stamina, "Rage Meter doesn't trigger before 3 cards")


# ============================================
# BLOOD CRYSTAL
# ============================================

func _test_blood_crystal_stamina_and_bleed():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_relic(player, "blood_crystal")

	var players: Array[Character] = [player]
	RelicRegistry.apply_fight_start(players)

	assert_debuff(player, "bleed", 4, "Blood Crystal applies 4 Bleed at fight start")

	var initial_stamina = player.current_stamina
	RelicRegistry.apply_turn_start(player, 1)

	assert_eq(player.current_stamina, initial_stamina + 1, "Blood Crystal grants 1 stamina at turn start")


# ============================================
# RADIATING APPLE
# ============================================

func _test_radiating_apple_stamina_and_damage():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_relic(player, "radiating_apple")
	TestFixtures.combat(game_manager, [player], [])

	var initial_stamina = player.current_stamina
	RelicRegistry.apply_turn_start(player, 1)

	assert_eq(player.current_stamina, initial_stamina + 1, "Radiating Apple grants 1 stamina")

	RelicRegistry.apply_turn_end(player)

	assert_health(player, 99, "Radiating Apple deals 1 damage at turn end")


# ============================================
# REVIVE RELIC
# ============================================

func _test_revive_relic_active_use():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_relic(player, "revive_relic")
	player.reset_relic_uses()

	assert_true(player.can_use_relic("revive_relic"), "Revive Relic can be used")
	assert_eq(player.relic_uses_remaining.get("revive_relic", 0), 1, "Revive Relic has 1 use")


func _test_revive_relic_once_per_fight():
	var player = TestFixtures.player("Test", 100, 10)
	TestFixtures.give_relic(player, "revive_relic")
	player.reset_relic_uses()

	player.use_relic("revive_relic")

	assert_false(player.can_use_relic("revive_relic"), "Revive Relic can't be used again")
	assert_eq(player.relic_uses_remaining.get("revive_relic", 0), 0, "Revive Relic has 0 uses left")
