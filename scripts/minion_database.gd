extends Node
## Factory for creating minion characters from data definitions
##
## This autoload singleton creates minions using the data-driven approach.
## All minion stats and decks are defined in EnemiesData.
## Minion cards are loaded by CardDatabase from EnemyCardsData.
## Adding a new minion only requires adding data to enemies_data.gd and enemy_cards.gd.

# Preload data classes
const EnemiesData = preload("res://scripts/data/enemies_data.gd")

var card_db: Node

func _ready():
	card_db = get_node("/root/CardDatabase")

## Create a minion from its ID using the factory pattern
## @param minion_id: The minion identifier (e.g., "swarm_of_racoons", "alex")
## @returns: Fully initialized minion Character with deck populated
func create_minion_by_id(minion_id_param: String) -> Character:
	if not EnemiesData.has_minion(minion_id_param):
		push_error("[MinionDatabase] Unknown minion ID: " + minion_id_param)
		return null

	var data = EnemiesData.MINIONS[minion_id_param]
	var minion = Character.new()

	# Set minion ID for network sync and reference
	minion.minion_id = minion_id_param

	# Set character properties from data
	minion.character_name = data.name
	var boss_names = ["Giant Moose", "Mr. 67", "Spider-Queen", "Flame Warlord", "Lich Summoner", "Storm Dragon"]
	var boss_idx = data.boss_index
	if boss_idx >= 0 and boss_idx < boss_names.size():
		minion.description = "Minion of " + boss_names[boss_idx]
	else:
		minion.description = "Minion"
	minion.max_health = data.max_health
	minion.current_health = data.max_health
	minion.starting_stamina = data.starting_stamina
	minion.max_stamina = data.starting_stamina
	minion.current_stamina = data.starting_stamina
	minion.character_role = Character.CharacterRole.MINION
	minion.is_minion = true

	# Build deck from card IDs and counts
	# Data format: {"ankle_nibble": 5, "swarm": 5, ...}
	var deck: Array[Card] = []
	for card_id in data.deck.keys():
		var count = data.deck[card_id]
		for i in count:
			var card = card_db.get_card(card_id)
			if card:
				deck.append(card)
			else:
				push_warning("[MinionDatabase] Failed to add card to minion deck: " + card_id)

	minion.starting_deck = deck
	minion.reset_deck()  # Initialize deck now that starting_deck is populated

	# Build special deck if defined
	if data.has("special_deck"):
		var special: Array[Card] = []
		for card_id in data.special_deck.keys():
			var count = data.special_deck[card_id]
			for i in count:
				var card = card_db.get_card(card_id)
				if card:
					special.append(card)
		minion.special_deck = special

	# Set special chance if defined
	if data.has("special_chance"):
		minion.special_chance = data.special_chance

	# Set cards per turn limit if defined (-1 = unlimited)
	if data.has("cards_per_turn"):
		minion.main_deck_cards_per_turn = data.cards_per_turn

	# Set extended probability properties
	if data.has("extra_main_deck_chance"):
		minion.extra_main_deck_chance = data.extra_main_deck_chance
	if data.has("special_deck_double_chance"):
		minion.special_deck_double_chance = data.special_deck_double_chance

	# Aura system support (for Enrique, The Fallen, etc.)
	if data.has("starting_aura"):
		minion.max_aura = data.starting_aura
		minion.current_aura = 0  # Start at 0, gained from cards

	# Passive ability support (for Enrique, The Fallen aura generation, etc.)
	if data.has("passive_ability_id"):
		minion.passive_ability_id = data.passive_ability_id

	return minion

## Get all minions for a specific boss encounter
## @param boss_index: Boss encounter number (0 = first boss minions, 1 = second boss minions)
## @returns: Array of minion Characters with decks initialized
func get_minions_for_boss(boss_index: int) -> Array[Character]:
	var minion_ids = EnemiesData.get_minions_for_boss(boss_index)
	var minions: Array[Character] = []

	for minion_id in minion_ids:
		var minion = create_minion_by_id(minion_id)
		if minion:
			minions.append(minion)

	return minions


## Create a random summonable minion by tag (used for mid-combat summoning)
## @param tag: The summon tag to filter by (e.g., "spiderling")
## @param rng: RandomNumberGenerator for deterministic selection
## @returns: A new minion Character marked as summoned, or null if no minions found
func create_random_summonable_minion(tag: String, rng: RandomNumberGenerator) -> Character:
	var minion_ids = EnemiesData.get_summonable_minions_by_tag(tag)
	if minion_ids.is_empty():
		push_warning("[MinionDatabase] No summonable minions found for tag: " + tag)
		return null

	# Pick a random minion from the available pool
	var random_idx = rng.randi() % minion_ids.size()
	var selected_id = minion_ids[random_idx]

	var minion = create_minion_by_id(selected_id)
	if minion:
		minion.was_summoned = true
		print("[MinionDatabase] Created summoned minion: " + minion.character_name)

	return minion
