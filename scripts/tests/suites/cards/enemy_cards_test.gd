extends "res://scripts/tests/framework/test_base.gd"
class_name EnemyCardsTest
## Tests for boss and minion cards

func _init(gm: Node, cdb: Node, bdb: Node = null):
	game_manager = gm
	card_db = cdb
	boss_db = bdb
	suite_name = "Enemy Cards"


# ============================================
# GIANT MOOSE (Boss 1)
# ============================================

func _test_charge_lowest_hp():
	var card = _get_boss_card("giant_moose", "charge")
	if not card:
		return

	assert_card_damage(card, 8, "Charge deals 8 damage")
	assert_true(card.targets_lowest_hp_player, "Charge targets lowest HP player")


func _test_stomp_aoe():
	var card = _get_boss_card("giant_moose", "stomp")
	if not card:
		return

	assert_card_damage(card, 5, "Stomp deals 5 damage")
	assert_eq(card.target_type, Card.TargetType.ALL_ENEMIES, "Stomp is AOE")


func _test_knocked_hinder():
	var card = _get_boss_card("giant_moose", "knocked_off_your_feet")
	if not card:
		return

	assert_card_damage(card, 5, "Knocked deals 5 damage")
	assert_eq(card.apply_hinder, 2, "Knocked applies 2 Hinder")


func _test_roar_scared():
	var card = _get_boss_card("giant_moose", "roar")
	if not card:
		return

	assert_eq(card.apply_scared, 1, "Roar applies 1 Scared")
	assert_true(card.targets_highest_hp_player, "Roar targets highest HP player")


func _test_forage_heal():
	var card = _get_boss_card("giant_moose", "forage")
	if not card:
		return

	assert_eq(card.heal, 10, "Forage heals 10 HP")


func _test_fur_coat_shield():
	var card = _get_boss_card("giant_moose", "fur_coat")
	if not card:
		return

	assert_eq(card.shield, 8, "Fur Coat grants 8 shield")


# ============================================
# MR. 67 (Boss 2)
# ============================================

func _test_big_punch():
	var card = _get_boss_card("mr_67", "big_punch")
	if not card:
		return

	assert_card_damage(card, 7, "Big Punch deals 7 damage")


func _test_gut_punch_scared():
	var card = _get_boss_card("mr_67", "gut_punch")
	if not card:
		return

	assert_card_damage(card, 5, "Gut Punch deals 5 damage")
	assert_eq(card.apply_scared, 1, "Gut Punch applies 1 Scared")


func _test_ground_smash_aoe():
	var card = _get_boss_card("mr_67", "ground_smash")
	if not card:
		return

	assert_card_damage(card, 5, "Ground Smash deals 5 damage")
	assert_eq(card.target_type, Card.TargetType.ALL_ENEMIES, "Ground Smash is AOE")


func _test_protein_shake():
	var card = _get_boss_card("mr_67", "protein_shake")
	if not card:
		return

	assert_eq(card.apply_strength, 2, "Protein Shake grants 2 Strength")


func _test_muscle_shield():
	var card = _get_boss_card("mr_67", "muscle_shield")
	if not card:
		return

	assert_eq(card.shield, 10, "Muscle Shield grants 10 shield")


func _test_intimidating_flex():
	var card = _get_boss_card("mr_67", "intimidating_flex")
	if not card:
		return

	assert_eq(card.apply_hinder, 2, "Intimidating Flex applies 2 Hinder")


# ============================================
# SPIDER-QUEEN (Boss 3)
# ============================================

func _test_venom_bite():
	var card = _get_boss_card("spider_queen", "venom_bite")
	if not card:
		return

	assert_card_damage(card, 7, "Venom Bite deals 7 damage")
	assert_eq(card.apply_venom, 3, "Venom Bite applies 3 Venom")


func _test_heavy_strike():
	var card = _get_boss_card("spider_queen", "heavy_strike")
	if not card:
		return

	assert_card_damage(card, 10, "Heavy Strike deals 10 damage")


func _test_venom_spray_aoe():
	var card = _get_boss_card("spider_queen", "venom_spray")
	if not card:
		return

	assert_eq(card.apply_venom, 4, "Venom Spray applies 4 Venom")
	assert_eq(card.target_type, Card.TargetType.ALL_ENEMIES, "Venom Spray is AOE")


func _test_web_shield():
	var card = _get_boss_card("spider_queen", "web_shield")
	if not card:
		return

	assert_eq(card.shield, 15, "Web Shield grants 15 shield")


func _test_terrify():
	var card = _get_boss_card("spider_queen", "terrify")
	if not card:
		return

	assert_eq(card.apply_scared, 2, "Terrify applies 2 Scared")


func _test_spawn_spiderling():
	var card = _get_boss_card("spider_queen", "spawn_spiderling")
	if not card:
		return

	assert_true(card.summons_minion, "Spawn Spiderling summons a minion")


# ============================================
# MUTE (Boss 4)
# ============================================

func _test_ravage():
	var card = _get_boss_card("mute", "ravage")
	if not card:
		return

	assert_card_damage(card, 10, "Ravage deals 10 damage")


func _test_black_surge_aoe():
	var card = _get_boss_card("mute", "black_surge")
	if not card:
		return

	assert_card_damage(card, 6, "Black Surge deals 6 damage")
	assert_eq(card.target_type, Card.TargetType.ALL_ENEMIES, "Black Surge is AOE")


func _test_instantiation_doll():
	var card = _get_boss_card("mute", "instantiation")
	if not card:
		return

	assert_true(card.applies_random_doll_curse, "Instantiation applies random Doll curse")


func _test_hex_acquisition():
	var card = _get_boss_card("mute", "hex_acquisition")
	if not card:
		return

	assert_true(card.exhausts_deck_cards, "Hex Acquisition exhausts deck cards")


func _test_hex_paranoia():
	var card = _get_boss_card("mute", "hex_paranoia")
	if not card:
		return

	assert_gt(card.apply_hinder, 0, "Hex Paranoia applies Hinder")


# ============================================
# THE DOCTOR (Boss 5)
# ============================================

func _test_vile_injection():
	var card = _get_boss_card("the_doctor", "vile_injection")
	if not card:
		return

	assert_card_damage(card, 7, "Vile Injection deals 7 damage")
	assert_eq(card.apply_poison, 3, "Vile Injection applies 3 Poison")


func _test_putrid_mist():
	var card = _get_boss_card("the_doctor", "putrid_mist")
	if not card:
		return

	assert_card_damage(card, 5, "Putrid Mist deals 5 damage")
	assert_gt(card.apply_poison, 0, "Putrid Mist applies Poison")
	assert_eq(card.target_type, Card.TargetType.ALL_ENEMIES, "Putrid Mist is AOE")


func _test_rupture_debuff_bonus():
	var card = _get_boss_card("the_doctor", "rupture")
	if not card:
		return

	assert_gt(card.bonus_damage_per_debuff, 0, "Rupture has bonus damage per debuff")


func _test_deep_stabs():
	var card = _get_boss_card("the_doctor", "deep_stabs")
	if not card:
		return

	assert_eq(card.apply_hinder, 3, "Deep Stabs applies 3 Hinder")
	assert_eq(card.apply_bleed, 3, "Deep Stabs applies 3 Bleed")


func _test_potion_goliath():
	var card = _get_boss_card("the_doctor", "potion_goliath")
	if not card:
		return

	assert_eq(card.apply_armor, 1, "Potion Goliath grants 1 Armor")


func _test_potion_apotheosis():
	var card = _get_boss_card("the_doctor", "potion_apotheosis")
	if not card:
		return

	assert_eq(card.apply_invincible, 1, "Potion Apotheosis grants Invincible")


func _test_potion_rage():
	var card = _get_boss_card("the_doctor", "potion_rage")
	if not card:
		return

	assert_eq(card.apply_strength, 2, "Potion Rage grants 2 Strength")


func _test_dark_barrier():
	var card = _get_boss_card("the_doctor", "dark_barrier")
	if not card:
		return

	assert_eq(card.shield, 8, "Dark Barrier grants 8 shield")


# ============================================
# MINION TESTS
# ============================================

func _test_minion_swarm_raccoons():
	var player = TestFixtures.player("Test", 100, 10)
	var minion = TestFixtures.minion("Raccoon", 20)
	TestFixtures.combat(game_manager, [player], [minion])

	var card = card_db.get_card("minion_raccoon_bite")
	if card:
		assert_card_damage(card, 3, "Raccoon Bite deals 3 damage")


func _test_minion_alex_monkey():
	var card = card_db.get_card("minion_monkey_scratch")
	if card:
		assert_card_damage(card, 4, "Monkey Scratch deals 4 damage")


func _test_minion_brock():
	var card = card_db.get_card("minion_brock_slam")
	if card:
		assert_card_damage(card, 6, "Brock Slam deals 6 damage")


func _test_minion_centipede():
	var card = card_db.get_card("minion_centipede_bite")
	if card:
		assert_gt(card.apply_poison, 0, "Centipede Bite applies Poison")


func _test_minion_wendigo():
	var card = card_db.get_card("minion_wendigo_claw")
	if card:
		assert_card_damage(card, 8, "Wendigo Claw deals 8 damage")


# ============================================
# HELPER METHODS
# ============================================

func _get_boss_card(boss_id: String, card_id: String) -> Card:
	if boss_db and boss_db.has_method("get_boss_card"):
		return boss_db.get_boss_card(boss_id, card_id)

	# Fallback: try card_db with full ID
	var full_id = "boss_%s_%s" % [boss_id, card_id]
	var card = card_db.get_card(full_id)
	if card:
		return card

	# Try without prefix
	card = card_db.get_card(card_id)
	if card:
		return card

	# Skip test if card not found
	print("  SKIP: Card not found: %s/%s" % [boss_id, card_id])
	return null
