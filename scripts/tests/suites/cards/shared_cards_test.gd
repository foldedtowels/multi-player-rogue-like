extends "res://scripts/tests/framework/test_base.gd"
class_name SharedCardsTest
## Tests for shared/token cards (Energy, Ember)

func _init(gm: Node, cdb: Node):
	game_manager = gm
	card_db = cdb
	suite_name = "Shared Cards"


func _test_energy_instant_stamina():
	var card = card_db.get_card("energy")

	assert_true(card.plays_immediately, "Energy plays immediately")
	assert_eq(card.grants_stamina, 1, "Energy grants 1 stamina")
	assert_card_cost(card, 0, "Energy costs 0 stamina")


func _test_ember_token_damage():
	var player = TestFixtures.player("Test", 100, 10)
	var enemy = TestFixtures.enemy("Target", 100)
	TestFixtures.combat(game_manager, [player], [enemy])

	var card = card_db.get_card("ember")
	TestFixtures.give_card(player, "ember", card_db)

	game_manager.apply_card_effects(player, player.hand[0], enemy)

	assert_health(enemy, 96, "Ember deals 4 damage")
	assert_card_cost(card, 1, "Ember costs 1 stamina")
