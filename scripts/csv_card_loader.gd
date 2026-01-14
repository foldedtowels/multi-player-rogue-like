extends RefCounted
class_name CSVCardLoader

## CSV Card Loader
## Loads card definitions from CSV files for easy balancing and card management.
## Column names match Card class property names directly.

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

## Load all cards from a CSV file
## Returns: Dictionary[card_id: String, Card]
static func load_cards_from_csv(csv_path: String) -> Dictionary:
	var cards: Dictionary = {}
	var file = FileAccess.open(csv_path, FileAccess.READ)
	if not file:
		push_error("[CSV] Failed to open: " + csv_path)
		return cards

	# Parse header row to get column indices
	var header_line = file.get_csv_line()
	var column_map: Dictionary = {}
	for i in range(header_line.size()):
		column_map[header_line[i].strip_edges()] = i

	# Validate required columns exist
	if not column_map.has("card_id"):
		push_error("[CSV] Missing required column: card_id")
		file.close()
		return cards

	var row_num = 1
	while not file.eof_reached():
		var row = file.get_csv_line()
		row_num += 1

		# Skip empty rows
		if row.size() < 2:
			continue
		var card_id = _get_string(row, column_map, "card_id")
		if card_id == "":
			continue

		var card = _parse_card_row(row, column_map, row_num)
		if card:
			cards[card_id] = card
			print("[CSV] Loaded card: " + card_id)

	file.close()

	# Second pass: link v2 cards
	_link_v2_cards(cards)

	print("[CSV] Loaded " + str(cards.size()) + " cards from " + csv_path)
	return cards


## Parse a single CSV row into a Card object
static func _parse_card_row(row: Array, columns: Dictionary, row_num: int) -> Card:
	var card = Card.new()

	# Core properties
	card.card_name = _get_string(row, columns, "card_name")
	card.description = _get_string(row, columns, "description")

	var card_type_str = _get_string(row, columns, "card_type")
	if CARD_TYPE_MAP.has(card_type_str):
		card.card_type = CARD_TYPE_MAP[card_type_str]
	else:
		push_warning("[CSV] Row " + str(row_num) + ": Unknown card_type '" + card_type_str + "', defaulting to ATTACK")
		card.card_type = Card.CardType.ATTACK

	var target_type_str = _get_string(row, columns, "target_type")
	if TARGET_TYPE_MAP.has(target_type_str):
		card.target_type = TARGET_TYPE_MAP[target_type_str]
	else:
		push_warning("[CSV] Row " + str(row_num) + ": Unknown target_type '" + target_type_str + "', defaulting to SINGLE_ENEMY")
		card.target_type = Card.TargetType.SINGLE_ENEMY

	card.stamina_cost = _get_int(row, columns, "stamina_cost")

	# Base stats
	card.damage = _get_int(row, columns, "damage")
	card.heal_amount = _get_int(row, columns, "heal_amount")
	card.shield_amount = _get_int(row, columns, "shield_amount")
	card.draw_cards = _get_int(row, columns, "draw_cards")
	card.is_upgraded = _get_bool(row, columns, "is_upgraded")

	# Status effects - debuffs (typically applied to enemies)
	card.apply_poison = _get_int(row, columns, "apply_poison")
	card.apply_burn = _get_int(row, columns, "apply_burn")
	card.apply_weakness = _get_int(row, columns, "apply_weakness")
	card.apply_vulnerable = _get_int(row, columns, "apply_vulnerable")
	card.apply_hinder = _get_int(row, columns, "apply_hinder")
	card.apply_scared = _get_int(row, columns, "apply_scared")
	card.apply_decay = _get_int(row, columns, "apply_decay")

	# Status effects - buffs (typically applied to self/allies)
	card.apply_strength = _get_int(row, columns, "apply_strength")
	card.apply_armor = _get_int(row, columns, "apply_armor")
	card.apply_rested = _get_int(row, columns, "apply_rested")
	card.apply_invigorated = _get_int(row, columns, "apply_invigorated")
	card.apply_damage_plus = _get_int(row, columns, "apply_damage_plus")
	card.apply_fatigued = _get_int(row, columns, "apply_fatigued")
	card.apply_exhausted = _get_int(row, columns, "apply_exhausted")

	# Special mechanics
	card.piercing = _get_bool(row, columns, "piercing")
	card.lifesteal = _get_bool(row, columns, "lifesteal")
	card.multi_hit = _get_int(row, columns, "multi_hit", 1)  # Default to 1
	card.aoe_damage = _get_bool(row, columns, "aoe_damage")
	card.plays_immediately = _get_bool(row, columns, "plays_immediately")

	# Delayed damage system
	card.is_delayed_damage = _get_bool(row, columns, "is_delayed_damage")
	card.delay_condition = _get_string(row, columns, "delay_condition")
	card.delayed_damage_amount = _get_int(row, columns, "delayed_damage_amount")

	# Special actions
	card.grants_card_retain = _get_bool(row, columns, "grants_card_retain")
	card.swaps_enemy_target = _get_bool(row, columns, "swaps_enemy_target")
	card.reveals_boss_intent = _get_bool(row, columns, "reveals_boss_intent")
	card.caster_discards_random = _get_int(row, columns, "caster_discards_random")
	card.bonus_damage_if_wounded = _get_int(row, columns, "bonus_damage_if_wounded")
	card.stamina_gain = _get_int(row, columns, "stamina_gain")
	card.scry_amount = _get_int(row, columns, "scry_amount")

	# Card generation (pipe-separated list of card IDs)
	var generate_str = _get_string(row, columns, "generate_cards")
	if generate_str != "":
		var gen_arr: Array[String] = []
		for card_id in generate_str.split("|"):
			var trimmed = card_id.strip_edges()
			if trimmed != "":
				gen_arr.append(trimmed)
		card.generate_cards = gen_arr

	# V2 system
	card.has_v2 = _get_bool(row, columns, "has_v2")
	card.v2_card_id = _get_string(row, columns, "v2_card_id")

	return card


## Link v2_card references after all cards are loaded
static func _link_v2_cards(cards: Dictionary) -> void:
	for card_id in cards:
		var card: Card = cards[card_id]
		if card.has_v2 and card.v2_card_id != "":
			if cards.has(card.v2_card_id):
				card.v2_card = cards[card.v2_card_id]
				print("[CSV] Linked V2: " + card_id + " -> " + card.v2_card_id)
			else:
				push_warning("[CSV] V2 card not found: " + card.v2_card_id + " for " + card_id)


## Get string value from row (returns empty string if column missing)
static func _get_string(row: Array, columns: Dictionary, key: String) -> String:
	if not columns.has(key) or columns[key] >= row.size():
		return ""
	return row[columns[key]].strip_edges()


## Get int value from row (returns default if column missing or empty)
static func _get_int(row: Array, columns: Dictionary, key: String, default: int = 0) -> int:
	var str_val = _get_string(row, columns, key)
	if str_val == "":
		return default
	return int(str_val)


## Get bool value from row (accepts true/false/1/0/yes/no)
static func _get_bool(row: Array, columns: Dictionary, key: String) -> bool:
	var str_val = _get_string(row, columns, key).to_lower()
	return str_val == "true" or str_val == "1" or str_val == "yes"


## Export cards to CSV format (for creating initial CSV from existing cards)
## This is a utility function to help migrate from hardcoded to CSV-based cards
static func export_cards_to_csv(cards: Dictionary, csv_path: String) -> bool:
	var file = FileAccess.open(csv_path, FileAccess.WRITE)
	if not file:
		push_error("[CSV] Failed to create: " + csv_path)
		return false

	# Write header row
	var headers = [
		"card_id", "card_name", "description", "card_type", "target_type", "stamina_cost",
		"damage", "heal_amount", "shield_amount", "draw_cards", "is_upgraded",
		"apply_poison", "apply_burn", "apply_weakness", "apply_vulnerable",
		"apply_strength", "apply_armor", "apply_rested", "apply_invigorated",
		"apply_damage_plus", "apply_fatigued", "apply_exhausted", "apply_decay",
		"apply_hinder", "apply_scared",
		"piercing", "lifesteal", "multi_hit", "aoe_damage", "plays_immediately",
		"is_delayed_damage", "delay_condition", "delayed_damage_amount",
		"grants_card_retain", "swaps_enemy_target", "reveals_boss_intent",
		"caster_discards_random", "bonus_damage_if_wounded", "stamina_gain", "scry_amount",
		"generate_cards", "has_v2", "v2_card_id"
	]
	file.store_csv_line(PackedStringArray(headers))

	# Write each card as a row
	for card_id in cards:
		var card: Card = cards[card_id]
		var row = _card_to_csv_row(card_id, card)
		file.store_csv_line(PackedStringArray(row))

	file.close()
	print("[CSV] Exported " + str(cards.size()) + " cards to " + csv_path)
	return true


## Convert a Card to a CSV row array
static func _card_to_csv_row(card_id: String, card: Card) -> Array:
	# Get card_type as string
	var card_type_str = ""
	for key in CARD_TYPE_MAP:
		if CARD_TYPE_MAP[key] == card.card_type:
			card_type_str = key
			break

	# Get target_type as string
	var target_type_str = ""
	for key in TARGET_TYPE_MAP:
		if TARGET_TYPE_MAP[key] == card.target_type:
			target_type_str = key
			break

	# Convert generate_cards array to pipe-separated string
	var generate_cards_str = "|".join(card.generate_cards) if card.generate_cards.size() > 0 else ""

	return [
		card_id,
		card.card_name,
		card.description,
		card_type_str,
		target_type_str,
		str(card.stamina_cost),
		str(card.damage),
		str(card.heal_amount),
		str(card.shield_amount),
		str(card.draw_cards),
		"true" if card.is_upgraded else "false",
		str(card.apply_poison),
		str(card.apply_burn),
		str(card.apply_weakness),
		str(card.apply_vulnerable),
		str(card.apply_strength),
		str(card.apply_armor),
		str(card.apply_rested),
		str(card.apply_invigorated),
		str(card.apply_damage_plus),
		str(card.apply_fatigued),
		str(card.apply_exhausted),
		str(card.apply_decay),
		str(card.apply_hinder),
		str(card.apply_scared),
		"true" if card.piercing else "false",
		"true" if card.lifesteal else "false",
		str(card.multi_hit),
		"true" if card.aoe_damage else "false",
		"true" if card.plays_immediately else "false",
		"true" if card.is_delayed_damage else "false",
		card.delay_condition,
		str(card.delayed_damage_amount),
		"true" if card.grants_card_retain else "false",
		"true" if card.swaps_enemy_target else "false",
		"true" if card.reveals_boss_intent else "false",
		str(card.caster_discards_random),
		str(card.bonus_damage_if_wounded),
		str(card.stamina_gain),
		str(card.scry_amount),
		generate_cards_str,
		"true" if card.has_v2 else "false",
		card.v2_card_id
	]
