extends Node
## Minion factory - creates Character instances from minion data

var minions_data: Node
var card_db: Node

func _ready():
	minions_data = preload("res://scripts/minions_data.gd").new()
	card_db = get_node("/root/CardDatabase")

func create_minion_by_id(minion_id: String) -> Character:
	var data = minions_data.get_minion_data(minion_id)
	if data.is_empty():
		push_error("[MinionDatabase] Minion not found: " + minion_id)
		return null

	var minion = Character.new()
	minion.character_name = data.name
	minion.description = "Minion of " + ["Giant Moose", "Mr. 67", "Flame Warlord", "Lich Summoner", "Storm Dragon", "Void Titan"][data.boss_index]
	minion.max_health = data.max_health
	minion.current_health = data.max_health
	minion.starting_stamina = data.starting_stamina
	minion.max_stamina = data.starting_stamina
	minion.current_stamina = data.starting_stamina
	minion.character_role = Character.CharacterRole.MINION
	minion.is_minion = true

	# Build minion deck from card data
	var deck: Array[Card] = []
	for card_data in data.deck:
		var card = create_card_from_data(card_data)
		deck.append(card)

	minion.starting_deck = deck
	minion.reset_deck()

	# Build special deck if present
	if data.has("special_deck"):
		for card_data in data.special_deck:
			var special_card = create_card_from_data(card_data)
			minion.special_deck.append(special_card)
		minion.special_chance = data.get("special_chance", 0.0)

	# Set cards per turn limit (-1 = unlimited)
	minion.main_deck_cards_per_turn = data.get("cards_per_turn", -1)

	# Set extended probability properties
	minion.extra_main_deck_chance = data.get("extra_main_deck_chance", 0.0)
	minion.special_deck_double_chance = data.get("special_deck_double_chance", 0.0)

	return minion

func create_card_from_data(data: Dictionary) -> Card:
	var card = Card.new()
	card.card_name = data.name
	card.description = data.get("description", "")

	# Card type
	match data.type:
		"ATTACK":
			card.card_type = Card.CardType.ATTACK
		"SPELL":
			card.card_type = Card.CardType.SPELL
		"BUFF":
			card.card_type = Card.CardType.BUFF
		"DEBUFF":
			card.card_type = Card.CardType.DEBUFF
		"HEAL":
			card.card_type = Card.CardType.HEAL

	# Target type
	match data.target:
		"SELF":
			card.target_type = Card.TargetType.SELF
		"SINGLE_ALLY":
			card.target_type = Card.TargetType.SINGLE_ALLY
		"ALL_ALLIES":
			card.target_type = Card.TargetType.ALL_ALLIES
		"SINGLE_ENEMY":
			card.target_type = Card.TargetType.SINGLE_ENEMY
		"ALL_ENEMIES":
			card.target_type = Card.TargetType.ALL_ENEMIES
		"RANDOM_ENEMY":
			card.target_type = Card.TargetType.RANDOM_ENEMY
		"CCW_PLAYER":
			card.target_type = Card.TargetType.CCW_PLAYER
		"HIGHEST_HP":
			card.target_type = Card.TargetType.HIGHEST_HP
		"LOWEST_HP":
			card.target_type = Card.TargetType.LOWEST_HP

	card.stamina_cost = data.cost
	card.damage = data.get("damage", 0)
	card.heal_amount = data.get("heal", 0)
	card.shield_amount = data.get("shield", 0)
	card.apply_poison = data.get("poison", 0)
	card.apply_burn = data.get("burn", 0)
	card.apply_strength = data.get("strength", 0)
	card.apply_vulnerable = data.get("vulnerable", 0)
	card.apply_weakness = data.get("weakness", 0)
	card.apply_armor = data.get("armor", 0)
	card.apply_hinder = data.get("hinder", 0)
	card.apply_scared = data.get("scared", 0)
	card.piercing = data.get("piercing", false)
	card.lifesteal = data.get("lifesteal", false)

	# Conditional damage properties
	card.damage_threshold_check = data.get("damage_threshold_check", 0)
	card.damage_threshold_modifier = data.get("damage_threshold_modifier", 0)

	if card.damage_threshold_check != 0 or card.damage_threshold_modifier != 0:
		print("[MINION CARD] ", card.card_name, " threshold_check=", card.damage_threshold_check, " threshold_mod=", card.damage_threshold_modifier)

	return card

func get_minions_for_boss(boss_index: int) -> Array[Character]:
	var minion_ids = minions_data.get_minions_for_boss(boss_index)
	var minions: Array[Character] = []

	for minion_id in minion_ids:
		var minion = create_minion_by_id(minion_id)
		if minion:
			minions.append(minion)

	return minions
