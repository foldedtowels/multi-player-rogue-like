extends Node
## Factory for creating hero characters from data definitions
##
## This autoload singleton creates heroes using the data-driven approach.
## All hero stats and decks are defined in HeroesData.HEROES dictionary.
## Adding a new hero only requires adding data to heroes_data.gd.

var card_db: Node

func _ready():
	card_db = get_node("/root/CardDatabase")

## Create a hero from its ID using the factory pattern
## @param hero_id: The hero identifier (e.g., "flame_wielder", "life_weaver")
## @returns: Fully initialized Character with deck populated
func create_hero(hero_id: String) -> Character:
	if not HeroesData.has_hero(hero_id):
		push_error("[HeroDatabase] Unknown hero ID: " + hero_id)
		return null

	var data = HeroesData.HEROES[hero_id]
	var hero = Character.new()

	# Set character properties from data
	hero.hero_id = hero_id  # Store the template ID for reward deck lookups
	hero.character_name = data.name
	hero.description = data.description
	hero.max_health = data.max_health
	hero.starting_stamina = data.starting_stamina
	hero.starting_aura = data.get("starting_aura", 0)  # Enrique's second resource (0 for non-aura heroes)
	hero.max_aura = hero.starting_aura  # Max aura equals starting aura
	hero.passive_ability_id = data.get("passive_ability_id", "")  # Optional field for Phase 1+ heroes

	# Build deck from card IDs
	var deck: Array[Card] = []
	for card_id in data.deck:
		var card = card_db.get_card(card_id)
		if card:
			deck.append(card)
		else:
			push_warning("[HeroDatabase] Failed to add card to deck: " + card_id)

	print("[HeroDatabase] ", hero.character_name, " deck built with ", deck.size(), " cards")
	hero.starting_deck = deck
	hero.reset_deck()  # Initialize deck now that starting_deck is populated
	print("[HeroDatabase] After reset_deck, ", hero.character_name, " deck has ", hero.deck.size(), " cards")

	# Build satchel for Kevin-style heroes (Alc cards)
	if data.has("satchel"):
		var satchel: Array[Card] = []
		for card_id in data.satchel:
			var card = card_db.get_card(card_id)
			if card:
				satchel.append(card)
			else:
				push_warning("[HeroDatabase] Failed to add card to satchel: " + card_id)
		hero.satchel = satchel
		print("[HeroDatabase] ", hero.character_name, " satchel built with ", satchel.size(), " Alc cards")

	return hero

## Legacy function for backwards compatibility
func create_life_weaver() -> Character:
	return create_hero("life_weaver")

## Get all available heroes
## @returns: Array of all hero characters with decks initialized
func get_all_heroes() -> Array[Character]:
	var heroes: Array[Character] = []

	# Iterate through all hero IDs in data file
	for hero_id in HeroesData.get_all_hero_ids():
		var hero = create_hero(hero_id)
		if hero:
			heroes.append(hero)

	return heroes

## Get the reward deck for a hero (cards offered after defeating bosses)
## @param hero_id: The hero identifier (e.g., "fabio")
## @returns: Array of Card objects, or empty if no reward deck defined
func get_reward_deck(hero_id: String) -> Array[Card]:
	if not HeroesData.has_hero(hero_id):
		return []

	var data = HeroesData.HEROES[hero_id]
	if not data.has("reward_deck"):
		return []

	var reward_cards: Array[Card] = []
	for card_id in data.reward_deck:
		var card = card_db.get_card(card_id)
		if card:
			reward_cards.append(card)
		else:
			push_warning("[HeroDatabase] Failed to get reward card: " + card_id)

	return reward_cards

## Check if a hero has a custom reward deck
## @param hero_id: The hero identifier
## @returns: True if the hero has a reward_deck defined
func has_reward_deck(hero_id: String) -> bool:
	if not HeroesData.has_hero(hero_id):
		return false
	return HeroesData.HEROES[hero_id].has("reward_deck")
