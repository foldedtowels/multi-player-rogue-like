extends Node
## Factory for creating boss characters from data definitions
##
## This autoload singleton creates bosses using the data-driven approach.
## All boss stats and decks are defined in EnemiesData.
## Boss cards are loaded by CardDatabase from EnemyCardsData.
## Adding a new boss only requires adding data to enemies_data.gd and enemy_cards.gd.

# Preload data classes
const EnemiesData = preload("res://scripts/data/enemies_data.gd")

var card_db: Node

func _ready():
	card_db = get_node("/root/CardDatabase")

## Create a boss from its ID using the factory pattern
## @param boss_id: The boss identifier (e.g., "giant_moose", "mr_67")
## @returns: Fully initialized boss Character with deck populated
func create_boss_by_id(boss_id: String) -> Character:
	if not EnemiesData.has_boss(boss_id):
		push_error("[BossDatabase] Unknown boss ID: " + boss_id)
		return null

	var data = EnemiesData.BOSSES[boss_id]
	var boss = Character.new()

	# Set character properties from data
	boss.character_name = data.name
	boss.description = data.description
	boss.max_health = data.max_health
	boss.current_health = data.max_health
	boss.starting_stamina = data.starting_stamina
	boss.max_stamina = data.starting_stamina
	boss.current_stamina = data.starting_stamina

	# Build deck from card IDs and counts
	# Data format: {"charge": 4, "stomp": 4, ...}
	var deck: Array[Card] = []
	for card_id in data.deck.keys():
		var count = data.deck[card_id]
		for i in count:
			var card = card_db.get_card(card_id)
			if card:
				deck.append(card)
			else:
				push_warning("[BossDatabase] Failed to add card to boss deck: " + card_id)

	boss.starting_deck = deck
	boss.reset_deck()  # Initialize deck now that starting_deck is populated

	# Build special deck if defined (for bosses with special_chance)
	if data.has("special_deck"):
		var special: Array[Card] = []
		for card_id in data.special_deck.keys():
			var count = data.special_deck[card_id]
			for i in count:
				var card = card_db.get_card(card_id)
				if card:
					special.append(card)
		boss.special_deck = special

	# Set special chance if defined
	if data.has("special_chance"):
		boss.special_chance = data.special_chance

	# Set cards per turn limit if defined (-1 = unlimited)
	if data.has("cards_per_turn"):
		boss.main_deck_cards_per_turn = data.cards_per_turn

	# Set extended probability properties
	if data.has("extra_main_deck_chance"):
		boss.extra_main_deck_chance = data.extra_main_deck_chance
	if data.has("special_deck_double_chance"):
		boss.special_deck_double_chance = data.special_deck_double_chance

	return boss

## Legacy function for backwards compatibility
func create_giant_moose() -> Character:
	return create_boss_by_id("giant_moose")

## Legacy function for backwards compatibility
func create_mr_67() -> Character:
	return create_boss_by_id("mr_67")

## Get boss by index (0-4 for the 5 boss encounters)
## @param index: Boss encounter number (0 = first boss, 4 = final boss)
## @returns: Fully initialized boss Character
func get_boss(index: int) -> Character:
	var boss_id = EnemiesData.get_boss_id(index)
	if boss_id == "":
		push_error("[BossDatabase] Invalid boss index: " + str(index))
		return null
	return create_boss_by_id(boss_id)

## Get all bosses in encounter order
## @returns: Array of all boss characters with decks initialized
func get_all_bosses() -> Array[Character]:
	var bosses: Array[Character] = []

	# Iterate through boss order defined in data
	for boss_id in EnemiesData.BOSS_ORDER:
		var boss = create_boss_by_id(boss_id)
		if boss:
			bosses.append(boss)

	return bosses
