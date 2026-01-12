extends Node
## Factory for creating boss characters from data definitions
##
## This autoload singleton creates bosses using the data-driven approach.
## All boss stats, decks, and boss-specific cards are defined in BossesData.
## Adding a new boss only requires adding data to bosses_data.gd.

var card_db: Node
var boss_cards_created: bool = false

func _ready():
	card_db = get_node("/root/CardDatabase")

## Create boss-specific cards from data definitions
## Boss cards are dynamically created and added to CardDatabase
func create_boss_cards():
	if boss_cards_created:
		return
	boss_cards_created = true

	# Iterate through all boss cards in data file
	for card_id in BossesData.BOSS_CARDS.keys():
		var data = BossesData.BOSS_CARDS[card_id]
		var card = Card.new()

		# Set basic properties
		card.card_name = data.card_name
		card.description = data.description
		card.stamina_cost = data.get("stamina_cost", data.get("energy_cost", 0))  # Support old data with energy_cost

		# Parse card type from string
		match data.card_type:
			"ATTACK": card.card_type = Card.CardType.ATTACK
			"SPELL": card.card_type = Card.CardType.SPELL
			"BUFF": card.card_type = Card.CardType.BUFF
			"DEBUFF": card.card_type = Card.CardType.DEBUFF
			"HEAL": card.card_type = Card.CardType.HEAL

		# Parse target type from string
		match data.target_type:
			"SELF": card.target_type = Card.TargetType.SELF
			"SINGLE_ALLY": card.target_type = Card.TargetType.SINGLE_ALLY
			"SINGLE_ENEMY": card.target_type = Card.TargetType.SINGLE_ENEMY
			"RANDOM_ENEMY": card.target_type = Card.TargetType.RANDOM_ENEMY
			"ALL_ALLIES": card.target_type = Card.TargetType.ALL_ALLIES
			"ALL_ENEMIES": card.target_type = Card.TargetType.ALL_ENEMIES

		# Set optional properties if they exist in data
		if data.has("damage"): card.damage = data.damage
		if data.has("shield_amount"): card.shield_amount = data.shield_amount
		if data.has("heal_amount"): card.heal_amount = data.heal_amount
		if data.has("apply_strength"): card.apply_strength = data.apply_strength
		if data.has("apply_poison"): card.apply_poison = data.apply_poison
		if data.has("apply_burn"): card.apply_burn = data.apply_burn
		if data.has("apply_vulnerable"): card.apply_vulnerable = data.apply_vulnerable
		if data.has("apply_weakness"): card.apply_weakness = data.apply_weakness
		if data.has("apply_armor"): card.apply_armor = data.apply_armor
		if data.has("lifesteal"): card.lifesteal = data.lifesteal
		if data.has("piercing"): card.piercing = data.piercing
		if data.has("aoe_damage"): card.aoe_damage = data.aoe_damage

		# Add to card database
		card_db.all_cards[card_id] = card

## Create a boss from its ID using the factory pattern
## @param boss_id: The boss identifier (e.g., "corrupted_treant", "flame_warlord")
## @returns: Fully initialized boss Character with deck populated
func create_boss_by_id(boss_id: String) -> Character:
	if not BossesData.has_boss(boss_id):
		push_error("[BossDatabase] Unknown boss ID: " + boss_id)
		return null

	var data = BossesData.BOSSES[boss_id]
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
	# Data format: {"root_lash": 6, "bark_armor": 4, ...}
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
	return boss

## Legacy function for backwards compatibility
func create_corrupted_treant() -> Character:
	return create_boss_by_id("corrupted_treant")

## Legacy function for backwards compatibility
func create_flame_warlord() -> Character:
	return create_boss_by_id("flame_warlord")

## Legacy function for backwards compatibility
func create_lich_summoner() -> Character:
	return create_boss_by_id("lich_summoner")

## Legacy function for backwards compatibility
func create_storm_dragon() -> Character:
	return create_boss_by_id("storm_dragon")

## Legacy function for backwards compatibility
func create_void_titan() -> Character:
	return create_boss_by_id("void_titan")

## Get boss by index (0-4 for the 5 boss encounters)
## @param index: Boss encounter number (0 = first boss, 4 = final boss)
## @returns: Fully initialized boss Character
func get_boss(index: int) -> Character:
	create_boss_cards()
	var boss_id = BossesData.get_boss_id(index)
	if boss_id == "":
		push_error("[BossDatabase] Invalid boss index: " + str(index))
		return null
	return create_boss_by_id(boss_id)

## Get all bosses in encounter order
## @returns: Array of all boss characters with decks initialized
func get_all_bosses() -> Array[Character]:
	create_boss_cards()
	var bosses: Array[Character] = []

	# Iterate through boss order defined in data
	for boss_id in BossesData.BOSS_ORDER:
		var boss = create_boss_by_id(boss_id)
		if boss:
			bosses.append(boss)

	return bosses
