extends Node
## Central repository for all player and boss cards
##
## This autoload singleton loads and manages all cards in the game.
## Cards are defined in GDScript data files under scripts/data/cards/.
##
## CARD DATA FORMAT:
## Cards are defined as dictionaries with properties matching Card class:
## {
##     "card_name": "Fire Smash",
##     "description": "Deal 5 damage.",
##     "card_type": "ATTACK",
##     "target_type": "SINGLE_ENEMY",
##     "stamina_cost": 2,
##     "damage": 5,
##     "element": "FIRE"
## }
##
## See scripts/data/cards/*.gd for all card definitions.

var all_cards = {}

## If true, CSV loading is enabled (for backwards compatibility/override)
var csv_loading_enabled: bool = false

## Path to CSV file for card definitions (used only if csv_loading_enabled)
var csv_path: String = "res://csvs/cards.csv"

## If true, print detailed loading info
var verbose_loading: bool = true

## Type mapping constants (match CSVCardLoader for consistency)
const CARD_TYPE_MAP: Dictionary = {
	"ATTACK": Card.CardType.ATTACK,
	"SPELL": Card.CardType.SPELL,
	"BUFF": Card.CardType.BUFF,
	"DEBUFF": Card.CardType.DEBUFF,
	"HEAL": Card.CardType.HEAL,
	"SUMMON": Card.CardType.SUMMON,
	"COUNTER": Card.CardType.COUNTER
}

const TARGET_TYPE_MAP: Dictionary = {
	"SELF": Card.TargetType.SELF,
	"SINGLE_ALLY": Card.TargetType.SINGLE_ALLY,
	"ALL_ALLIES": Card.TargetType.ALL_ALLIES,
	"OTHER_ALLIES": Card.TargetType.OTHER_ALLIES,
	"SINGLE_ENEMY": Card.TargetType.SINGLE_ENEMY,
	"ALL_ENEMIES": Card.TargetType.ALL_ENEMIES,
	"RANDOM_ENEMY": Card.TargetType.RANDOM_ENEMY,
	"ANY": Card.TargetType.ANY,
	"CCW_PLAYER": Card.TargetType.CCW_PLAYER,
	"HIGHEST_HP": Card.TargetType.HIGHEST_HP,
	"LOWEST_HP": Card.TargetType.LOWEST_HP
}

const ELEMENT_TYPE_MAP: Dictionary = {
	"NONE": Card.ElementType.NONE,
	"FIRE": Card.ElementType.FIRE,
	"WATER": Card.ElementType.WATER,
	"EARTH": Card.ElementType.EARTH
}


func _ready():
	_load_all_card_definitions()
	if csv_loading_enabled:
		_load_cards_from_csv()
	_link_v2_cards()
	_generate_card_documentation()


## Load all card definitions from GDScript data files
func _load_all_card_definitions():
	var total_loaded = 0

	# Load shared cards (tokens, utilities)
	total_loaded += _load_cards_from_data(SharedCardsData.CARDS, "SharedCards")

	# Load hero cards
	total_loaded += _load_cards_from_data(FabioCardsData.CARDS, "Fabio")
	total_loaded += _load_cards_from_data(KevinCardsData.CARDS, "Kevin")
	total_loaded += _load_cards_from_data(EnriqueCardsData.CARDS, "Enrique")

	# Load generic reward cards
	total_loaded += _load_cards_from_data(RewardCardsData.CARDS, "Rewards")

	# Load minion cards
	total_loaded += _load_cards_from_data(MinionCardsData.CARDS, "Minions")

	# Load boss cards
	total_loaded += _load_cards_from_data(BossesData.BOSS_CARDS, "Bosses")

	if verbose_loading:
		print("[CardDatabase] Loaded " + str(total_loaded) + " cards from GDScript data files")


## Load cards from a dictionary of card definitions
## Returns the number of cards loaded
func _load_cards_from_data(cards_dict: Dictionary, source_name: String = "") -> int:
	var count = 0
	for card_id in cards_dict:
		var card_data = cards_dict[card_id]
		var card = _create_card_from_dict(card_data)
		if card:
			all_cards[card_id] = card
			count += 1
		else:
			push_warning("[CardDatabase] Failed to create card: " + card_id)

	if verbose_loading and source_name != "":
		print("[CardDatabase] Loaded " + str(count) + " cards from " + source_name)
	return count


## Create a Card object from a dictionary of properties
func _create_card_from_dict(data: Dictionary) -> Card:
	var card = Card.new()

	# Core properties
	card.card_name = data.get("card_name", "Unknown")
	card.description = data.get("description", "")

	# Card type
	var card_type_str = data.get("card_type", "ATTACK")
	if CARD_TYPE_MAP.has(card_type_str):
		card.card_type = CARD_TYPE_MAP[card_type_str]
	else:
		push_warning("[CardDatabase] Unknown card_type: " + card_type_str)
		card.card_type = Card.CardType.ATTACK

	# Target type
	var target_type_str = data.get("target_type", "SINGLE_ENEMY")
	if TARGET_TYPE_MAP.has(target_type_str):
		card.target_type = TARGET_TYPE_MAP[target_type_str]
	else:
		push_warning("[CardDatabase] Unknown target_type: " + target_type_str)
		card.target_type = Card.TargetType.SINGLE_ENEMY

	# Base stats
	card.stamina_cost = data.get("stamina_cost", 0)
	card.damage = data.get("damage", 0)
	card.heal_amount = data.get("heal_amount", 0)
	card.heal_per_wet_removed = data.get("heal_per_wet_removed", 0)
	card.shield_amount = data.get("shield_amount", 0)
	card.draw_cards = data.get("draw_cards", 0)
	card.is_upgraded = data.get("is_upgraded", false)

	# Status effects - debuffs
	card.apply_poison = data.get("apply_poison", 0)
	card.apply_burn = data.get("apply_burn", 0)
	card.apply_weakness = data.get("apply_weakness", 0)
	card.apply_vulnerable = data.get("apply_vulnerable", 0)
	card.apply_hinder = data.get("apply_hinder", 0)
	card.apply_scared = data.get("apply_scared", 0)
	card.apply_decay = data.get("apply_decay", 0)

	# Status effects - buffs
	card.apply_strength = data.get("apply_strength", 0)
	card.apply_armor = data.get("apply_armor", 0)
	card.apply_rested = data.get("apply_rested", 0)
	card.apply_invigorated = data.get("apply_invigorated", 0)
	card.apply_damage_plus = data.get("apply_damage_plus", 0)
	card.apply_fatigued = data.get("apply_fatigued", 0)
	card.apply_exhausted = data.get("apply_exhausted", 0)

	# Special mechanics
	card.piercing = data.get("piercing", false)
	card.lifesteal = data.get("lifesteal", false)
	card.multi_hit = data.get("multi_hit", 1)
	card.aoe_damage = data.get("aoe_damage", false)
	card.plays_immediately = data.get("plays_immediately", false)

	# Delayed damage system
	card.is_delayed_damage = data.get("is_delayed_damage", false)
	card.delay_condition = data.get("delay_condition", "")
	card.delayed_damage_amount = data.get("delayed_damage_amount", 0)

	# Special actions
	card.grants_card_retain = data.get("grants_card_retain", false)
	card.swaps_enemy_target = data.get("swaps_enemy_target", false)
	card.reveals_boss_intent = data.get("reveals_boss_intent", false)
	card.caster_discards_random = data.get("caster_discards_random", 0)
	card.bonus_damage_if_wounded = data.get("bonus_damage_if_wounded", 0)
	card.bonus_damage_per_debuff = data.get("bonus_damage_per_debuff", 0)
	card.damage_threshold_check = data.get("damage_threshold_check", 0)
	card.damage_threshold_modifier = data.get("damage_threshold_modifier", 0)
	card.stamina_gain = data.get("stamina_gain", 0)
	card.scry_amount = data.get("scry_amount", 0)

	# Card generation
	var gen_cards = data.get("generate_cards", [])
	if gen_cards is Array:
		var typed_arr: Array[String] = []
		for c in gen_cards:
			typed_arr.append(str(c))
		card.generate_cards = typed_arr

	# V2 system
	card.has_v2 = data.get("has_v2", false)
	card.v2_card_id = data.get("v2_card_id", "")
	card.context_sensitive_v2 = data.get("context_sensitive_v2", false)

	# Element/Alchemy system (Kevin)
	var element_str = str(data.get("element", "NONE")).to_upper()
	if ELEMENT_TYPE_MAP.has(element_str):
		card.element = ELEMENT_TYPE_MAP[element_str]
	else:
		card.element = Card.ElementType.NONE

	# Ingredient list
	var ingredients = data.get("ingredient_list", [])
	if ingredients is Array:
		var ing_arr: Array[String] = []
		for elem in ingredients:
			ing_arr.append(str(elem).to_lower())
		card.ingredient_list = ing_arr

	card.is_alc = data.get("is_alc", false)

	# Wet mechanic (Kevin)
	card.apply_wet = data.get("apply_wet", 0)
	card.bonus_damage_per_wet = data.get("bonus_damage_per_wet", 0)
	card.remove_all_wet = data.get("remove_all_wet", false)

	# Ring Of Fire (Kevin)
	card.apply_ring_of_fire = data.get("apply_ring_of_fire", 0)

	# Spell discard mechanics (Kevin)
	card.discard_spell_requirement = data.get("discard_spell_requirement", 0)
	card.discard_all_spells = data.get("discard_all_spells", false)
	card.damage_per_spell_discarded = data.get("damage_per_spell_discarded", 0)
	card.random_spell_discard = data.get("random_spell_discard", false)

	# Spell search/tutor (Kevin)
	card.choose_spell_from_deck = data.get("choose_spell_from_deck", 0)

	# All players effects (Kevin)
	card.all_players_shield = data.get("all_players_shield", 0)

	# Target effects (Kevin)
	card.target_stamina_gain = data.get("target_stamina_gain", 0)
	card.remove_target_debuffs = data.get("remove_target_debuffs", 0)

	# Enrique's Aura system
	card.aura_cost = data.get("aura_cost", 0)
	card.aura_cost_all = data.get("aura_cost_all", false)
	card.aura_gain = data.get("aura_gain", 0)
	card.damage_per_aura_spent = data.get("damage_per_aura_spent", 0)

	# Enrique's buff effects
	card.grants_played_twice = data.get("grants_played_twice", false)
	card.grants_invincible = data.get("grants_invincible", false)

	# D6 damage (Prayer Beads)
	card.damage_is_d6 = data.get("damage_is_d6", false)

	# All players draw cards (Guy with Beard)
	card.all_players_draw = data.get("all_players_draw", 0)

	return card


## Link v2_card references after all cards are loaded
func _link_v2_cards() -> void:
	for card_id in all_cards:
		var card: Card = all_cards[card_id]
		if card.has_v2 and card.v2_card_id != "":
			if all_cards.has(card.v2_card_id):
				card.v2_card = all_cards[card.v2_card_id]
				if verbose_loading:
					print("[CardDatabase] Linked V2: " + card_id + " -> " + card.v2_card_id)
			else:
				push_warning("[CardDatabase] V2 card not found: " + card.v2_card_id + " for " + card_id)


## Load cards from CSV file (overrides/adds to GDScript cards)
func _load_cards_from_csv() -> void:
	if csv_path == "":
		return

	if not FileAccess.file_exists(csv_path):
		if verbose_loading:
			print("[CardDatabase] No CSV file at: " + csv_path + " (using GDScript cards only)")
		return

	var csv_cards = CSVCardLoader.load_cards_from_csv(csv_path)
	var override_count = 0
	var new_count = 0

	for card_id in csv_cards:
		if all_cards.has(card_id):
			override_count += 1
		else:
			new_count += 1
		all_cards[card_id] = csv_cards[card_id]

	if verbose_loading:
		print("[CardDatabase] CSV loaded: " + str(override_count) + " overrides, " + str(new_count) + " new cards")


## Generate human-readable card documentation
## Only runs in debug builds to avoid file I/O in release
func _generate_card_documentation() -> void:
	if not OS.is_debug_build():
		return

	var doc_path = "res://docs/CARDS_REFERENCE.md"
	var file = FileAccess.open(doc_path, FileAccess.WRITE)
	if not file:
		push_warning("[CardDatabase] Could not create documentation at: " + doc_path)
		return

	file.store_string("# Card Reference\n\n")
	file.store_string("*Auto-generated from GDScript card definitions.*\n\n")
	file.store_string("Total cards: " + str(all_cards.size()) + "\n\n")

	# Group cards by source
	var sections = {
		"Fabio (Warrior)": FabioCardsData.CARDS.keys(),
		"Kevin (Alchemist)": KevinCardsData.CARDS.keys(),
		"Enrique (Cleric)": EnriqueCardsData.CARDS.keys(),
		"Generic Rewards": RewardCardsData.CARDS.keys(),
		"Shared/Token Cards": SharedCardsData.CARDS.keys(),
		"Minion Cards": MinionCardsData.CARDS.keys(),
		"Boss Cards": BossesData.BOSS_CARDS.keys()
	}

	for section_name in sections:
		var card_ids = sections[section_name]
		if card_ids.size() == 0:
			continue

		file.store_string("## " + section_name + "\n\n")
		file.store_string("| Card | Type | Cost | Damage | Description |\n")
		file.store_string("|------|------|------|--------|-------------|\n")

		for card_id in card_ids:
			if not all_cards.has(card_id):
				continue
			var card: Card = all_cards[card_id]
			var type_str = CARD_TYPE_MAP.find_key(card.card_type)
			if type_str == null:
				type_str = "?"
			var cost_str = str(card.stamina_cost)
			if card.aura_cost > 0:
				cost_str += " + " + str(card.aura_cost) + "A"
			elif card.aura_cost_all:
				cost_str += " + ALL A"
			var dmg_str = str(card.damage) if card.damage > 0 else "-"
			# Escape pipes in description for markdown table
			var desc = card.description.replace("|", "\\|")
			file.store_string("| " + card.card_name + " | " + type_str + " | " + cost_str + " | " + dmg_str + " | " + desc + " |\n")

		file.store_string("\n")

	file.close()
	if verbose_loading:
		print("[CardDatabase] Generated documentation: " + doc_path)


## Export all current cards to CSV (useful for backup/migration)
## Call this from the debugger: CardDatabase.export_all_cards_to_csv()
func export_all_cards_to_csv(output_path: String = "res://csvs/cards.csv") -> bool:
	return CSVCardLoader.export_cards_to_csv(all_cards, output_path)


## Factory function for creating cards with basic stats (legacy support)
func create_card(name: String, desc: String, type: Card.CardType, target: Card.TargetType,
				 cost: int, dmg: int, heal: int, shield: int, draw: int) -> Card:
	var card = Card.new()
	card.card_name = name
	card.description = desc
	card.card_type = type
	card.target_type = target
	card.stamina_cost = cost
	card.damage = dmg
	card.heal_amount = heal
	card.shield_amount = shield
	card.draw_cards = draw
	return card


func get_card(card_id: String) -> Card:
	if all_cards.has(card_id):
		var original = all_cards[card_id]
		var copy = original.duplicate()
		# v2_card_id is @export so it's copied by duplicate()
		# v2_card reference can be set locally for efficiency
		if original.has_v2 and original.v2_card != null:
			copy.v2_card = original.v2_card.duplicate()
		return copy
	else:
		push_error("Card not found: " + card_id)
		return null


# === REWARD CARD GETTERS ===

func get_rare_cards() -> Array[Card]:
	var rare_pool: Array[Card] = []
	for card_id in RewardCardsData.RARE_CARDS:
		if all_cards.has(card_id):
			rare_pool.append(all_cards[card_id].duplicate())
	return rare_pool


func get_common_cards() -> Array[Card]:
	var common_pool: Array[Card] = []
	for card_id in RewardCardsData.COMMON_CARDS:
		if all_cards.has(card_id):
			common_pool.append(all_cards[card_id].duplicate())
	return common_pool
