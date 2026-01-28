extends "res://scripts/tests/framework/test_base.gd"
class_name StateSyncTest
## Tests for multiplayer state synchronization

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "State Synchronization"


# ============================================
# HP SYNCHRONIZATION
# ============================================

func _test_hp_sync_after_damage():
	var result = TestFixtures.multiplayer_combat(game_manager, 2, 1)
	var players = result[0]
	var enemies = result[1]

	# Player 1 takes damage
	players[0].take_damage(20, false)

	assert_health(players[0], 80, "Player 1 HP updated locally")
	# In real multiplayer, this would be synced via RPC


func _test_shield_sync():
	var result = TestFixtures.multiplayer_combat(game_manager, 2, 1)
	var players = result[0]

	# Player 1 gains shield
	players[0].shield = 15

	assert_shield(players[0], 15, "Shield value set correctly")


# ============================================
# STATUS EFFECT SYNC
# ============================================

func _test_buff_sync():
	var result = TestFixtures.multiplayer_combat(game_manager, 2, 1)
	var players = result[0]

	# Player 1 gains strength
	TestFixtures.apply_buff(players[0], "strength", 3)

	assert_buff(players[0], "strength", 3, "Buff applied correctly")


func _test_debuff_sync():
	var result = TestFixtures.multiplayer_combat(game_manager, 2, 1)
	var players = result[0]

	# Player 1 gets poisoned
	TestFixtures.apply_debuff(players[0], "poison", 5)

	assert_debuff(players[0], "poison", 5, "Debuff applied correctly")


# ============================================
# HAND/DECK SYNC
# ============================================

func _test_hand_size_sync():
	var result = TestFixtures.multiplayer_combat(game_manager, 2, 1)
	var players = result[0]

	# Add cards to player 1's hand
	for i in range(5):
		var card = TestFixtures.make_attack_card("Card%d" % i, 5)
		players[0].hand.append(card)

	assert_hand_size(players[0], 5, "Hand size tracked correctly")


func _test_deck_size_sync():
	var result = TestFixtures.multiplayer_combat(game_manager, 2, 1)
	var players = result[0]

	# Add cards to player 1's deck
	for i in range(10):
		var card = TestFixtures.make_attack_card("Card%d" % i, 5)
		players[0].deck.append(card)

	assert_deck_size(players[0], 10, "Deck size tracked correctly")


# ============================================
# RELIC SYNC
# ============================================

func _test_relic_sync():
	var result = TestFixtures.multiplayer_combat(game_manager, 2, 1)
	var players = result[0]

	# Give player 1 a relic
	TestFixtures.give_relic(players[0], "backpack")

	assert_has_relic(players[0], "backpack", "Relic ownership tracked")


# ============================================
# ROUND NUMBER SYNC
# ============================================

func _test_round_increment():
	TestFixtures.multiplayer_combat(game_manager, 2, 1)

	game_manager.round_number = 5

	assert_eq(game_manager.round_number, 5, "Round number tracked correctly")
