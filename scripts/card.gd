extends Resource
class_name Card

enum CardType {
	ATTACK,
	SPELL,
	BUFF,
	DEBUFF,
	HEAL,
	SUMMON,
	COUNTER
}

enum TargetType {
	SELF,
	SINGLE_ALLY,
	ALL_ALLIES,
	SINGLE_ENEMY,
	ALL_ENEMIES,
	RANDOM_ENEMY,
	ANY
}

@export var card_name: String
@export var description: String
@export var card_type: CardType
@export var target_type: TargetType
@export var energy_cost: int
@export var damage: int = 0
@export var heal_amount: int = 0
@export var shield_amount: int = 0
@export var draw_cards: int = 0
@export var is_upgraded: bool = false

# Status effects
@export var apply_poison: int = 0
@export var apply_burn: int = 0
@export var apply_weakness: int = 0
@export var apply_vulnerable: int = 0
@export var apply_strength: int = 0
@export var apply_armor: int = 0

# Special mechanics
@export var piercing: bool = false  # Ignores armor
@export var lifesteal: bool = false
@export var multi_hit: int = 1  # Number of times to apply effect
@export var aoe_damage: bool = false
@export var plays_immediately: bool = false  # Plays when selected in SELECTION phase (e.g., Draw cards)

# Card generation
@export var generate_cards: Array[String] = []  # Names of cards to add to hand
@export var scry_amount: int = 0  # Look at top X cards of deck

# Runtime-only unique ID for queued card instances (invisible to player, not saved to disk)
# Used to distinguish between identical cards in the queue (e.g., two Fire Strike cards)
var queue_instance_id: int = 0

func get_full_description() -> String:
	var desc = description + "\n\n"

	if damage > 0:
		desc += "Deal %d damage" % damage
		if multi_hit > 1:
			desc += " %d times" % multi_hit
		if piercing:
			desc += " (Piercing)"
		desc += "\n"

	if heal_amount > 0:
		desc += "Heal %d HP\n" % heal_amount

	if shield_amount > 0:
		desc += "Gain %d Shield\n" % shield_amount

	if draw_cards > 0:
		desc += "Draw %d card(s)\n" % draw_cards

	if apply_poison > 0:
		desc += "Apply %d Poison\n" % apply_poison

	if apply_burn > 0:
		desc += "Apply %d Burn\n" % apply_burn

	if apply_strength > 0:
		desc += "Gain %d Strength\n" % apply_strength

	if apply_vulnerable > 0:
		desc += "Apply %d Vulnerable\n" % apply_vulnerable

	return desc

func can_afford(current_energy: int) -> bool:
	return current_energy >= energy_cost

# Network serialization
func serialize() -> Dictionary:
	return {
		"card_name": card_name,
		"description": description,
		"card_type": card_type,
		"target_type": target_type,
		"energy_cost": energy_cost,
		"damage": damage,
		"heal_amount": heal_amount,
		"shield_amount": shield_amount,
		"draw_cards": draw_cards,
		"is_upgraded": is_upgraded,
		"apply_poison": apply_poison,
		"apply_burn": apply_burn,
		"apply_weakness": apply_weakness,
		"apply_vulnerable": apply_vulnerable,
		"apply_strength": apply_strength,
		"apply_armor": apply_armor,
		"piercing": piercing,
		"lifesteal": lifesteal,
		"multi_hit": multi_hit,
		"aoe_damage": aoe_damage,
		"plays_immediately": plays_immediately,
		"generate_cards": generate_cards,
		"scry_amount": scry_amount,
		"queue_instance_id": queue_instance_id
	}

static func deserialize(data: Dictionary) -> Card:
	var card = Card.new()
	card.card_name = data.card_name
	card.description = data.description
	card.card_type = data.card_type as CardType
	card.target_type = data.target_type as TargetType
	card.energy_cost = data.energy_cost
	card.damage = data.damage
	card.heal_amount = data.heal_amount
	card.shield_amount = data.shield_amount
	card.draw_cards = data.draw_cards
	card.is_upgraded = data.is_upgraded
	card.apply_poison = data.apply_poison
	card.apply_burn = data.apply_burn
	card.apply_weakness = data.apply_weakness
	card.apply_vulnerable = data.apply_vulnerable
	card.apply_strength = data.apply_strength
	card.apply_armor = data.apply_armor
	card.piercing = data.piercing
	card.lifesteal = data.lifesteal
	card.multi_hit = data.multi_hit
	card.aoe_damage = data.aoe_damage
	card.plays_immediately = data.get("plays_immediately", false)  # Default to false for old cards
	card.generate_cards = data.generate_cards
	card.scry_amount = data.scry_amount
	card.queue_instance_id = data.get("queue_instance_id", 0)  # Default to 0 for old cards
	return card
